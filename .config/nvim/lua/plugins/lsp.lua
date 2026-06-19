return {
  {
    "folke/lazydev.nvim",
    ft = "lua",
    opts = {
      library = {
        { path = "${3rd}/luv/library", words = { "vim%.uv" } },
      },
    },
  },
  {
    "mason-org/mason.nvim",
    opts = {},
  },
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    dependencies = { "mason-org/mason.nvim" },
    opts = {
      ensure_installed = {
        "lua-language-server",
        "clangd",
        "basedpyright",
        "black",
        "stylua",
        "clang-format",
        "codelldb",
      },
    },
  },
  {
    "j-hui/fidget.nvim",
    opts = {},
  },
}
