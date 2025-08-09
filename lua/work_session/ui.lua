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

  local lines = {}
  if not state.buf or not vim.api.nvim_buf_is_valid(state.buf) then return end
  
  local lines = {}
  local hl = {}
  
  -- Header
  table.insert(lines, "Work Session Manager")
  table.insert(lines, string.rep("=", config.ui.width))
  table.insert(lines, "")
  
  -- Workspaces section
  table.insert(lines, "Workspaces:")
  local workspaces = workspace.get_workspaces()
  state.menu_items = {}
  
   -- Calculate visible range based on scroll position
  state.scroll_pos = state.scroll_pos or 0
  local visible_lines = config.ui.height - 4  -- Account for header/footer
  local total_items = #state.menu_items
  
  -- Adjust scroll position if needed
  if state.current_selection < state.scroll_pos + 1 then
    state.scroll_pos = state.current_selection - 1
  elseif state.current_selection > state.scroll_pos + visible_lines then
    state.scroll_pos = state.current_selection - visible_lines
  end
  
  -- Add visible items only
  for i = state.scroll_pos + 1, math.min(state.scroll_pos + visible_lines, total_items) do
    local item = state.menu_items[i]
    if item.type == "workspace" then
      table.insert(lines, string.format("%d. %s", i, item.name))
    elseif item.type == "action" then
      table.insert(lines, string.format("%s. %s", 
        item.action == "add_dir" and "a" or "d",
        item.action == "add_dir" and "Add current directory to workspaces" or "Remove current directory from workspaces"
      ))
    end
  end

  -- In ui.lua's render_menu function:
  local venv_status = ""
  if package.loaded["venv-selector"] then
    local venv = require("venv-selector").venv()
    venv_status = venv and " (venv: "..vim.fn.fnamemodify(venv, ":t")..")" or ""
  end
  table.insert(lines, 1, "Work Session Manager"..venv_status)


  -- Footer with keybinds
  table.insert(lines, "")
  table.insert(lines, string.rep("-", config.ui.width))
  local footer = "Select: " .. config.ui.keymaps.select
  footer = footer .. " | Navigate: " .. config.ui.keymaps.up .. "/" .. config.ui.keymaps.down
  footer = footer .. " | Quit: " .. config.ui.keymaps.quit
  table.insert(lines, footer)
  
  -- Add scroll indicator if needed
  if total_items > visible_lines then
    local scroll_info = string.format(" [%d-%d/%d] ", 
      state.scroll_pos + 1,
      math.min(state.scroll_pos + visible_lines, total_items),
      total_items
    )
    table.insert(lines, 3, scroll_info)  -- Add after header
  end

  -- Set buffer content
  vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, lines)
  
  -- Highlight current selection
  vim.api.nvim_buf_clear_namespace(state.buf, -1, 0, -1)
  if state.current_selection > 0 and state.current_selection <= #state.menu_items then
    vim.api.nvim_buf_add_highlight(
      state.buf, 
      -1, 
      "CursorLine", 
      state.menu_items[state.current_selection].line, 
      0, 
      -1
    )
    vim.api.nvim_win_set_cursor(state.win, {state.menu_items[state.current_selection].line + 1, 0})
  end
end

function M.navigate(direction)
  if not state.win or not vim.api.nvim_win_is_valid(state.win) then return end
  
  local new_selection = state.current_selection + direction
  if new_selection < 1 then new_selection = #state.menu_items end
  if new_selection > #state.menu_items then new_selection = 1 end
  
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
  if num > #state.menu_items then return end
  state.current_selection = num
  M.select_item()
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
  
  -- Set initial cursor position if we have items
  if state.menu_items and #state.menu_items > 0 then
    vim.api.nvim_win_set_cursor(state.win, {state.menu_items[1].line + 1, 0})
  end
end

local function setup_keymaps(config)
  local keymaps = config.ui.keymaps
  
  -- Clear existing keymaps first
  vim.api.nvim_buf_set_keymap(state.buf, "n", keymaps.select, "", {})
  vim.api.nvim_buf_set_keymap(state.buf, "n", keymaps.quit, "", {})
  vim.api.nvim_buf_set_keymap(state.buf, "n", keymaps.up, "", {})
  vim.api.nvim_buf_set_keymap(state.buf, "n", keymaps.down, "", {})
  
  -- Set new keymaps
  vim.keymap.set("n", keymaps.select, function() M.select_item() end, { buffer = state.buf, silent = true })
  vim.keymap.set("n", keymaps.quit, function() M.close_window() end, { buffer = state.buf, silent = true })
  vim.keymap.set("n", keymaps.up, function() M.navigate(-1) end, { buffer = state.buf, silent = true })
  vim.keymap.set("n", keymaps.down, function() M.navigate(1) end, { buffer = state.buf, silent = true })
  
  -- Number keymaps for workspaces
  for i = 1, 9 do
    vim.keymap.set("n", tostring(i), function() M.select_by_number(i) end, { buffer = state.buf, silent = true })
  end
  
  -- Action keymaps
  vim.keymap.set("n", keymaps.add_dir, function() M.trigger_action("add_dir") end, { buffer = state.buf, silent = true })
  vim.keymap.set("n", keymaps.remove_dir, function() M.trigger_action("remove_dir") end, { buffer = state.buf, silent = true })
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

return M
