local M = {}

M.default_config = {
  session_dir = ".work_session",
  
  -- Auto-save configuration
  auto_save = {
    enabled = true,           -- Enable auto-save functionality
    on_exit = true,          -- Save session when exiting Neovim
    on_focus_lost = false,   -- Save session when Neovim loses focus
    periodic = {             -- Periodic auto-save settings
      enabled = false,       -- Enable periodic auto-save
      interval = 60000,      -- Auto-save interval in milliseconds (60 seconds)
    },
  },
  
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
  auto_detect = {
    enabled = true,           -- Enable auto-detection of session data
    on_startup = true,        -- Auto-restore session on Neovim startup
    on_dir_change = true,     -- Auto-restore session when changing directories
  },
  ui = {
    -- Window dimensions
    width = 60,
    height = 25,
    border = "rounded", -- "rounded", "single", "double", "shadow", "none"
    
    -- Window positioning
    position = "center", -- "center", "top", "bottom"
    row_offset = 0, -- Additional row offset from position
    col_offset = 0, -- Additional column offset from position
    
    -- Colors and styling
    highlight = {
      normal = "Normal", -- Background highlight group
      border = "FloatBorder", -- Border highlight group
      title = "FloatTitle", -- Title highlight group
      selected = "CursorLine", -- Selected item highlight
      separator = "Comment", -- Separator line highlight
    },
    
    -- Visual elements
    show_venv_status = true, -- Show virtual environment in title
    show_separator = true, -- Show separator between sections
    separator_char = "─", -- Character used for separator
    confirm_workspace_open = true, -- Show confirmation before opening workspace
    
    -- Icons (optional, fallback to text if not available)
    icons = {
      workspace = "󰉋 ", -- Workspace icon
      add = "+ ", -- Add action icon
      remove = "- ", -- Remove action icon
      help = "? ", -- Help icon
    },
    
    -- Keymaps
    keymaps = {
      select = "<Space>",
      quit = "<Esc>",
      up = "<Up>",
      down = "<Down>",
      help = "?",
      add_dir = "a",
      remove_dir = "d",
      -- Auto-save toggle keymaps
      toggle_auto_save_exit = "e",
      toggle_auto_save_focus = "f", 
      toggle_auto_save_periodic = "p",
      save_session_now = "s",
      -- Alternative navigation keys
      nav_up = "k",
      nav_down = "j",
      alt_select = "<CR>",
      alt_quit = "q"
    }
  }
}

return M
