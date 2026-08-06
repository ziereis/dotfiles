return {
  "barrettruth/diffs.nvim",
  cmd = { "Diff" },
  init = function()
    vim.g.diffs = {
      integrations = {
        gitsigns = true,
        neogit = true,
      },
    }
  end,
  keys = {
    { "<leader>gr", "<cmd>Diff review<cr>", desc = "[G]it [R]eview" },
  },
}
