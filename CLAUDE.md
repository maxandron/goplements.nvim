# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Goplements.nvim is a Neovim plugin that visualizes Go struct and interface implementations by adding virtual text annotations next to type definitions. The plugin uses LSP's `textDocument/implementation` request with the `gopls` server to discover implementations and displays them as inline hints.

## Development Commands

### Build and Quality Assurance
- `make ci` - Runs complete CI pipeline (format, lint, test)
- `make fmt` - Format code using stylua with project config
- `make lint` - Lint Lua code using selene
- `make test` - Run test suite using nvim with busted framework

### Individual Commands
- `stylua lua/ --config-path=stylua.toml` - Format Lua code
- `selene lua/` - Lint Lua files
- `nvim -l tests/minit.lua tests` - Run tests directly

## Code Architecture

### Core Components

**Main Module (`lua/goplements/init.lua`)**
- `M.find_types()` - Discovers struct/interface definitions using either TreeSitter or pattern matching
- `M.get_implementation_names()` - Queries LSP for implementations using `textDocument/implementation`
- `M.implementation_callback()` - Processes LSP results and extracts type names
- `M.set_virt_text()` - Creates extmarks with virtual text annotations
- `M.annotate_structs_interfaces()` - Main orchestration function called by autocmds

**Health Check (`lua/goplements/health.lua`)**
- Validates nvim-treesitter availability and Go parser installation
- Run with `:checkhealth goplements`

### Plugin Architecture

The plugin operates through an event-driven system:
1. Autocmds trigger on `TextChanged`, `InsertLeave`, and `LspAttach` for `*.go` files
2. TreeSitter queries or regex patterns identify struct/interface definitions
3. LSP requests fetch implementation details asynchronously
4. Virtual text is rendered using Neovim's extmark API

### Dual Type Discovery System

The plugin implements fallback type discovery:
- **Primary**: TreeSitter with Go parser for precise AST-based detection
- **Fallback**: Lua pattern matching when TreeSitter unavailable
- Both methods return identical data structure: `{line, character, type}`

### File Caching Strategy

The plugin implements intelligent file caching in `implementation_callback()`:
- Checks if files are loaded in Neovim buffers first (fastest)
- Falls back to filesystem reads with caching to avoid duplicate I/O
- Extracts package names when `display_package` option is enabled

## Testing Framework

Tests use busted framework through lazy.nvim's minit system:
- Test runner: `tests/minit.lua` bootstraps lazy.nvim with required dependencies
- Specs in: `tests/goplements/init_spec.lua`
- Tests cover core functions: `set_virt_text`, `get_package_name`, `implementation_callback`, `find_types`
- TreeSitter dependency automatically installed during test setup

## Configuration

Code style enforced by:
- **stylua.toml**: 2-space indentation, 120 character width, sorted requires
- **selene.toml**: Lua 5.1 linting with vim globals
- **vim.toml**: Test framework globals (describe, it, before_each, assert)