return {
  "NeogitOrg/neogit",
  dependencies = {
    "barrettruth/diffs.nvim",
    "nvim-lua/plenary.nvim",
    "nvim-tree/nvim-web-devicons",
    "folke/snacks.nvim",
  },
  cmd = { "Neogit" },
  keys = {
    { "<leader>gn", "<cmd>Neogit kind=replace<cr>", desc = "[G]it [N]eogit" },
  },
  opts = {},
}
