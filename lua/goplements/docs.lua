local Docs = require("lazy.docs")

local M = {}

function M.update()
  local config = Docs.extract("lua/goplmenets/config.lua", "\n(--@class wk%.Opts.-\n})")
  config = config:gsub("%s*debug = false.\n", "\n")
  Docs.save({
    config = config,
    colors = Docs.colors({
      modname = "goplmenets.colors",
      path = "lua/goplmenets/colors.lua",
      name = "WhichKey",
    }),
  })
end

M.update()
print("Updated docs")

return M
