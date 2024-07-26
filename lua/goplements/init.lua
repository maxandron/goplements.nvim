---@class goplements
local M = {}
M._enabled = true
M._namespace = 0

---@class goplements.opts
---@field prefix { interface: string, struct: string } The prefixes prepended to the type names
---@field display_package boolean Whether to display the package name along with the type name (i.e. builtins.error vs error)
---@field namespace_name string The namespace to use for the extmarks
---@field highlight string The highlight group to use
M.config = {
  prefix = {
    interface = "implemented by: ",
    struct = "implements: ",
  },
  display_package = false,
  namespace_name = "goplements",
  highlight = "Goplements",
}

---@alias goplements.Typedef { line: integer, character: integer, type: `interface` | `struct` }

--- Finds all structs and interfaces in the current buffer using Treesitter
--- @param parser vim.treesitter.LanguageTree
--- @return goplements.Typedef[]
M.find_types_ts = function(parser)
  local query = vim.treesitter.query.parse(
    "go",
    [[
        (type_spec
            name: (type_identifier) @interface
            type: (interface_type))
        (type_spec
            name: (type_identifier) @struct
            type: (struct_type))
    ]]
  )

  local root = parser:parse()[1]:root()

  local nodes = {} --- @type goplements.Typedef[]
  for id, node in query:iter_captures(root, 0) do
    local type = query.captures[id]
    local line, character = node:range()
    table.insert(nodes, { line = line, character = character, type = type })
  end

  return nodes
end

--- Find all structs and interfaces in the current buffer using lua pattern matching
--- @param bufnr integer The buffer number to parse
--- @return goplements.Typedef[]
M.find_types_patterns = function(bufnr)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local nodes = {} --- @type goplements.Typedef[]
  local interface_pattern = "^(type%s+)%w+%s+interface%s*{%s*$"
  local struct_pattern = "^(type%s+)%w+%s+struct%s*{%s*$"

  for i, line in ipairs(lines) do
    local type_prefix = string.match(line, interface_pattern)
    if type_prefix then
      table.insert(nodes, { line = i - 1, character = string.len(type_prefix), type = "interface" })
      goto continue
    end

    type_prefix = string.match(line, struct_pattern)
    if type_prefix then
      table.insert(nodes, { line = i - 1, character = string.len(type_prefix), type = "struct" })
      goto continue
    end
    ::continue::
  end
  return nodes
end

--- Find all structs and interfaces in the current buffer
--- @param bufnr integer The buffer number to parse
--- @return goplements.Typedef[]
M.find_types = function(bufnr)
  local ok, parser = pcall(vim.treesitter.get_parser, bufnr, "go")
  if ok then
    return M.find_types_ts(parser)
  end
  print("Treesitter parser not found for Go")
  return {}
end

--- Clear all extmarks in the current buffer
--- @param namespace integer
local function clear(namespace)
  vim.api.nvim_buf_clear_namespace(0, namespace, 0, -1)
end

local function set_colors()
  vim.api.nvim_set_hl(0, "Goplements", { default = true, link = "DiagnosticHint" })
end

--- Given the lines from a Go file - searches for the package name
--- @param fdata string[]
--- @return string the package name or an empty string if not found
M.get_package_name = function(fdata)
  for _, line in ipairs(fdata) do
    local match = string.match(line, "^package (%a+)$")
    if match then
      return match
    end
  end
  return ""
end

--- @alias goplements.LspImplementation { range: { start: { line: integer, character: integer }, ["end"]: { line: integer, character: integer } }, uri: string }
--- @param result goplements.LspImplementation[]
--- @param publish_names fun(names: string[])
M.implementation_callback = function(result, publish_names)
  --- @type string[]
  local names = {}
  if result then
    for _, impl in pairs(result) do
      local uri = impl.uri
      local impl_line = impl.range.start.line
      local impl_start = impl.range.start.character
      local impl_end = impl.range["end"].character

      -- Read the line of the implementation to get the name
      local file = vim.uri_to_fname(uri)
      local data = vim.fn.readfile(file)
      local package_name = ""
      if M.config.display_package then
        package_name = M.get_package_name(data)
        if package_name ~= "" then
          package_name = package_name .. "."
        end
      end
      local impl_text = data[impl_line + 1]
      local name = package_name .. impl_text:sub(impl_start + 1, impl_end)

      table.insert(names, name)
    end
  end
  publish_names(names)
end

--- Add virtual text to the struct/interface at the given line and character position
--- @param client vim.lsp.Client The LSP client
--- @param line integer The line number of the struct/interface
--- @param character integer The character position of the struct/interface name
--- @param callback fun(names: string[])
local function get_implementation_names(client, line, character, callback)
  client.request("textDocument/implementation", {
    textDocument = vim.lsp.util.make_text_document_params(),
    position = {
      line = line,
      character = character,
    },
  }, function(err, result)
    if err then
      -- This can happen if the Go file structure is ruined (e.g. the "package" is deleted)
      return
    end

    M.implementation_callback(result, callback)
  end)
end

--- Set the virtual text for the given line
--- @param namespace integer The namespace to use
--- @param bufnr integer The buffer number
--- @param line integer The line number
--- @param prefix string The prefix to display before the names
--- @param names string[] The names to display
M.set_virt_text = function(namespace, bufnr, line, prefix, names)
  if #names > 0 then
    local impl_text = prefix .. table.concat(names, ", ")
    vim.api.nvim_buf_set_extmark(bufnr, namespace, line, 0, {
      virt_text = { { impl_text, M.config.highlight } },
      virt_text_pos = "eol",
    })
  end
end

--- The callback for the LspNotify autocmd
--- @param namespace integer
--- @param bufnr integer
--- @param client_id integer
M.callback = function(namespace, bufnr, client_id)
  if not M._enabled then
    return
  end

  local client = vim.lsp.get_client_by_id(client_id)
  assert(client, "expected client to not be nil")
  if client.name ~= "gopls" then
    return
  end

  clear(namespace)
  local nodes = M.find_types(bufnr)
  for _, node in ipairs(nodes) do
    local prefix = M.config.prefix[node.type]
    assert(prefix, "prefix not found for node type .. " .. node.type)

    get_implementation_names(client, node.line, node.character + 1, function(names)
      M.set_virt_text(namespace, bufnr, node.line, prefix, names)
    end)
  end
end

--- @param namespace integer
local function register_autocmds(namespace)
  vim.api.nvim_create_autocmd({ "LspNotify" }, {
    pattern = { "*.go" },
    callback = function(args)
      M.callback(namespace, args.buf, args.data.client_id)
    end,
  })

  vim.api.nvim_create_autocmd({ "InsertEnter" }, {
    pattern = { "*.go" },
    callback = function()
      M._enabled = false
    end,
  })

  vim.api.nvim_create_autocmd({ "InsertLeave" }, {
    pattern = { "*.go" },
    callback = function()
      M.enable()
    end,
  })
end

M.disable = function()
  M._enabled = false
  clear(M._namespace)
end

M.enable = function()
  M._enabled = true

  local client = vim.lsp.get_clients({ name = "gopls" })[1]
  if not client then
    -- If gopls is not attached we assume the current buffer is not a Go file
    return
  end

  local bufnr = vim.api.nvim_get_current_buf()

  M.callback(M._namespace, bufnr, client.id)
end

M.toggle = function()
  if M._enabled then
    M.disable()
  else
    M.enable()
  end
end

local function register_user_commands()
  vim.api.nvim_create_user_command("GoplementsEnable", M.enable, { desc = "Enable Goplements" })
  vim.api.nvim_create_user_command("GoplementsDisable", M.disable, { desc = "Disable Goplements" })
  vim.api.nvim_create_user_command("GoplementsToggle", M.toggle, { desc = "Toggle Goplements" })
end

---@param opts? goplements.opts
function M.setup(opts)
  M.config = vim.tbl_deep_extend("keep", opts or {}, M.config)
  set_colors()
  register_user_commands()

  M._namespace = vim.api.nvim_create_namespace(M.config.namespace_name)
  register_autocmds(M._namespace)
end

return M
