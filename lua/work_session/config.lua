local M = {}

M.default_config = {
  session_dir = ".work_session",  -- Directory to store session data
  workspaces = {
    plugin = "natecraddock/workspaces.nvim",
    open = function(workspace) 
      require("workspaces").open(workspace) 
    end
  },
  venv_selector = {
    plugin = "linux-cultist/venv-selector.nvim",
    get_current = function()
      local ok, venv = pcall(function()
        return require("venv-selector").get_active_venv() or ""
      end)
      return ok and venv or ""
    end,
    set_current = function(venv)
      if venv and venv ~= "" then
        pcall(function()
          require("venv-selector").activate_venv(venv)
        end)
      end
    end
  },
  ui = {
    width = 60,
    height = 20,
    border = "rounded",  -- or "single", "double", "shadow"
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
