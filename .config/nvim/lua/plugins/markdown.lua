return {
  "MeanderingProgrammer/render-markdown.nvim",
  dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-mini/mini.nvim" }, -- if you use the mini.nvim suite
  -- dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-mini/mini.icons' },        -- if you use standalone mini plugins
  -- dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-tree/nvim-web-devicons' }, -- if you prefer nvim-web-devicons
  ---@module 'render-markdown'
  ---@type render.md.UserConfig
  opts = {
    heading = {
      -- No full-width slab behind headings. The default `backgrounds` list
      -- resolves through RenderMarkdownH{1..6}Bg, which link to
      -- DiffText/DiffAdd/DiffChange/DiffDelete/Visual/CursorColumn -- so
      -- headings render in the git-diff tints that theme.lua
      -- defines. An empty list makes render-markdown paint no background at
      -- all; the level is carried by the foreground ramp set in theme.lua.
      -- Repopulating this list brings the diff tints back unless those Bg
      -- groups are given real colors first.
      backgrounds = {},
    },
  },
}
