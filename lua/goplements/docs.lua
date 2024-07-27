local Docs = require("lazy.docs")

local M = {}

function M.update()
  local config = Docs.extract("lua/goplmenets/init.lua", "\n(--@class wk%.Opts.-\n})")
  Docs.save({
    config = config,
    colors = Docs.colors({
      modname = "goplmenets.colors",
      path = "lua/goplmenets/colors.lua",
      name = "Goplements",
    }),
  })
end

M.update()
print("Updated docs")

return M
