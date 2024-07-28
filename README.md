# Goplements.nvim

Goplements is a small Neovim plugin for Go that visualizes struct and interface implementations.

![image](https://github.com/user-attachments/assets/e2a2e194-e5f6-492b-8657-1906d3d7e034)

## ✨ Features

- Displays the implementors of an interface next to the definition.
- Dispays the interfaces implemented by a struct next to the definition.

## ⚡️ Requirements

- **Neovim** >= 0.9.4
- LSP with the `gopls` server
  - for the `textDocument/implementations` request
- (optional) [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter/) with the `go` parser installed.
  - for an unnoticeably faster experience

## 📦 Installation

Install the plugin with your package manager.

### Lazy.nvim

```lua
{
  "maxandron/goplements.nvim",
  ft = "go",
  opts = {
    -- your configuration comes here
    -- or leave it empty to use the default settings
    -- refer to the configuration section below
  },
}
```

## ⚙️ Configuration

Default Options

```lua
local defaults = {
  -- The prefixes prepended to the type names
  prefix = {
    interface = "implemented by: ",
    struct = "implements: ",
  },
  -- Whether to display the package name along with the type name (i.e., builtins.error vs error)
  display_package = false,
  -- The namespace to use for the extmarks (no real reason to change this except for testing)
  namespace_name = "goplements",
  -- The highlight group to use (if you want to change the default colors)
  -- The default links to DiagnosticHint
  highlight = "Goplements",
}
```

## 🚀 Usage and API

The plugin is automatically enabled for Go files using an autocmd.

Three commands are provided for disabling, enabling, and toggling the plugin:

- `:GoplementEnable`
- `:GoplementDisable`
- `:GoplementToggle`

The same commands are also available as lua functions:

- `require("goplements").enable()`
- `require("goplements").disable()`
- `require("goplements").toggle()`

