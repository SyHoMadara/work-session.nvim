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
  local height = config.ui.height or 25
  
  -- Calculate position based on config
  local col, row
  local position = config.ui.position or "center"
  
  if position == "center" then
    col = math.floor((vim.o.columns - width) / 2) + (config.ui.col_offset or 0)
    row = math.floor((vim.o.lines - height) / 3) + (config.ui.row_offset or 0)
  elseif position == "top" then
    col = math.floor((vim.o.columns - width) / 2) + (config.ui.col_offset or 0)
    row = 2 + (config.ui.row_offset or 0)
  elseif position == "bottom" then
    col = math.floor((vim.o.columns - width) / 2) + (config.ui.col_offset or 0)
    row = vim.o.lines - height - 5 + (config.ui.row_offset or 0)
  else
    -- Default to center if invalid position
    col = math.floor((vim.o.columns - width) / 2) + (config.ui.col_offset or 0)
    row = math.floor((vim.o.lines - height) / 3) + (config.ui.row_offset or 0)
  end
  
  -- Create window
  state.win = vim.api.nvim_open_win(state.buf, true, {
    relative = "editor",
    width = width,
    height = height,
    col = col,
    row = row,
    style = "minimal",
    border = config.ui.border or "rounded"
  })

  -- Set window options
  vim.api.nvim_win_set_option(state.win, "number", false)
  vim.api.nvim_win_set_option(state.win, "relativenumber", false)
  vim.api.nvim_win_set_option(state.win, "cursorline", true)
  
  -- Set highlight groups if configured
  if config.ui.highlight then
    if config.ui.highlight.normal then
      vim.api.nvim_win_set_option(state.win, "winhl", "Normal:" .. config.ui.highlight.normal)
    end
  end
  
  -- Set buffer options to make it properly closeable (but keep it modifiable for now)
  vim.api.nvim_buf_set_option(state.buf, "buftype", "nofile")
  vim.api.nvim_buf_set_option(state.buf, "swapfile", false)
end

local function create_subwindow(content, title)
  -- Calculate size based on content
  local max_width = 0
  for _, line in ipairs(content) do
    max_width = math.max(max_width, #line)
  end
  
  local width = math.max(max_width + 4, 30)  -- Minimum width of 30
  local height = #content + 2  -- Add padding
  
  -- Create a scratch buffer
  local buf = vim.api.nvim_create_buf(false, true)
  
  -- Create a centered window with appropriate size
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    col = math.floor((vim.o.columns - width) / 2),
    row = math.floor((vim.o.lines - height) / 2),
    style = "minimal",
    border = "rounded",
    title = title,
    title_pos = "center"
  })
  
  -- Set content
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, content)
  vim.api.nvim_buf_set_option(buf, "modifiable", false)
  vim.api.nvim_buf_set_option(buf, "buftype", "nofile")
  vim.api.nvim_buf_set_option(buf, "swapfile", false)
  vim.api.nvim_win_set_option(win, "wrap", true)
  vim.api.nvim_win_set_option(win, "cursorline", false)
  
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
  
  -- Header with venv status (if enabled)
  local header = (config.ui.icons and config.ui.icons.workspace or "") .. "Work Session Manager"
  if config.ui.show_venv_status ~= false and package.loaded["venv-selector"] then
    local venv = require("venv-selector").venv()
    local venv_status = venv and " (venv: "..vim.fn.fnamemodify(venv, ":t")..")" or ""
    header = header .. venv_status
  end
  table.insert(lines, header)
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
    local workspace_icon = config.ui.icons and config.ui.icons.workspace or ""
    table.insert(lines, string.format("%d. %s%s", i, workspace_icon, ws.name))
    line_index = line_index + 1
  end
  
  -- Add separator and actions section
  if #workspaces > 0 and config.ui.show_separator ~= false then
    table.insert(lines, "")
    local sep_char = config.ui.separator_char or "─"
    table.insert(lines, string.rep(sep_char, config.ui.width or 60))
    line_index = line_index + 2
  elseif #workspaces > 0 then
    table.insert(lines, "")
    line_index = line_index + 1
  end
  
  table.insert(lines, "Actions:")
  line_index = line_index + 1
  
  -- Add workspace management actions
  table.insert(state.menu_items, {
    type = "action",
    action = "add_dir",
    line = line_index
  })
  local add_icon = config.ui.icons and config.ui.icons.add or ""
  table.insert(lines, string.format("a. %sAdd current directory to workspaces", add_icon))
  line_index = line_index + 1
  
  table.insert(state.menu_items, {
    type = "action",
    action = "remove_dir", 
    line = line_index
  })
  local remove_icon = config.ui.icons and config.ui.icons.remove or ""
  table.insert(lines, string.format("d. %sRemove current directory from workspaces", remove_icon))
  line_index = line_index + 1

  -- Auto-save toggle actions
  table.insert(state.menu_items, {
    type = "action",
    action = "toggle_auto_save_exit",
    line = line_index
  })
  local current_config = require("work_session").config
  local exit_status = current_config.auto_save.on_exit and "ON" or "OFF"
  table.insert(lines, string.format("e.  Toggle auto-save on exit [%s]", exit_status))
  line_index = line_index + 1

  table.insert(state.menu_items, {
    type = "action", 
    action = "toggle_auto_save_focus",
    line = line_index
  })
  local focus_status = current_config.auto_save.on_focus_lost and "ON" or "OFF"
  table.insert(lines, string.format("f.  Toggle auto-save on focus lost [%s]", focus_status))
  line_index = line_index + 1

  table.insert(state.menu_items, {
    type = "action",
    action = "toggle_auto_save_periodic", 
    line = line_index
  })
  local periodic_status = current_config.auto_save.periodic.enabled and "ON" or "OFF"
  table.insert(lines, string.format("p.  Toggle periodic auto-save [%s]", periodic_status))
  line_index = line_index + 1

  table.insert(state.menu_items, {
    type = "action",
    action = "save_session_now",
    line = line_index  
  })
  table.insert(lines, "s.  Save session now")

  -- Footer with keybinds
  table.insert(lines, "")
  table.insert(lines, string.rep("-", config.ui.width or 60))
  local footer = "Select: " .. config.ui.keymaps.select .. "/" .. "<CR>"
  footer = footer .. " | Help: ? | Quit: q/" .. config.ui.keymaps.quit
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
  local config = require("work_session.config").default_config
  
  if item.type == "workspace" then
    -- Check if confirmation is enabled
    if config.ui.confirm_workspace_open == false then
      -- Direct open without confirmation
      close_window()
      workspace.open_workspace(item.name)
      return
    end
    
    -- Show confirmation dialog
    local content = {
      "Open workspace: " .. item.name .. "?",
      "",
      "<Enter> Yes    <Esc> Cancel"
    }
    
    local subwin = create_subwindow(content, "Confirm Open")
    
    vim.keymap.set("n", "<CR>", function()
      M._close_subwindow()
      close_window()
      workspace.open_workspace(item.name)
    end, { buffer = subwin.buf, silent = true })
      
    vim.keymap.set("n", "<Esc>", function()
      M._close_subwindow()
    end, { buffer = subwin.buf, silent = true })
    
    -- Store subwin reference for proper cleanup
    state.subwin = subwin
      
  elseif item.type == "action" then
    M.trigger_action(item.action)
  end
end

function M.show_help()
  local content = {
    "Work Session Manager - Help",
    string.rep("=", 40),
    "",
    "Navigation:",
    "  j/k, ↑/↓    - Navigate menu",
    "  <Space>/<CR> - Select item",
    "  1-9          - Quick open workspace",
    "",
    "Workspace Actions:",
    "  a            - Add current directory to workspaces",
    "  d            - Remove current directory from workspaces",
    "",
    "Session Actions:",
    "  e            - Toggle auto-save on exit",
    "  f            - Toggle auto-save on focus lost",
    "  p            - Toggle periodic auto-save",
    "  s            - Save session now",
    "",
    "Other:",
    "  ?            - Show this help",
    "  q/<Esc>      - Quit/Close",
    "",
    "Workspace Details:",
    "  When opening a workspace, you'll see:",
    "  - Workspace name and full path",
    "  - Session restoration if available",
    "",
    "Auto-Save Features:",
    "  - Toggle options show current status [ON/OFF]",
    "  - Changes take effect immediately",
    "  - Settings persist during session",
    "",
    "Press <Esc> to close this help"
  }
  
  local subwin = create_subwindow(content, "Help")
  
  vim.keymap.set("n", "<Esc>", function()
    M._close_subwindow()
  end, { buffer = subwin.buf, silent = true })
  
  vim.keymap.set("n", "q", function()
    M._close_subwindow()
  end, { buffer = subwin.buf, silent = true })
  
  -- Store subwin reference
  state.subwin = subwin
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
  elseif action == "toggle_auto_save_exit" then
    local config = require("work_session").config
    config.auto_save.on_exit = not config.auto_save.on_exit
    local status = config.auto_save.on_exit and "enabled" or "disabled"
    vim.notify("Auto-save on exit " .. status, vim.log.levels.INFO)
    -- Reinitialize auto-save with new settings
    require("work_session.session").setup_auto_save(config)
  elseif action == "toggle_auto_save_focus" then
    local config = require("work_session").config
    config.auto_save.on_focus_lost = not config.auto_save.on_focus_lost
    local status = config.auto_save.on_focus_lost and "enabled" or "disabled"
    vim.notify("Auto-save on focus lost " .. status, vim.log.levels.INFO)
    -- Reinitialize auto-save with new settings
    require("work_session.session").setup_auto_save(config)
  elseif action == "toggle_auto_save_periodic" then
    local config = require("work_session").config
    config.auto_save.periodic.enabled = not config.auto_save.periodic.enabled
    local status = config.auto_save.periodic.enabled and "enabled" or "disabled"
    vim.notify("Periodic auto-save " .. status, vim.log.levels.INFO)
    -- Reinitialize auto-save with new settings
    require("work_session.session").setup_auto_save(config)
  elseif action == "save_session_now" then
    require("work_session.session").save_current_session()
    vim.notify("Session saved manually", vim.log.levels.INFO)
  end
end

function M.close_window()
  close_window()
end

local function setup_keymaps(config)
  local keymaps = config.ui.keymaps
  
  -- Primary keymaps
  vim.keymap.set("n", keymaps.select or "<Space>", function() M.select_item() end, { buffer = state.buf, silent = true })
  vim.keymap.set("n", keymaps.quit or "<Esc>", function() M.close_window() end, { buffer = state.buf, silent = true })
  vim.keymap.set("n", keymaps.up or "<Up>", function() M.navigate(-1) end, { buffer = state.buf, silent = true })
  vim.keymap.set("n", keymaps.down or "<Down>", function() M.navigate(1) end, { buffer = state.buf, silent = true })
  
  -- Alternative keymaps
  if keymaps.alt_select then
    vim.keymap.set("n", keymaps.alt_select, function() M.select_item() end, { buffer = state.buf, silent = true })
  end
  if keymaps.alt_quit then
    vim.keymap.set("n", keymaps.alt_quit, function() M.close_window() end, { buffer = state.buf, silent = true })
  end
  if keymaps.nav_up then
    vim.keymap.set("n", keymaps.nav_up, function() M.navigate(-1) end, { buffer = state.buf, silent = true })
  end
  if keymaps.nav_down then
    vim.keymap.set("n", keymaps.nav_down, function() M.navigate(1) end, { buffer = state.buf, silent = true })
  end
  
  -- Action keymaps
  vim.keymap.set("n", keymaps.add_dir or "a", function() M.trigger_action("add_dir") end, { buffer = state.buf, silent = true })
  vim.keymap.set("n", keymaps.remove_dir or "d", function() M.trigger_action("remove_dir") end, { buffer = state.buf, silent = true })
  
  -- Auto-save toggle keymaps
  vim.keymap.set("n", keymaps.toggle_auto_save_exit or "e", function() M.trigger_action("toggle_auto_save_exit") end, { buffer = state.buf, silent = true })
  vim.keymap.set("n", keymaps.toggle_auto_save_focus or "f", function() M.trigger_action("toggle_auto_save_focus") end, { buffer = state.buf, silent = true })
  vim.keymap.set("n", keymaps.toggle_auto_save_periodic or "p", function() M.trigger_action("toggle_auto_save_periodic") end, { buffer = state.buf, silent = true })
  vim.keymap.set("n", keymaps.save_session_now or "s", function() M.trigger_action("save_session_now") end, { buffer = state.buf, silent = true })
  
  -- Help keymap
  vim.keymap.set("n", keymaps.help or "?", function() M.show_help() end, { buffer = state.buf, silent = true })
  
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

  -- Don't save session here - it will be saved when actually switching workspaces
  -- This prevents overwriting session files of the workspace we want to open

  -- Create and render UI
  create_window(config)
  render_menu(config)
  setup_keymaps(config)
  
  -- Set initial cursor position if we have items
  if state.menu_items and #state.menu_items > 0 then
    vim.api.nvim_win_set_cursor(state.win, {state.menu_items[1].line + 1, 0})
  end
end

-- Expose the create_main_menu function
M.create_main_menu = create_main_menu

return M
