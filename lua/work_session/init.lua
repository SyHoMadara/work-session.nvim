local M = {}

function M.setup(user_config)
  local ok, err = pcall(function()
     -- Load modules only when needed
      local config = require("work_session.config")
      local ui = require("work_session.ui")
      local workspace = require("work_session.workspace")
      local session = require("work_session.session")

      -- Merge configurations
      M.config = vim.tbl_deep_extend("force", {}, config.default_config, user_config or {})

      -- Migration: handle old 'interval' config format
      if M.config.auto_save and M.config.auto_save.interval then
        -- Convert old interval format to new periodic format
        if not M.config.auto_save.periodic then
          M.config.auto_save.periodic = {}
        end
        if M.config.auto_save.interval > 0 then
          M.config.auto_save.periodic.enabled = true
          M.config.auto_save.periodic.interval = M.config.auto_save.interval * 1000 -- Convert seconds to milliseconds
        else
          M.config.auto_save.periodic.enabled = false
        end
        -- Remove the old interval field
        M.config.auto_save.interval = nil
      end

      -- Initialize modules by passing config (no init() function needed)
      workspace.setup(M.config)
      session.setup(M.config)
      
      -- Setup auto-detection if enabled
      if M.config.auto_detect and M.config.auto_detect.enabled then
        workspace.setup_auto_detection()
      end
      
      -- Create user commands
      vim.api.nvim_create_user_command("WorkSession", function()
        M.open_menu()
      end, { desc = "Open Work Session Manager" })
      
      vim.api.nvim_create_user_command("WorkSessionSave", function()
        M.save_session()
      end, { desc = "Save current work session" })
      
      vim.api.nvim_create_user_command("WorkSessionRestore", function(opts)
        local path = opts.args ~= "" and opts.args or vim.fn.getcwd()
        M.restore_session(path)
      end, { 
        nargs = "?", 
        complete = "dir",
        desc = "Restore work session from path" 
      })
      
      vim.api.nvim_create_user_command("WorkSessionInfo", function()
        M.show_session_info()
      end, { desc = "Show current session information" })
      
      vim.api.nvim_create_user_command("WorkSessionDeactivateVenv", function()
        if M.config.venv_selector then
          M.config.venv_selector.deactivate()
        end
      end, { desc = "Deactivate current virtual environment" })
      
      vim.api.nvim_create_user_command("WorkSessionAutoDetect", function(opts)
        local path = opts.args ~= "" and opts.args or vim.fn.getcwd()
        local detected = workspace.auto_detect_and_restore_session(path)
        if not detected then
          vim.notify("No session data found in: " .. path, vim.log.levels.INFO)
        end
      end, { 
        nargs = "?", 
        complete = "dir",
        desc = "Auto-detect and restore session from directory" 
      })

      return M
  end)
  
  if not ok then
    vim.notify("Failed to setup work-session: " .. tostring(err), vim.log.levels.ERROR)
  end
end

function M.open_menu()
  -- Ensure we have a valid config
  if not M.config then
    vim.notify("Work Session not configured. Please call setup() first.", vim.log.levels.ERROR)
    return
  end

  -- Check for workspaces dependency
  if not package.loaded["workspaces"] then
    vim.notify("workspaces.nvim is required but not loaded", vim.log.levels.ERROR)
    return
  end

  -- Safely open menu
  local ok, err = pcall(require("work_session.ui").create_main_menu, M.config)
  if not ok then
    vim.notify("Failed to open menu: " .. tostring(err), vim.log.levels.ERROR)
  end
end

function M.save_session(path)
  -- Ensure we have a valid config
  if not M.config then
    vim.notify("Work Session not configured. Please call setup() first.", vim.log.levels.ERROR)
    return false
  end

  local workspace_path = path or vim.fn.getcwd()
  local session = require("work_session.session")
  
  local ok, err = pcall(session.save_session, workspace_path)
  if ok then
    vim.notify("Session saved successfully", vim.log.levels.INFO)
    return true
  else
    vim.notify("Failed to save session: " .. tostring(err), vim.log.levels.ERROR)
    return false
  end
end

function M.restore_session(path)
  -- Ensure we have a valid config
  if not M.config then
    vim.notify("Work Session not configured. Please call setup() first.", vim.log.levels.ERROR)
    return false
  end

  local workspace_path = path or vim.fn.getcwd()
  local session = require("work_session.session")
  
  local ok, err = pcall(session.restore_session, workspace_path)
  if ok then
    return true
  else
    vim.notify("Failed to restore session: " .. tostring(err), vim.log.levels.ERROR)
    return false
  end
end

function M.show_session_info()
  -- Ensure we have a valid config
  if not M.config then
    vim.notify("Work Session not configured. Please call setup() first.", vim.log.levels.ERROR)
    return
  end

  local current_dir = vim.fn.getcwd()
  local session = require("work_session.session")
  local info = session.get_session_info(current_dir)
  
  if not info.exists then
    vim.notify("No session found for current directory: " .. current_dir, vim.log.levels.INFO)
    return
  end
  
  local lines = {
    "Work Session Information",
    string.rep("=", 40),
    "",
    "Directory: " .. current_dir,
    "Buffers: " .. info.buffer_count,
    "Virtual Environment: " .. (info.has_venv and "Yes" or "No"),
  }
  
  if info.saved_at then
    table.insert(lines, "Last Saved: " .. os.date("%Y-%m-%d %H:%M:%S", info.saved_at))
  end
  
  -- Show in a popup
  local ui = require("work_session.ui")
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(buf, "modifiable", false)
  
  local width = 50
  local height = #lines + 2
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    col = math.floor((vim.o.columns - width) / 2),
    row = math.floor((vim.o.lines - height) / 2),
    style = "minimal",
    border = "rounded",
    title = "Session Info",
    title_pos = "center"
  })
  
  vim.keymap.set("n", "<Esc>", function()
    vim.api.nvim_win_close(win, true)
  end, { buffer = buf, silent = true })
  
  vim.keymap.set("n", "q", function()
    vim.api.nvim_win_close(win, true)
  end, { buffer = buf, silent = true })
end

return M
