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
  local ui = config.ui
  local width = ui.width
  local height = ui.height
  local border = ui.border
  
  -- Create buffer
  state.buf = vim.api.nvim_create_buf(false, true)
  
  -- Get editor dimensions
  local editor_width = vim.api.nvim_win_get_width(0)
  local editor_height = vim.api.nvim_win_get_height(0)
  
  -- Calculate position
  local col = (editor_width - width) / 2
  local row = (editor_height - height) / 2
  
  -- Create window
  state.win = vim.api.nvim_open_win(state.buf, true, {
    relative = "editor",
    width = width,
    height = height,
    col = col,
    row = row,
    style = "minimal",
    border = border
  })
  
  -- Set window options
  vim.api.nvim_win_set_option(state.win, "number", false)
  vim.api.nvim_win_set_option(state.win, "relativenumber", false)
  vim.api.nvim_win_set_option(state.win, "cursorline", true)
end

local function render_menu(config)
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
  
  for i, ws in ipairs(workspaces) do
    local prefix = i .. ". "
    table.insert(lines, prefix .. ws.name)
    table.insert(state.menu_items, {
      type = "workspace",
      name = ws.name,
      path = ws.path,
      line = #lines
    })
  end
  
  -- Actions section
  table.insert(lines, "")
  table.insert(lines, "Actions:")
  table.insert(lines, "a. Add current directory to workspaces")
  table.insert(state.menu_items, {
    type = "action",
    action = "add_dir",
    line = #lines
  })
  
  table.insert(lines, "d. Remove current directory from workspaces")
  table.insert(state.menu_items, {
    type = "action",
    action = "remove_dir",
    line = #lines
  })
  
  -- Footer with keybinds
  table.insert(lines, "")
  table.insert(lines, string.rep("-", config.ui.width))
  local footer = "Select: " .. config.ui.keymaps.select
  footer = footer .. " | Navigate: " .. config.ui.keymaps.up .. "/" .. config.ui.keymaps.down
  footer = footer .. " | Quit: " .. config.ui.keymaps.quit
  table.insert(lines, footer)
  
  -- Set buffer content
  vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, lines)
  
  -- Highlight current selection
  vim.api.nvim_buf_add_highlight(state.buf, -1, "CursorLine", state.current_selection, 0, -1)
  
  -- Set keymaps
  local keymaps = config.ui.keymaps
  vim.api.nvim_buf_set_keymap(state.buf, "n", keymaps.up, "<cmd>lua require('work_session.ui').navigate(-1)<CR>", {silent = true})
  vim.api.nvim_buf_set_keymap(state.buf, "n", keymaps.down, "<cmd>lua require('work_session.ui').navigate(1)<CR>", {silent = true})
  vim.api.nvim_buf_set_keymap(state.buf, "n", keymaps.select, "<cmd>lua require('work_session.ui').select_item()<CR>", {silent = true})
  vim.api.nvim_buf_set_keymap(state.buf, "n", keymaps.quit, "<cmd>lua require('work_session.ui').close_window()<CR>", {silent = true})
  
  -- Number keymaps for workspaces
  for i = 1, #workspaces do
    vim.api.nvim_buf_set_keymap(state.buf, "n", tostring(i), 
      "<cmd>lua require('work_session.ui').select_by_number(" .. i .. ")<CR>", 
      {silent = true})
  end
  
  -- Action keymaps
  vim.api.nvim_buf_set_keymap(state.buf, "n", keymaps.add_dir, 
    "<cmd>lua require('work_session.ui').trigger_action('add_dir')<CR>", 
    {silent = true})
    
  vim.api.nvim_buf_set_keymap(state.buf, "n", keymaps.remove_dir, 
    "<cmd>lua require('work_session.ui').trigger_action('remove_dir')<CR>", 
    {silent = true})
end

function M.navigate(direction)
  if not state.win or not vim.api.nvim_win_is_valid(state.win) then return end
  
  local new_selection = state.current_selection + direction
  if new_selection < 1 then new_selection = 1 end
  if new_selection > #state.menu_items then new_selection = #state.menu_items end
  
  -- Clear previous highlight
  vim.api.nvim_buf_clear_namespace(state.buf, -1, 0, -1)
  
  -- Update selection
  state.current_selection = new_selection
  
  -- Apply new highlight
  vim.api.nvim_buf_add_highlight(
    state.buf, 
    -1, 
    "CursorLine", 
    state.menu_items[new_selection].line, 
    0, 
    -1
  )
  
  -- Move cursor
  vim.api.nvim_win_set_cursor(state.win, {state.menu_items[new_selection].line + 1, 0})
end

function M.select_item()
  if not state.win or #state.menu_items == 0 then return end
  local item = state.menu_items[state.current_selection]
  
  if item.type == "workspace" then
    close_window()
    workspace.open_workspace(item.name)
  elseif item.type == "action" then
    M.trigger_action(item.action)
  end
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

function M.create_main_menu(config)
  -- Save current session before opening menu
  local session = require("work_session.session")
  session.save_session(vim.fn.getcwd())
  
  -- Create and render UI
  create_window(config)
  render_menu(config)
  
  -- Set initial cursor position
  vim.api.nvim_win_set_cursor(state.win, {state.menu_items[1].line + 1, 0})
end

return M
