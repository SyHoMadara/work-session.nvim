# 🚀 Work Session for Neovim

![Work Session Plugin Demo](https://via.placeholder.com/800x400.png?text=Work+Session+Demo)  
*Interactive workspace and session management for Neovim*

**Work Session** is a powerful Neovim plugin that enhances your project workflow by integrating workspace management with session persistence. It provides a keyboard-driven interface to manage your workspaces, sessions, and Python virtual environments.

## ✨ Features

- **🎯 Unified Workspace Management**: Seamless integration with `natecraddock/workspaces.nvim`
- **💾 Session Persistence**: Automatic save/restore of open buffers and window state
- **🐍 Python Virtual Environment Support**: Integrates with `venv-selector.nvim`
- **🎨 Fully Customizable UI**: Configure dimensions, colors, icons, and positioning
- **⌨️ Intuitive Controls**: Keyboard-driven interface with vim-like navigation
- **❓ Built-in Help System**: Comprehensive help accessible with `?` key
- **🚀 Quick Workspace Access**: Direct workspace opening with number keys (1-9)
- **🎛️ Flexible Configuration**: Disable confirmations, customize keymaps, and more
- **📁 Session Isolation**: Creates `.work_session` directories for clean organization
- **🔧 Smart Defaults**: Works out of the box with sensible configuration

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

### Basic Setup

```lua
require("work_session").setup({
  -- Custom configuration (all options are optional)
})
```

### Default Configuration

You can override any of these options in your setup:

```lua
{
  session_dir = ".work_session",  -- Directory to store session data
  
  -- Workspace integration
  workspaces = {
    plugin = "natecraddock/workspaces.nvim",
    open = function(workspace) 
      require("workspaces").open(workspace) 
    end
  },
  
  -- Virtual environment integration
  venv_selector = {
    plugin = "linux-cultist/venv-selector.nvim",
    get_current = function() 
      return require("venv-selector").venv() or ""
    end,
    set_current = function(venv) 
      require("venv-selector").activate_from_path(venv) 
    end,
    deactivate = function()
      require("venv-selector").deactivate()
    end
  },
  
  -- UI Configuration
  ui = {
    -- Window dimensions
    width = 60,
    height = 25,
    border = "rounded", -- "rounded", "single", "double", "shadow", "none"
    
    -- Window positioning
    position = "center", -- "center", "top", "bottom"
    row_offset = 0,      -- Additional row offset from position
    col_offset = 0,      -- Additional column offset from position
    
    -- Colors and styling
    highlight = {
      normal = "Normal",      -- Background highlight group
      border = "FloatBorder", -- Border highlight group
      title = "FloatTitle",   -- Title highlight group
      selected = "CursorLine", -- Selected item highlight
      separator = "Comment",   -- Separator line highlight
    },
    
    -- Visual elements
    show_venv_status = true,            -- Show virtual environment in title
    show_separator = true,              -- Show separator between sections
    separator_char = "─",               -- Character used for separator
    confirm_workspace_open = true,      -- Show confirmation before opening workspace
    
    -- Icons (optional, fallback to text if not available)
    icons = {
      workspace = "󰉋 ", -- Workspace icon (requires nerd fonts)
      add = "+ ",       -- Add action icon
      remove = "- ",    -- Remove action icon
      help = "? ",      -- Help icon
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
      -- Alternative navigation keys
      nav_up = "k",        -- Vim-style up
      nav_down = "j",      -- Vim-style down
      alt_select = "<CR>", -- Alternative select key
      alt_quit = "q"       -- Alternative quit key
    }
  }
}
```

### Configuration Examples

#### Minimal Configuration
```lua
require("work_session").setup({
  ui = {
    width = 50,
    height = 20
  }
})
```

#### Custom Styling
```lua
require("work_session").setup({
  ui = {
    border = "double",
    position = "top",
    separator_char = "═",
    highlight = {
      normal = "NormalFloat",
      border = "TelescopeBorder",
      selected = "Visual"
    },
    icons = {
      workspace = "📁 ",
      add = "➕ ",
      remove = "❌ "
    }
  }
})
```

#### Disable Confirmations
```lua
require("work_session").setup({
  ui = {
    confirm_workspace_open = false, -- Open workspaces directly
    show_venv_status = false,       -- Hide venv in title
    show_separator = false          -- Remove separator line
  }
})
```

#### Custom Keymaps
```lua
require("work_session").setup({
  ui = {
    keymaps = {
      select = "<Tab>",
      quit = "q",
      up = "h",
      down = "l",
      help = "H",
      add_dir = "+",
      remove_dir = "-"
    }
  }
})
```

## 🎮 Usage

### Opening Work Session Manager

1. **Command**: `:WorkSession`
2. **Keymap**: Set up a convenient mapping:
   ```lua
   vim.keymap.set("n", "<leader>ws", "<cmd>WorkSession<CR>", {desc = "Open Work Session"})
   ```

### Interface Overview

The interactive menu displays:
- **Header**: Shows "Work Session Manager" with optional virtual environment status
- **Workspaces**: Numbered list of available workspaces
- **Separator**: Visual divider between sections (configurable)
- **Actions**: Add/Remove current directory options
- **Footer**: Shows available keybindings and help

### Navigation & Controls

#### Basic Navigation
- **Arrow Keys / j,k**: Navigate up/down through items
- **Space / Enter**: Select highlighted item
- **Esc / q**: Close the window
- **? (Question Mark)**: Show comprehensive help window

#### Quick Actions
- **Number Keys (1-9)**: Directly open workspace by number
- **a**: Add current directory to workspaces
- **d**: Remove current directory from workspaces

#### Workspace Opening
When selecting a workspace:
- **With Confirmation** (default): Shows confirmation dialog
- **Direct Opening**: Set `confirm_workspace_open = false` for instant opening
- **Session Restoration**: Automatically restores previously open buffers
- **Virtual Environment**: Activates the previously used Python environment

### Help System

Press **?** in the main menu to access the built-in help system, which includes:
- Complete list of keybindings
- Navigation instructions
- Workspace management details
- Usage tips and shortcuts

### Session Management

Work Session automatically handles:
1. **Saving**: When you open the session manager, current state is saved
2. **Restoring**: When opening a workspace, previous session is restored
3. **Virtual Environments**: Python venv state is preserved across sessions

### Example Workflow

```
1. Open project directory: cd ~/projects/my-app
2. Open session manager: <leader>ws
3. Add to workspaces: press 'a'
4. Work on project...
5. Switch to another project: <leader>ws → select workspace
6. Return later: <leader>ws → workspace is restored exactly as left
```

## 🧩 How It Works

The plugin creates a `.work_session` directory in your project root with:
- `buffers.txt`: List of open buffers to restore
- `venv.txt`: Current Python virtual environment path (if applicable)

Session data is automatically saved when you open the work session manager.

## � Troubleshooting

### Common Issues

#### Plugin Not Loading
```lua
-- Ensure dependencies are properly loaded
require("workspaces").setup() -- Must be called before work-session
require("work_session").setup()
```

#### Keymaps Not Working
- Check for keymap conflicts with other plugins
- Verify configuration syntax:
```lua
ui = {
  keymaps = {
    select = "<Space>", -- Correct
    -- select = "Space", -- Incorrect (missing angle brackets)
  }
}
```

#### UI Positioning Issues
```lua
-- For small terminals, adjust dimensions
ui = {
  width = math.min(50, vim.o.columns - 10),
  height = math.min(20, vim.o.lines - 10)
}
```

#### Icons Not Displaying
- Install a [Nerd Font](https://www.nerdfonts.com/)
- Or disable icons:
```lua
ui = {
  icons = {
    workspace = "",
    add = "",
    remove = "",
    help = ""
  }
}
```

### Debug Mode
Enable verbose logging to troubleshoot issues:
```lua
vim.g.work_session_debug = true
```

### Reset Configuration
To reset to defaults, remove custom config:
```lua
require("work_session").setup() -- No parameters = all defaults
```

## �🚧 Limitations

- **Dependency Requirement**: Requires `workspaces.nvim` to be installed and configured
- **Python Environment Support**: Virtual environment integration limited to `venv-selector.nvim`
- **Window Layout**: Session restoration doesn't preserve complex window layouts (planned feature)
- **Terminal Sessions**: Terminal buffers and their state are not preserved
- **Cross-Platform**: Path handling optimized for Unix-like systems (Windows support planned)

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
