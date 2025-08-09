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

      -- Initialize modules by passing config (no init() function needed)
      workspace.setup(M.config)
      session.setup(M.config)
      vim.api.nvim_create_user_command("WorkSessionDeactivateVenv", function()
        if M.config.venv_selector then
          M.config.venv_selector.deactivate()
        end
      end, {})

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

return M
