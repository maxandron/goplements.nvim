---@module 'luassert'

local goplements = require("goplements")

describe("set_virt_text", function()
  it("should not set text if the names array is empty", function()
    local namespace = vim.api.nvim_create_namespace("test")
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "package main" })

    goplements.set_virt_text(namespace, buf, 0, "prefix", {})

    local extmarks = vim.api.nvim_buf_get_extmarks(buf, namespace, 0, -1, {})
    assert.are.same({}, extmarks)
  end)

  it("concatenates prefix and names", function()
    local namespace = vim.api.nvim_create_namespace("test")
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "package main" })

    goplements.set_virt_text(namespace, buf, 0, "prefix ", { "name1", "name2" })

    local extmarks = vim.api.nvim_buf_get_extmarks(buf, namespace, 0, -1, { details = true })
    assert.are_same(1, #extmarks)
    assert.are.same("prefix name1, name2", extmarks[1][4].virt_text[1][1])
  end)
end)

describe("get_package_name", function()
  it("can find the package name", function()
    local package = goplements.get_package_name({
      "// not a package name",
      "",
      "// Also not a package",
      "a mistaken package name",
      "package bad name",
      "package main",
      "package notmain",
    })

    assert.are.same("main", package)
  end)
end)

describe("implementation_callback", function()
  local stub = require("luassert.stub")

  it("always publishes names", function()
    local called = false
    goplements.implementation_callback({}, {}, function(names)
      called = true
      assert.are.same({}, names)
    end)
    assert.is_true(called)
  end)

  it("retrieves the names from files", function()
    goplements.config.display_package = false

    local fn = stub.new(vim.fn, "readfile")
    fn.returns({ "package foo", "func main() {}" })

    goplements.implementation_callback({}, {
      {
        uri = "file://uri",
        range = { start = { line = 1, character = 5 }, ["end"] = { line = 1, character = 9 } },
      },
      {
        uri = "file://uri2",
        range = { start = { line = 0, character = 8 }, ["end"] = { line = 1, character = 11 } },
      },
    }, function(names)
      assert.are.same({ "main", "foo" }, names)
    end)

    assert.is_true(fn:called_with({ "/uri", n = 1 }))
    assert.is_true(fn:called_with({ "/uri2", n = 1 }))

    fn:revert()
  end)

  it("retrieves the package name from the file", function()
    goplements.config.display_package = true

    local fn = stub.new(vim.fn, "readfile")
    fn.returns({ "package foo", "func main() {}" })

    goplements.implementation_callback({}, {
      {
        uri = "file://uri",
        range = { start = { line = 1, character = 5 }, ["end"] = { line = 1, character = 9 } },
      },
    }, function(names)
      assert.are.same({ "foo.main" }, names)
    end)

    assert.is_true(fn:called_with({ "/uri", n = 1 }))

    fn:revert()
  end)

  it("doesn't read the same file twice", function()
    local fn = stub.new(vim.fn, "readfile")
    local data = { "package foo", "func main() {}" }
    fn.returns(data)

    local cache = {}
    goplements.implementation_callback(cache, {
      {
        uri = "file://uri",
        range = { start = { line = 1, character = 5 }, ["end"] = { line = 1, character = 9 } },
      },
      {
        uri = "file://uri",
        range = { start = { line = 1, character = 5 }, ["end"] = { line = 1, character = 9 } },
      },
    }, function(names)
      assert.are.same({ "foo.main", "foo.main" }, names)
    end)

    assert.is_true(fn:called(1))

    assert.are.same(cache["/uri"], data)

    fn:revert()
  end)
end)

describe("find_types", function()
  it("should find all structs and interfaces", function()
    local fdata = {
      "package main",
      "type MyStruct struct {",
      "  Field1 string",
      "}",
      "type MyStruct2 struct{   ",
      "  Field1 string",
      "}",
      "type My3struct struct {",
      "  Field1 string",
      "}",
      "type  MyInterface interface {",
      "  Method1()",
      "}",
      "type Myinterface interface {",
      "  Method1()",
      "}",
    }

    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, fdata)

    local assert_types = function(types)
      assert.are.same(#types, 5)
      assert.are.same(types[1], { line = 1, character = 5, type = "struct" })
      assert.are.same(types[2], { line = 4, character = 5, type = "struct" })
      assert.are.same(types[3], { line = 7, character = 5, type = "struct" })
      assert.are.same(types[4], { line = 10, character = 6, type = "interface" })
      assert.are.same(types[5], { line = 13, character = 5, type = "interface" })
    end

    local pattern_types = goplements.find_types_patterns(buf)
    assert_types(pattern_types)

    local parser = vim.treesitter.get_parser(buf, "go")
    local ts_types = goplements.find_types_ts(parser)
    assert_types(ts_types)

    vim.api.nvim_buf_delete(buf, { force = true })
  end)
end)
