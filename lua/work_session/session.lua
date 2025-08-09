local M = {}
local uv = vim.loop

function M.setup(config)
  M.config = config
end

function M.save_session(workspace_path)
  local session_dir = require("work_session.config").default_config.session_dir
  local session_path = workspace_path .. "/" .. session_dir
  
  -- Create session directory if needed
  uv.fs_mkdir(session_path, tonumber("755", 8))
  
  -- Save buffer list
  local buffers = {}
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) then
      local buf_name = vim.api.nvim_buf_get_name(buf)
      if buf_name ~= "" then
        table.insert(buffers, buf_name)
      end
    end
  end
  
  local buf_file = session_path .. "/buffers.txt"
  local file = io.open(buf_file, "w")
  if file then
    for _, buf_path in ipairs(buffers) do
      file:write(buf_path, "\n")
    end
    file:close()
  end
  
  -- Save virtual environment if available
  local config = require("work_session.config").default_config
  if config.venv_selector and config.venv_selector.get_current then
    local venv = config.venv_selector.get_current()
    if venv and venv ~= "" then
      local venv_file = session_path .. "/venv.txt"
      local file = io.open(venv_file, "w")
      if file then
        file:write(venv)
        file:close()
      end
    end
  end

end

function M.restore_session(workspace_path)
  local session_dir = require("work_session.config").default_config.session_dir
  local session_path = workspace_path .. "/" .. session_dir
  
  -- Restore buffers
  local buf_file = session_path .. "/buffers.txt"
  local file = io.open(buf_file, "r")
  if file then
    for line in file:lines() do
      pcall(vim.cmd, "e " .. line)
    end
    file:close()
  end
  
  -- Restore virtual environment
  local config = require("work_session.config").default_config
  if config.venv_selector then
    -- First deactivate any current venv
    config.venv_selector.deactivate()
    
    -- Then restore saved venv if exists
    local venv_file = session_path .. "/venv.txt"
    local file = io.open(venv_file, "r")
    if file then
      local venv = file:read("*a")
      file:close()
      if venv and venv ~= "" then
        config.venv_selector.set_current(venv)
      end
    end
  end
end

return M
