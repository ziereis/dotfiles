-- Reviews (vs trunk, vs the downstack branch) live in diff.lua; this
-- plugin is kept for its gitsigns hunk highlighting and neogit diff rendering.
return {
  "barrettruth/diffs.nvim",
  -- Loaded by the local viewer (and Neogit) for integrations. :Diff belongs
  -- to local-plugins/diff, which loads after this dependency.
  lazy = true,
  init = function()
    vim.g.diffs = {
      integrations = {
        gitsigns = true,
        neogit = true,
      },
    }
  end,
}
