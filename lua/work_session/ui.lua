local M = {}
local workspace = require("work_session.workspace")

local state = {
  win = nil,
  buf = nil,
  menu_items = {},
  current_selection = 1
}

local function close_window()
  if state.win and vim.api.nvim_win_is_valid(state.win) then
    vim.api.nvim_win_close(state.win, true)
  end
  state.win = nil
  state.buf = nil
end

local function create_window(config)
  -- Clear any existing window
  if state.win and vim.api.nvim_win_is_valid(state.win) then
    vim.api.nvim_win_close(state.win, true)
  end

  -- Create new buffer
  state.buf = vim.api.nvim_create_buf(false, true)
  
  -- Window dimensions
  local width = config.ui.width or 60
  local height = config.ui.height or 20
  
  -- Create window
  state.win = vim.api.nvim_open_win(state.buf, true, {
    relative = "editor",
    width = width,
    height = height,
    col = math.floor((vim.o.columns - width) / 2),
    row = math.floor((vim.o.lines - height) / 3),
    style = "minimal",
    border = config.ui.border or "rounded"
  })

  -- Set window options
  vim.api.nvim_win_set_option(state.win, "number", false)
  vim.api.nvim_win_set_option(state.win, "relativenumber", false)
  vim.api.nvim_win_set_option(state.win, "cursorline", true)
  
  -- Set buffer options to make it properly closeable (but keep it modifiable for now)
  vim.api.nvim_buf_set_option(state.buf, "buftype", "nofile")
  vim.api.nvim_buf_set_option(state.buf, "swapfile", false)
end

local function create_subwindow(content, title)
  local width = math.floor(vim.o.columns * 0.6)
  local height = math.floor(vim.o.lines * 0.6)
  
  -- Create a scratch buffer
  local buf = vim.api.nvim_create_buf(false, true)
  
  -- Create a parent window with fixed size
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    col = math.floor((vim.o.columns - width) / 2),
    row = math.floor((vim.o.lines - height) / 3),
    style = "minimal",
    border = "rounded",
    title = title,
    title_pos = "center"
  })
  
  -- Set content with proper scrolling
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, content)
  vim.api.nvim_buf_set_option(buf, "modifiable", false)
  vim.api.nvim_buf_set_option(buf, "buftype", "nofile")
  vim.api.nvim_buf_set_option(buf, "swapfile", false)
  vim.api.nvim_win_set_option(win, "wrap", false)
  vim.api.nvim_win_set_option(win, "cursorline", true)
  vim.api.nvim_win_set_option(win, "number", true)
  
  -- Enable scrolling
  vim.keymap.set("n", "<Down>", "<C-e>", { buffer = buf, silent = true })
  vim.keymap.set("n", "<Up>", "<C-y>", { buffer = buf, silent = true })
  vim.keymap.set("n", "<PageDown>", "<C-f>", { buffer = buf, silent = true })
  vim.keymap.set("n", "<PageUp>", "<C-b>", { buffer = buf, silent = true })
  vim.keymap.set("n", "<C-d>", function() M.scroll_down() end, { buffer = state.buf, silent = true })
  vim.keymap.set("n", "<C-u>", function() M.scroll_up() end, { buffer = state.buf, silent = true })
  
  return {
    buf = buf,
    win = win
  }
end

local function render_menu(config)
  -- Check if buffer and window are valid
  if not state.buf or not vim.api.nvim_buf_is_valid(state.buf) then return end
  if not state.win or not vim.api.nvim_win_is_valid(state.win) then return end

  -- Reset menu items
  state.menu_items = {}

  -- Check if buffer and window are valid
  if not state.buf or not vim.api.nvim_buf_is_valid(state.buf) then return end
  if not state.win or not vim.api.nvim_win_is_valid(state.win) then return end

  local lines = {}
  
  -- Header with venv status
  local venv_status = ""
  if package.loaded["venv-selector"] then
    local venv = require("venv-selector").venv()
    venv_status = venv and " (venv: "..vim.fn.fnamemodify(venv, ":t")..")" or ""
  end
  table.insert(lines, "Work Session Manager"..venv_status)
  table.insert(lines, string.rep("=", config.ui.width or 60))
  table.insert(lines, "")
  
  -- Workspaces section
  table.insert(lines, "Workspaces:")
  local workspaces = workspace.get_workspaces()
  state.menu_items = {}
  
  -- Build menu items for workspaces only
  local line_index = 4  -- Starting after header
  for i, ws in ipairs(workspaces) do
    table.insert(state.menu_items, {
      type = "workspace",
      name = ws.name,
      path = ws.path,
      line = line_index
    })
    table.insert(lines, string.format("%d. %s", i, ws.name))
    line_index = line_index + 1
  end
  
  -- Add separator and actions section
  if #workspaces > 0 then
    table.insert(lines, "")
    table.insert(lines, string.rep("─", config.ui.width or 60))
    line_index = line_index + 2
  end
  
  table.insert(lines, "Actions:")
  line_index = line_index + 1
  
  -- Add workspace management actions
  table.insert(state.menu_items, {
    type = "action",
    action = "add_dir",
    line = line_index
  })
  table.insert(lines, string.format("a. Add current directory to workspaces"))
  line_index = line_index + 1
  
  table.insert(state.menu_items, {
    type = "action",
    action = "remove_dir", 
    line = line_index
  })
  table.insert(lines, string.format("d. Remove current directory from workspaces"))

  -- Footer with keybinds
  table.insert(lines, "")
  table.insert(lines, string.rep("-", config.ui.width or 60))
  local footer = "Select: " .. config.ui.keymaps.select .. "/" .. "<CR>"
  footer = footer .. " | Navigate: j/k/" .. config.ui.keymaps.up .. "/" .. config.ui.keymaps.down
  footer = footer .. " | Quick Open: 1-9 | Add: a | Remove: d | Quit: q/" .. config.ui.keymaps.quit
  table.insert(lines, footer)

  -- Set buffer content
  vim.api.nvim_buf_set_option(state.buf, "modifiable", true)
  vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(state.buf, "modifiable", false)
  
  -- Highlight current selection
  vim.api.nvim_buf_clear_namespace(state.buf, -1, 0, -1)
  if state.current_selection > 0 and state.current_selection <= #state.menu_items then
    local current_item = state.menu_items[state.current_selection]
    local highlight_line = current_item.line
    vim.api.nvim_buf_add_highlight(
      state.buf, 
      -1, 
      "CursorLine", 
      highlight_line, 
      0, 
      -1
    )
    vim.api.nvim_win_set_cursor(state.win, {highlight_line + 1, 0})
  end
end

function M.navigate(direction)
  if not state.win or not vim.api.nvim_win_is_valid(state.win) then return end
  if #state.menu_items == 0 then return end
  
  local new_selection = state.current_selection + direction
  if new_selection < 1 then 
    new_selection = #state.menu_items 
  elseif new_selection > #state.menu_items then 
    new_selection = 1 
  end
  
  state.current_selection = new_selection
  render_menu(require("work_session.config").default_config)
end

function M.select_item()
  if not state.win or #state.menu_items == 0 then return end
  local item = state.menu_items[state.current_selection]
  
  if item.type == "workspace" then
    -- Show confirmation subwindow
    local content = {
      "Are you sure you want to open workspace:",
      "",
      "Name: " .. item.name,
      "Path: " .. item.path,
      "",
      "Press <Enter> to confirm",
      "Press <Esc> to cancel"
    }
    
    local subwin = create_subwindow(content, "Confirm Workspace Open")
    
    vim.api.nvim_buf_set_keymap(subwin.buf, "n", "<CR>", 
      "<cmd>lua require('work_session.ui')._confirm_open('"..item.name.."')<CR>", 
      {silent = true})
      
    vim.api.nvim_buf_set_keymap(subwin.buf, "n", "<Esc>", 
      "<cmd>lua require('work_session.ui')._close_subwindow()<CR>", 
      {silent = true})
      
  elseif item.type == "action" then
    M.trigger_action(item.action)
  end
end

function M._confirm_open(workspace_name)
  M._close_subwindow()
  close_window()
  workspace.open_workspace(workspace_name)
end

function M._close_subwindow()
  if state.subwin and vim.api.nvim_win_is_valid(state.subwin.win) then
    vim.api.nvim_win_close(state.subwin.win, true)
  end
  state.subwin = nil
end

function M.select_by_number(num)
  -- Only handle numbered workspaces (not actions)
  local workspace_count = 0
  for _, item in ipairs(state.menu_items) do
    if item.type == "workspace" then
      workspace_count = workspace_count + 1
      if workspace_count == num then
        -- Directly open the workspace without confirmation
        close_window()
        workspace.open_workspace(item.name)
        return
      end
    end
  end
end

function M.trigger_action(action)
  close_window()
  
  if action == "add_dir" then
    workspace.add_current_dir()
    vim.notify("Current directory added to workspaces", vim.log.levels.INFO)
  elseif action == "remove_dir" then
    workspace.remove_current_dir()
    vim.notify("Current directory removed from workspaces", vim.log.levels.INFO)
  end
end

function M.close_window()
  close_window()
end

local function setup_keymaps(config)
  local keymaps = config.ui.keymaps
  
  -- Set keymaps
  vim.keymap.set("n", keymaps.select, function() M.select_item() end, { buffer = state.buf, silent = true })
  vim.keymap.set("n", keymaps.quit, function() M.close_window() end, { buffer = state.buf, silent = true })
  vim.keymap.set("n", keymaps.up, function() M.navigate(-1) end, { buffer = state.buf, silent = true })
  vim.keymap.set("n", keymaps.down, function() M.navigate(1) end, { buffer = state.buf, silent = true })
  
  -- Also support alternative keys for navigation
  vim.keymap.set("n", "j", function() M.navigate(1) end, { buffer = state.buf, silent = true })
  vim.keymap.set("n", "k", function() M.navigate(-1) end, { buffer = state.buf, silent = true })
  vim.keymap.set("n", "<CR>", function() M.select_item() end, { buffer = state.buf, silent = true })
  vim.keymap.set("n", "q", function() M.close_window() end, { buffer = state.buf, silent = true })
  
  -- Direct action keymaps (like lazygit)
  vim.keymap.set("n", "a", function() M.trigger_action("add_dir") end, { buffer = state.buf, silent = true })
  vim.keymap.set("n", "d", function() M.trigger_action("remove_dir") end, { buffer = state.buf, silent = true })
  
  -- Number keymaps for workspaces only (count actual workspaces)
  local workspace_count = 0
  for _, item in ipairs(state.menu_items or {}) do
    if item.type == "workspace" then
      workspace_count = workspace_count + 1
    end
  end
  
  for i = 1, math.min(workspace_count, 9) do
    vim.keymap.set("n", tostring(i), function() M.select_by_number(i) end, { buffer = state.buf, silent = true })
  end
end

local function create_main_menu(config)
  -- Initialize state if it doesn't exist
  state = state or {
    win = nil,
    buf = nil,
    menu_items = {},
    current_selection = 1,
    scroll_pos = 0
  }

  -- Save current session before opening menu
  local session = require("work_session.session")
  local ok, err = pcall(session.save_session, vim.fn.getcwd())
  if not ok then
    vim.notify("Failed to save session: " .. tostring(err), vim.log.levels.ERROR)
  end

  -- Create and render UI
  create_window(config)
  render_menu(config)
  setup_keymaps(config)
  
  -- Set initial cursor position if we have items
  if state.menu_items and #state.menu_items > 0 then
    vim.api.nvim_win_set_cursor(state.win, {state.menu_items[1].line + 1, 0})
  end
end

function M.scroll_down()
  if not state.win then return end
  local config = require("work_session.config").default_config
  local visible_lines = config.ui.height - 4
  if state.scroll_pos + visible_lines < #state.menu_items then
    state.scroll_pos = state.scroll_pos + 1
    render_menu(config)
  end
end

function M.scroll_up()
  if not state.win then return end
  if state.scroll_pos > 0 then
    state.scroll_pos = state.scroll_pos - 1
    render_menu(require("work_session.config").default_config)
  end
end

-- Expose the create_main_menu function
M.create_main_menu = create_main_menu

return M
