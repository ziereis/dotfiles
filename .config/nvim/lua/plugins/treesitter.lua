return {
  "nvim-treesitter/nvim-treesitter",
  branch = "main",
  lazy = false,
  build = ":TSUpdate",
  config = function()
    local ensure_installed = {
      "bash",
      "c",
      "diff",
      "html",
      "lua",
      "luadoc",
      "markdown",
      "markdown_inline",
      "query",
      "vim",
      "vimdoc",
    }

    local nt = require("nvim-treesitter")
    local installed = nt.get_installed()
    local missing = {}
    for _, lang in ipairs(ensure_installed) do
      if not vim.tbl_contains(installed, lang) then
        table.insert(missing, lang)
      end
    end
    if #missing > 0 then
      nt.install(missing)
    end

    local no_indent = { ruby = true, cuda = true }
    local skip = { mlir = true }

    vim.api.nvim_create_autocmd("FileType", {
      callback = function(args)
        local buf = args.buf
        local ft = vim.bo[buf].filetype
        local lang = vim.treesitter.language.get_lang(ft) or ft
        if not lang or skip[lang] then
          return
        end

        if not vim.tbl_contains(nt.get_installed(), lang) then
          if vim.tbl_contains(nt.get_available(), lang) then
            nt.install({ lang })
          end
          return
        end

        pcall(vim.treesitter.start, buf, lang)
        if not no_indent[ft] then
          vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end
      end,
    })
  end,
}
