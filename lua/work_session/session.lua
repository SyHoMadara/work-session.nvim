local M = {}
local uv = vim.loop

function M.setup(config)
  M.config = config
  
  -- Set up auto-save functionality
  if config.auto_save and config.auto_save.enabled then
    M.setup_auto_save(config)
  end
end

function M.setup_auto_save(config)
  local auto_save = config.auto_save
  
  -- Save on exit
  if auto_save.on_exit then
    vim.api.nvim_create_autocmd("VimLeavePre", {
      group = vim.api.nvim_create_augroup("WorkSessionAutoSave", { clear = true }),
      callback = function()
        M.save_current_session()
      end,
      desc = "Auto-save work session on exit"
    })
  end
  
  -- Save on focus lost
  if auto_save.on_focus_lost then
    vim.api.nvim_create_autocmd("FocusLost", {
      group = vim.api.nvim_create_augroup("WorkSessionAutoSave", { clear = false }),
      callback = function()
        M.save_current_session()
      end,
      desc = "Auto-save work session on focus lost"
    })
  end
  
  -- Periodic auto-save
  if auto_save.periodic and auto_save.periodic.enabled and auto_save.periodic.interval > 0 then
    local timer = uv.new_timer()
    timer:start(auto_save.periodic.interval, auto_save.periodic.interval, vim.schedule_wrap(function()
      M.save_current_session()
    end))
  end
end

function M.save_current_session()
  -- Save session for current working directory
  local current_dir = vim.fn.getcwd()
  local ok, err = pcall(M.save_session, current_dir)
  if not ok then
    -- Only notify on error if debug mode is enabled
    if vim.g.work_session_debug then
      vim.notify("Failed to auto-save session: " .. tostring(err), vim.log.levels.WARN)
    end
  end
end

function M.save_session(workspace_path)
  local session_dir = require("work_session.config").default_config.session_dir
  local session_path = workspace_path .. "/" .. session_dir
  
  -- Create session directory if needed
  uv.fs_mkdir(session_path, tonumber("755", 8))
  
  -- Save buffer list (only valid, named buffers)
  local buffers = {}
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) and vim.api.nvim_buf_is_valid(buf) then
      local buf_name = vim.api.nvim_buf_get_name(buf)
      local buf_type = vim.api.nvim_buf_get_option(buf, "buftype")
      
      -- Only save real files (not terminals, help files, etc.)
      if buf_name ~= "" and buf_type == "" then
        -- Make path relative to workspace if possible
        local relative_path = vim.fn.fnamemodify(buf_name, ":.")
        table.insert(buffers, relative_path)
      end
    end
  end
  
  -- Debug output
  if vim.g.work_session_debug then
    vim.notify("Saving session to: " .. session_path .. " with " .. #buffers .. " buffers", vim.log.levels.INFO)
  end
  
  local buf_file = session_path .. "/buffers.txt"
  local file = io.open(buf_file, "w")
  if file then
    for _, buf_path in ipairs(buffers) do
      file:write(buf_path, "\n")
    end
    file:close()
  end
  
  -- Save current working directory
  local cwd_file = session_path .. "/cwd.txt"
  local file = io.open(cwd_file, "w")
  if file then
    file:write(vim.fn.getcwd())
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
  
  -- Save session metadata
  local meta_file = session_path .. "/metadata.txt"
  local file = io.open(meta_file, "w")
  if file then
    file:write("saved_at=" .. os.time() .. "\n")
    file:write("nvim_version=" .. vim.version().major .. "." .. vim.version().minor .. "." .. vim.version().patch .. "\n")
    file:write("buffer_count=" .. #buffers .. "\n")
    file:close()
  end

end

function M.restore_session(workspace_path)
  local session_dir = require("work_session.config").default_config.session_dir
  local session_path = workspace_path .. "/" .. session_dir
  
  -- Debug output
  if vim.g.work_session_debug then
    vim.notify("Attempting to restore session from: " .. session_path, vim.log.levels.INFO)
  end
  
  -- Check if session exists
  local buf_file = session_path .. "/buffers.txt"
  local file = io.open(buf_file, "r")
  if not file then
    -- No session to restore
    if vim.g.work_session_debug then
      vim.notify("No session file found at: " .. buf_file, vim.log.levels.INFO)
    end
    return false
  end
  
  -- Restore working directory if saved
  local cwd_file = session_path .. "/cwd.txt"
  local cwd_file_handle = io.open(cwd_file, "r")
  if cwd_file_handle then
    local saved_cwd = cwd_file_handle:read("*a"):gsub("%s+", "")
    cwd_file_handle:close()
    if saved_cwd and saved_cwd ~= "" then
      vim.cmd("cd " .. vim.fn.fnameescape(saved_cwd))
    end
  end
  
  -- Restore buffers
  local buffers_restored = 0
  for line in file:lines() do
    if line and line ~= "" then
      -- Handle both relative and absolute paths
      local file_path = line
      
      -- If it's a relative path, make it relative to the workspace
      if not vim.fn.fnamemodify(file_path, ":p"):match("^/") then
        file_path = workspace_path .. "/" .. file_path
      end
      
      -- Only try to open if file exists
      if vim.fn.filereadable(file_path) == 1 then
        local success = pcall(vim.cmd, "e " .. vim.fn.fnameescape(file_path))
        if success then
          buffers_restored = buffers_restored + 1
        end
      else
        -- Debug info for missing files
        if vim.g.work_session_debug then
          vim.notify("Buffer file not found: " .. file_path, vim.log.levels.WARN)
        end
      end
    end
  end
  file:close()
  
  -- Restore virtual environment
  local config = require("work_session.config").default_config
  if config.venv_selector then
    -- First deactivate any current venv
    if config.venv_selector.deactivate then
      config.venv_selector.deactivate()
    end
    
    -- Then restore saved venv if exists
    local venv_file = session_path .. "/venv.txt"
    local venv_file_handle = io.open(venv_file, "r")
    if venv_file_handle then
      local venv = venv_file_handle:read("*a"):gsub("%s+", "")
      venv_file_handle:close()
      if venv and venv ~= "" and config.venv_selector.set_current then
        config.venv_selector.set_current(venv)
      end
    end
  end
  
  -- Show restoration info
  if buffers_restored > 0 then
    vim.notify("Restored " .. buffers_restored .. " buffers from work session", vim.log.levels.INFO)
  end
  
  return true
end

function M.get_session_info(workspace_path)
  local session_dir = require("work_session.config").default_config.session_dir
  local session_path = workspace_path .. "/" .. session_dir
  
  local info = {
    exists = false,
    buffer_count = 0,
    saved_at = nil,
    has_venv = false
  }
  
  -- Check metadata
  local meta_file = session_path .. "/metadata.txt"
  local file = io.open(meta_file, "r")
  if file then
    info.exists = true
    for line in file:lines() do
      local key, value = line:match("(.+)=(.+)")
      if key == "saved_at" then
        info.saved_at = tonumber(value)
      elseif key == "buffer_count" then
        info.buffer_count = tonumber(value) or 0
      end
    end
    file:close()
  end
  
  -- Check if venv exists
  local venv_file = session_path .. "/venv.txt"
  local venv_file_handle = io.open(venv_file, "r")
  if venv_file_handle then
    info.has_venv = true
    venv_file_handle:close()
  end
  
  return info
end

return M
