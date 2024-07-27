vim.env.LAZY_STDPATH = ".tests"
load(vim.fn.system("curl -s https://raw.githubusercontent.com/folke/lazy.nvim/main/bootstrap.lua"))()

-- Setup lazy.nvim
require("lazy.minit").busted({
  spec = {
    {
      dir = vim.uv.cwd(),
      opts = {},
    },
    {
      "nvim-treesitter/nvim-treesitter",
      build = function()
        require("nvim-treesitter.install").update({ with_sync = true })()
      end,
      config = function()
        require("nvim-treesitter.configs").setup({
          modules = {},
          auto_install = true,
          ignore_install = {},
          ensure_installed = { "go" },
          sync_install = true,
        })
      end,
    },
  },
})
