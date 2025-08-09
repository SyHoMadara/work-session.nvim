local M = {}

M.default_config = {
  session_dir = ".work_session",
  workspaces = {
    plugin = "natecraddock/workspaces.nvim",
    open = function(workspace)
      if package.loaded["workspaces"] then
        return require("workspaces").open(workspace)
      end
    end
  },
  venv_selector = {
    plugin = "linux-cultist/venv-selector.nvim",
    get_current = function()
      if package.loaded["venv-selector"] then
        return require("venv-selector").venv() or ""
      end
      return ""
    end,
    set_current = function(venv)
      if package.loaded["venv-selector"] and venv and venv ~= "" then
        require("venv-selector").activate_from_path(venv)
      end
    end,
    deactivate = function()
      if package.loaded["venv-selector"] then
        require("venv-selector").deactivate()
      end
    end
  },
  ui = {
    width = 60,
    height = 20,
    border = "rounded",
    keymaps = {
      select = "<Space>",
      quit = "<Esc>",
      up = "<Up>",
      down = "<Down>",
      number_select = "<number>",
      add_dir = "a",
      remove_dir = "d"
    }
  }
}

return M
