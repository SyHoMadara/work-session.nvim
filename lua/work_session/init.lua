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

      return M
  end)
  
  if not ok then
    vim.notify("Failed to setup work-session: " .. tostring(err), vim.log.levels.ERROR)
  end
end

function M.open_menu()
  if not package.loaded["workspaces"] then
    vim.notify("workspaces.nvim is required but not loaded", vim.log.levels.ERROR)
    return
  end
  require("work_session.ui").create_main_menu(M.config)
end

return M
