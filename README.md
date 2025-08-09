# 🚀 Work Session for Neovim

![Work Session Plugin Demo](https://via.placeholder.com/800x400.png?text=Work+Session+Demo)  
*Interactive workspace and session management for Neovim*

**Work Session** is a powerful Neovim plugin that enhances your project workflow by integrating workspace management with session persistence. It provides a keyboard-driven interface to manage your workspaces, sessions, and Python virtual environments.

## ✨ Features

- **Unified Workspace Management**: List, open, add, and remove workspaces using `natecraddock/workspaces.nvim`
- **Session Persistence**: Automatically saves and restores open buffers
- **Virtual Environment Support**: Integrates with `venv-selector.nvim` for Python workflows
- **Intuitive Popup UI**: Keyboard-driven interface with clear navigation
- **Session Isolation**: Creates `.work_session` directories to store session data
- **Customizable**: Configure UI dimensions, borders, and key mappings

## 📦 Installation

### Prerequisites
- Neovim 0.8+
- [workspaces.nvim](https://github.com/natecraddock/workspaces.nvim)
- [venv-selector.nvim](https://github.com/linux-cultist/venv-selector.nvim) (optional for Python environments)

### Using [Lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
return {
  "SyHoMadara/work-session.nvim",
  dependencies = {
    "natecraddock/workspaces.nvim",
    "linux-cultist/venv-selector.nvim"  -- optional but recommended
  },
  config = function()
    require("work-session").setup({
      -- Custom configuration (optional)
      ui = {
        width = 70,
        height = 15,
        border = "rounded"
      }
    })
    
    -- Set a keymap to open the session manager
    vim.keymap.set("n", "<leader>ws", "<cmd>WorkSession<CR>", {desc = "Open Work Session"})
  end
}
```

### Using [Packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  "SyHoMadara/work-session.nvim",
  requires = {
    "natecraddock/workspaces.nvim",
    "linux-cultist/venv-selector.nvim"
  },
  config = function()
    require("work_session").setup()
  end
}
```

## ⚙️ Configuration

Default configuration (you can override any of these options):

```lua
{
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
      return require("venv-selector").get_current_venv() 
    end,
    set_current = function(venv) 
      require("venv-selector").set_venv(venv) 
    end
  },
  ui = {
    width = 60,        -- Popup width
    height = 20,       -- Popup height
    border = "rounded",-- Border style: "single", "double", "rounded", "solid", "shadow"
    keymaps = {
      select = "<Space>",  -- Select item
      quit = "<Esc>",      -- Close window
      up = "<Up>",         -- Navigate up
      down = "<Down>",     -- Navigate down
      add_dir = "a",       -- Add current directory
      remove_dir = "d"     -- Remove current directory
    }
  }
}
```

## 🎮 Usage

1. Open the work session manager:
   ```
   :WorkSession
   ```
   or use your mapped key (e.g., `<leader>ws`)

2. The interactive menu will show:
   - All available workspaces (select with numbers or navigation keys)
   - Action options: Add/Remove current directory

3. Navigation:
   - Use arrow keys or j/k to navigate
   - Press <Space> to select an item
   - Use number keys to directly select a workspace
   - Press 'a' to add current directory
   - Press 'd' to remove current directory
   - Press <Esc> to close the window

4. When opening a workspace:
   - All previously open buffers will be restored
   - Python virtual environment will be activated if previously set

## 🧩 How It Works

The plugin creates a `.work_session` directory in your project root with:
- `buffers.txt`: List of open buffers to restore
- `venv.txt`: Current Python virtual environment path (if applicable)

Session data is automatically saved when you open the work session manager.

## 🚧 Limitations

- Requires workspaces.nvim to be installed and configured
- Currently only supports Python virtual environments
- Session restoration doesn't preserve window layouts (yet!)

## Python Virtual Environment Support

This plugin optionally integrates with [venv-selector.nvim](https://github.com/linux-cultist/venv-selector.nvim) for Python virtual environment management. If installed, it will:

- Save the current virtual environment when saving a session
- Restore the virtual environment when loading a session

To disable this functionality, set `venv_selector = nil` in your config:

```lua
require("work_session").setup({
  venv_selector = nil  -- Disable venv integration
})
```

## 💻 Development

Contributions are welcome! The plugin is structured as a single Lua file:

```
lua/
└── work_session/
    └── init.lua
```

To test during development:
```bash
# Create a symlink to your Neovim plugins directory
ln -s /path/to/work-session.nvim ~/.local/share/nvim/site/pack/plugins/start/work-session.nvim
```

## 📜 License

MIT License © 2023 SyHoMadara
```

This README provides all the essential information users need to install, configure, and use your plugin. It includes:

1. Clear feature highlights
2. Installation instructions for popular package managers
3. Configuration options with default values
4. Usage instructions with keyboard navigation details
5. Technical details about how sessions are stored
6. Development and contribution information
7. License information
