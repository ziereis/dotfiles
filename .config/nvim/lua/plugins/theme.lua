return {
  -- "projekt0n/github-nvim-theme",
  -- name = "github-theme",
  -- lazy = false, -- make sure we load this during startup if it is your main colorscheme
  -- priority = 1000, -- make sure to load this before all the other start plugins
  -- config = function()
  --   require("github-theme").setup({
  --     options = {
  --       transparent = true,
  --     },
  --   })
  --   vim.cmd([[ colorscheme github_dark_dimmed ]])
  -- end,
  --
  -- "nyoom-engineering/oxocarbon.nvim",
  -- name = "oxocarbon",
  -- lazy = false,
  -- priority = 1000,
  -- config = function()
  --   vim.opt.background = "dark"
  --   vim.cmd.colorscheme("oxocarbon")
  --
  --   -- Remove bold from all highlight groups
  --   local highlights = vim.api.nvim_get_hl(0, {})
  --   for name, hl in pairs(highlights) do
  --     if hl.bold then
  --       hl.bold = false
  --       vim.api.nvim_set_hl(0, name, hl)
  --     end
  --   end
  --
  --   vim.api.nvim_set_hl(0, "DiffAdd", { bg = "#1e3d2f" })
  --   vim.api.nvim_set_hl(0, "DiffDelete", { bg = "#3d1e28" })
  --   vim.api.nvim_set_hl(0, "DiffChange", { bg = "#2b3d4f" })
  --   vim.api.nvim_set_hl(0, "DiffText", { bg = "#3b4d5f" })
  --   vim.api.nvim_set_hl(0, "DiffviewDiffDeleteDim", { bg = "none", fg = "#3a3a3a" })
  --
  --   -- Neo-tree: use white instead of teal for directories
  --   vim.api.nvim_set_hl(0, "Directory", { fg = "#ffffff" })
  --   vim.api.nvim_set_hl(0, "NeoTreeDirectoryName", { fg = "#ffffff" })
  --   vim.api.nvim_set_hl(0, "NeoTreeDirectoryIcon", { fg = "#ffffff" })
  --   vim.api.nvim_set_hl(0, "NeoTreeRootName", { fg = "#ffffff" })
  -- end,

  -- "shaunsingh/nord.nvim",
  -- lazy = false,
  -- priority = 1000,
  -- config = function()
  --   vim.cmd.colorscheme("nord")
  -- end,

  -- "kdheepak/monochrome.nvim",
  -- lazy = false,
  -- priority = 1000,
  -- config = function()
  --   vim.cmd.colorscheme("monochrome")
  -- end,

  -- "folke/tokyonight.nvim",
  -- lazy = false,
  -- priority = 1000,
  -- config = function()
  --   require("tokyonight").setup({
  --     transparent = true,
  --     styles = {
  --       sidebars = "transparent",
  --       floats = "transparent",
  --     },
  --   })
  --   vim.cmd.colorscheme("tokyonight-night")
  -- end,

  "blazkowolf/gruber-darker.nvim",
  lazy = false,
  priority = 1000,
  config = function()
    vim.cmd.colorscheme("gruber-darker")
    vim.api.nvim_set_hl(0, "String", { fg = "#b8bb8a" })

    vim.api.nvim_set_hl(0, "DiffAdd", { bg = "#1e3d2f" })
    vim.api.nvim_set_hl(0, "DiffDelete", { bg = "#3d1e28" })
    vim.api.nvim_set_hl(0, "DiffChange", { bg = "#2b3d4f" })
    vim.api.nvim_set_hl(0, "DiffText", { bg = "#3b4d5f" })
  end,
}
