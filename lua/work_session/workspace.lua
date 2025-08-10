local M = {}

function M.setup(config)
  M.config = config
end

function M.get_workspaces()
  local ok, workspaces = pcall(require, "workspaces")
  if not ok then return {} end
  return workspaces.get()
end

function M.open_workspace(name)
  -- Save current session before switching workspaces
  local current_dir = vim.fn.getcwd()
  local session = require("work_session.session")
  local ok, err = pcall(session.save_session, current_dir)
  if not ok then
    vim.notify("Failed to save current session: " .. tostring(err), vim.log.levels.WARN)
  end

  -- Open the new workspace
  local config = require("work_session.config").default_config
  config.workspaces.open(name)
  
  -- Restore session after opening (with small delay to ensure directory change is complete)
  vim.schedule(function()
    vim.defer_fn(function()
      local new_dir = vim.fn.getcwd()
      local session_module = require("work_session.session")
      local restored = session_module.restore_session(new_dir)
      if not restored then
        vim.notify("No previous session found for this workspace", vim.log.levels.INFO)
      end
    end, 50) -- 50ms delay to ensure workspace change is complete
  end)
end

function M.add_current_dir()
  local ok, workspaces = pcall(require, "workspaces")
  if ok then
    workspaces.add(vim.fn.getcwd())
  end
end

function M.remove_current_dir()
  local ok, workspaces = pcall(require, "workspaces")
  if ok then
    workspaces.remove(vim.fn.getcwd())
  end
end

function M.has_session_data(path)
  -- Check if directory has a .work_session folder with session files
  local session_dir = require("work_session.config").default_config.session_dir
  local session_path = path .. "/" .. session_dir
  
  -- Check if session directory exists
  if vim.fn.isdirectory(session_path) == 0 then
    return false
  end
  
  -- Check if it has actual session files
  local buffers_file = session_path .. "/buffers.txt"
  local metadata_file = session_path .. "/metadata.txt"
  
  return vim.fn.filereadable(buffers_file) == 1 or vim.fn.filereadable(metadata_file) == 1
end

function M.auto_detect_and_restore_session(path)
  -- Auto-detect and restore session if directory has session data
  path = path or vim.fn.getcwd()
  
  if M.has_session_data(path) then
    if vim.g.work_session_debug then
      vim.notify("Auto-detected session data in: " .. path, vim.log.levels.INFO)
    end
    
    -- Restore the session
    vim.schedule(function()
      local session_module = require("work_session.session")
      local restored = session_module.restore_session(path)
      if restored then
        vim.notify("Auto-restored work session from: " .. vim.fn.fnamemodify(path, ":t"), vim.log.levels.INFO)
      end
    end)
    
    return true
  end
  
  return false
end

function M.setup_auto_detection()
  -- Set up auto-detection when changing directories
  local config = require("work_session.config").default_config
  
  if config.auto_detect and config.auto_detect.enabled then
    -- Auto-detect on directory change
    if config.auto_detect.on_dir_change then
      vim.api.nvim_create_autocmd("DirChanged", {
        group = vim.api.nvim_create_augroup("WorkSessionAutoDetect", { clear = true }),
        callback = function(args)
          -- Only auto-detect for 'global' directory changes (not window-local)
          if args.scope == "global" then
            vim.defer_fn(function()
              M.auto_detect_and_restore_session(args.file)
            end, 100) -- Small delay to ensure directory change is complete
          end
        end,
        desc = "Auto-detect and restore work session on directory change"
      })
    end
    
    -- Auto-detect on Neovim startup
    if config.auto_detect.on_startup then
      vim.api.nvim_create_autocmd("VimEnter", {
        group = vim.api.nvim_create_augroup("WorkSessionAutoDetect", { clear = false }),
        callback = function()
          vim.defer_fn(function()
            M.auto_detect_and_restore_session()
          end, 500) -- Delay to let other plugins load
        end,
        desc = "Auto-detect and restore work session on startup"
      })
    end
  end
end

return M
