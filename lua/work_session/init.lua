local M = {}

-- Properly initialize modules
local config = require("work_session.config")
local ui = require("work_session.ui")
local workspace = require("work_session.workspace")
local session = require("work_session.session")

function M.setup(user_config)
  -- Merge user config with defaults
  M.config = vim.tbl_deep_extend("force", {}, config.default_config, user_config or {})
  
  -- Initialize submodules
  workspace.init(M.config)
  session.init(M.config)
  
  return M
end

function M.open_menu()
  -- Add safety checks
  if not package.loaded["workspaces"] then
    vim.notify("workspaces.nvim not loaded", vim.log.levels.ERROR)
    return
  end
  
  ui.create_main_menu(M.config)
end

return M
