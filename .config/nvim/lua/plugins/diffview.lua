return {
  "sindrets/diffview.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  cmd = { "DiffviewOpen", "DiffviewFileHistory" },
  keys = {
    { "<leader>gd", "<cmd>DiffviewOpen<cr>", desc = "[G]it [D]iffview" },
    { "<leader>gq", "<cmd>DiffviewClose<cr>", desc = "[G]it diffview [Q]uit" },
    { "<leader>gh", "<cmd>DiffviewFileHistory %<cr>", desc = "[G]it file [H]istory" },
    { "<leader>gH", "<cmd>DiffviewFileHistory<cr>", desc = "[G]it repo [H]istory" },
  },
  opts = {
    enhanced_diff_hl = true,
    keymaps = {
      view = { { "n", "R", "<cmd>DiffviewRefresh<cr>", { desc = "Refresh" } } },
      file_panel = { { "n", "R", "<cmd>DiffviewRefresh<cr>", { desc = "Refresh" } } },
      file_history_panel = { { "n", "R", "<cmd>DiffviewRefresh<cr>", { desc = "Refresh" } } },
    },
  },
}
