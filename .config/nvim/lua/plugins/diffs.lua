-- Reviews (vs trunk, vs the downstack branch) live in diffview.lua now; this
-- plugin is kept for its gitsigns hunk highlighting and neogit diff rendering.
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
}
