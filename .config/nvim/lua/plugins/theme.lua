-- Vesper ships no usable diff highlights. Its Diff* groups set only a
-- foreground over the normal background, so changed lines render identically to
-- unchanged ones and the foreground just muddies syntax colors; DiffText, the
-- intra-line change that matters most in review, lands at 1.86:1 against the
-- background. Added/Changed/Removed are left at Neovim's pastel defaults
-- (#b3f6c0/#8cf8f7/#ffc0b9), which gitsigns and diffview's file panel link to.
--
-- Rebuild both from the Vesper palette. Line backgrounds are the accent hue at
-- 14% over #101010 and word-level backgrounds at 30%, mirroring the 0x15 alpha
-- tints upstream Vesper uses for the same purpose. Backgrounds carry the signal
-- so syntax highlighting still shows through the changed text.
local diff = {
  bg_dark = "#161616",
  mint = "#99FFE4",
  red = "#FF8080",
  peach = "#FFC799",

  add_line = "#23312E",
  add_word = "#395850",
  del_line = "#312020",
  del_word = "#583232",
  chg_line = "#312A23",
  chg_word = "#584739",
}

local function apply_diff_highlights()
  local hl = function(group, spec)
    vim.api.nvim_set_hl(0, group, spec)
  end

  -- Core diff groups. No foreground, so the diffed text keeps its syntax colors.
  hl("DiffAdd", { bg = diff.add_line })
  hl("DiffChange", { bg = diff.chg_line })
  hl("DiffText", { bg = diff.chg_word })
  -- No foreground, for the same reason as the groups above: diffview copies
  -- both fg and bg off DiffDelete into DiffviewDiffAddAsDelete, which is what
  -- paints deleted lines in the left pane, so a foreground here renders them
  -- as the deletion tint on the deletion tint. Filler rows are unaffected --
  -- both panes map their fillchar to DiffviewDiffDeleteDim instead.
  hl("DiffDelete", { bg = diff.del_line })

  -- gitsigns signs and diffview's file panel counters resolve through these.
  hl("Added", { fg = diff.mint })
  hl("Changed", { fg = diff.peach })
  hl("Removed", { fg = diff.red })
  hl("diffAdded", { fg = diff.mint })
  hl("diffChanged", { fg = diff.peach })
  hl("diffRemoved", { fg = diff.red })

  -- gitsigns word-level hunk diffs.
  hl("GitSignsAddInline", { bg = diff.add_word })
  hl("GitSignsChangeInline", { bg = diff.chg_word })
  hl("GitSignsDeleteInline", { bg = diff.del_word })

  -- diffview recomputes DiffviewDiffAddAsDelete from DiffDelete on load, so it
  -- follows the groups above on its own. DeleteDim it only links by default,
  -- landing on Comment gray; point it at the deletion tint instead.
  hl("DiffviewDiffDeleteDim", { fg = diff.del_word })

  -- neogit only defines a group it finds unset, so these must land first.
  hl("NeogitDiffAdd", { bg = diff.add_line })
  hl("NeogitDiffAddHighlight", { bg = diff.add_word })
  hl("NeogitDiffDelete", { bg = diff.del_line })
  hl("NeogitDiffDeleteHighlight", { bg = diff.del_word })
  hl("NeogitDiffContextHighlight", { bg = diff.bg_dark })
  hl("NeogitHunkHeader", { fg = diff.peach, bg = diff.bg_dark })
  hl("NeogitHunkHeaderHighlight", { fg = "#101010", bg = diff.peach })
end

-- Vesper predates the @markup.* capture names and still targets the legacy
-- @text.* ones, several of which it misspelled as @texcolors.* in a bad
-- rename, so nothing it defines reaches a markdown buffer. Every markdown
-- capture therefore lands unset, and render-markdown's default links resolve
-- into whatever Vesper happens to define for unrelated purposes.
--
-- The worst of it: RenderMarkdownCode(Inline) links to ColorColumn, which
-- Vesper paints #585858 -- a near-mid gray slab. Inline code inherits its
-- foreground from an unset @markup.raw, i.e. Normal's #CCCCCC, for 4.4:1, and
-- comments inside a fenced block land at 1.7:1 against the same slab. The
-- heading backgrounds link straight to DiffText/DiffAdd/DiffChange/DiffDelete,
-- so headings render in the git-diff tints defined above.
--
-- Rebuild the markdown surface from the Vesper palette. Code carries a darker
-- slab than the editor background so syntax colors keep the contrast they were
-- tuned for, and headings carry a brightness ramp. The heading slabs stay off
-- entirely; markdown.lua drops them, because clearing a highlight
-- group here cannot win -- a cleared group reads as unset, so render-markdown's
-- `default = true` links reapply on top of it when its plugin file runs.
local markdown = {
  code_bg = "#161616",
  inline_bg = "#232323",
  inline_fg = "#FFC799",

  white = "#FFFFFF",
  peach = "#FFC799",
  mint = "#99FFE4",
  mint_dim = "#82D9C2",
  fg = "#CCCCCC",
  primary = "#A0A0A0",
  comment = "#7D7D7D",
  symbol = "#65737E",
}

local function apply_markdown_highlights()
  local hl = function(group, spec)
    vim.api.nvim_set_hl(0, group, spec)
  end

  -- Inline code. Peach on the darkest panel tint, 10.4:1.
  hl("@markup.raw", { fg = markdown.inline_fg, bg = markdown.inline_bg })
  hl("@markup.raw.markdown_inline", { fg = markdown.inline_fg, bg = markdown.inline_bg })
  hl("RenderMarkdownCodeInline", { fg = markdown.inline_fg, bg = markdown.inline_bg })

  -- Fenced and indented blocks. No foreground: language injections paint the
  -- contents, and @markup.raw.block would otherwise flatten an unlabelled
  -- fence to a single color.
  hl("@markup.raw.block", { bg = markdown.code_bg })
  hl("RenderMarkdownCode", { bg = markdown.code_bg })
  hl("RenderMarkdownCodeBorder", { bg = markdown.code_bg })
  hl("RenderMarkdownCodeFallback", { fg = markdown.fg, bg = markdown.code_bg })
  hl("RenderMarkdownCodeInfo", { fg = markdown.comment, bg = markdown.code_bg })

  -- Headings descend in brightness rather than hue, so depth reads at a glance
  -- without six competing accent colors.
  local heading = {
    markdown.white,
    markdown.peach,
    markdown.mint,
    markdown.fg,
    markdown.primary,
    markdown.comment,
  }
  for level, color in ipairs(heading) do
    hl("@markup.heading." .. level .. ".markdown", { fg = color, bold = true })
    hl("RenderMarkdownH" .. level, { fg = color, bold = true })
  end
  hl("@markup.heading", { fg = markdown.white, bold = true })

  -- Emphasis.
  hl("@markup.strong", { fg = markdown.white, bold = true })
  hl("@markup.italic", { fg = markdown.fg, italic = true })
  hl("@markup.strikethrough", { fg = markdown.comment, strikethrough = true })

  -- The query captures the whole block_quote node, so this color sets the
  -- quoted body text; only the marker bar drops to the dimmer symbol gray.
  hl("@markup.quote", { fg = markdown.primary })
  hl("RenderMarkdownQuote", { fg = markdown.symbol })

  -- Lists and checkboxes.
  hl("@markup.list", { fg = markdown.peach })
  hl("@markup.list.checked", { fg = markdown.mint })
  hl("@markup.list.unchecked", { fg = markdown.symbol })
  hl("RenderMarkdownBullet", { fg = markdown.peach })
  hl("RenderMarkdownChecked", { fg = markdown.mint })
  hl("RenderMarkdownUnchecked", { fg = markdown.symbol })
  hl("RenderMarkdownDash", { fg = markdown.symbol })

  -- Links. Label carries the color; the URL stays metadata.
  hl("@markup.link", { fg = markdown.mint_dim })
  hl("@markup.link.label", { fg = markdown.mint_dim, underline = false })
  hl("@markup.link.url", { fg = markdown.symbol, underline = true })

  -- Tables.
  hl("RenderMarkdownTableHead", { fg = markdown.peach, bold = true })
  hl("RenderMarkdownTableRow", { fg = markdown.symbol })

  -- ==highlight== spans reuse the inline code panel.
  hl("RenderMarkdownInlineHighlight", { fg = markdown.inline_fg, bg = markdown.inline_bg })
end

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

  -- "blazkowolf/gruber-darker.nvim",
  -- lazy = false,
  -- priority = 1000,
  -- config = function()
  --   vim.cmd.colorscheme("gruber-darker")
  --   vim.api.nvim_set_hl(0, "String", { fg = "#b8bb8a" })
  -- end,

  -- "navarasu/onedark.nvim",
  -- lazy = false,
  -- priority = 1000,
  -- config = function()
  --   vim.opt.background = "dark"
  --   require("onedark").setup({
  --     style = "dark",
  --   })
  --   require("onedark").load()
  -- end,

  "datsfilipe/vesper.nvim",
  lazy = false,
  priority = 1000,
  config = function()
    vim.opt.background = "dark"
    require("vesper").setup({
      italics = {
        comments = false,
        keywords = false,
        functions = false,
        strings = false,
        variables = false,
      },
    })
    vim.cmd.colorscheme("vesper")

    -- vesper.nvim maps bright white to its comment gray, leaving it darker
    -- than plain white, and blue to the same mint it uses for green. Realign
    -- both with the kitty palette in ../kitty/vesper.conf.
    vim.g.terminal_color_4 = "#8B9BA8"
    vim.g.terminal_color_12 = "#A9B8C4"
    vim.g.terminal_color_15 = "#FFFFFF"

    -- The direct call covers this startup; the autocmd re-applies on any later
    -- reload of the colorscheme, which clears every group. Both run before
    -- neogit and diffview lazy-load, so those two find the groups already set
    -- and leave them alone. render-markdown registers its groups with
    -- `default = true`, which never overwrites an existing definition, so its
    -- links lose to these regardless of load order.
    vim.api.nvim_create_autocmd("ColorScheme", {
      group = vim.api.nvim_create_augroup("vesper-highlight-overrides", { clear = true }),
      pattern = "vesper",
      callback = function()
        apply_diff_highlights()
        apply_markdown_highlights()
      end,
    })
    apply_diff_highlights()
    apply_markdown_highlights()
  end,
}
