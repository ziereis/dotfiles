-- https://github.com/mikavilpas/yazi.nvim
return {
  "mikavilpas/yazi.nvim",
  version = "*",
  lazy = false,
  dependencies = {
    { "nvim-lua/plenary.nvim", lazy = true },
  },
  keys = {
    { "\\", "<cmd>Yazi<CR>", desc = "Yazi reveal", silent = true },
  },
  init = function()
    vim.g.loaded_netrwPlugin = 1
  end,
  opts = {
    open_for_directories = true,
  },
}
