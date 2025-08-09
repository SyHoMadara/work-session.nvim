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
  local config = require("work_session.config").default_config
  config.workspaces.open(name)
  
  -- Restore session after opening
  vim.schedule(function()
    local session = require("work_session.session")
    session.restore_session(vim.fn.getcwd())
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

return M
