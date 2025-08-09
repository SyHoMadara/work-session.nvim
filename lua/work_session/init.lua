local M = {}
local config = require("work_session.config")
local ui = require("work_session.ui")

function M.setup(user_config)
  M.config = vim.tbl_deep_extend("force", config.default_config, user_config or {})
end

function M.open_menu()
  ui.create_main_menu(M.config)
end

return M
