---@diagnostic disable: deprecated
local start = vim.health.start or vim.health.report_start
local ok = vim.health.ok or vim.health.report_ok
local warn = vim.health.warn or vim.health.report_warn
-- local error = vim.health.error or vim.health.report_error
-- local info = vim.health.info or vim.health.report_info
---@diagnostic enable: deprecated

local M = {}

function M.check()
  start("Requirements")
  M.is_plugin_available("nvim-treesitter")
  M.treesitter_parser_installed("go")
end

function M.is_plugin_available(plugin)
  local is_plugin_available = pcall(require, plugin)
  if is_plugin_available then
    ok(plugin .. " is available")
  else
    warn(plugin .. " is not available")
  end
end

function M.treesitter_parser_installed(lang)
  local is_installed = require("nvim-treesitter.parsers").has_parser(lang)
  if is_installed then
    ok("Treesitter parser for " .. lang .. " is installed")
  else
    warn("Treesitter parser for " .. lang .. " is not installed")
  end
end

return M
