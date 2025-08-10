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
      local restored = session.restore_session(new_dir)
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

return M
