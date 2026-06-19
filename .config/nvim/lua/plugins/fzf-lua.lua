return {
  "ibhagwan/fzf-lua",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  event = "VimEnter",
  config = function()
    local fzf = require("fzf-lua")

    fzf.setup({
      "fzf-native",
      fzf_colors = true,
      previewers = {
        builtin = {
          syntax = true,
          treesitter = { enabled = true },
        },
      },
      winopts = {
        height = 0.85,
        width = 0.80,
        row = 0.35,
        col = 0.50,
        border = "rounded",
        preview = {
          border = "rounded",
          wrap = "nowrap",
          hidden = "nohidden",
          vertical = "down:45%",
          horizontal = "right:50%",
          layout = "flex",
          flip_columns = 120,
        },
      },
      keymap = {
        builtin = {
          ["<C-d>"] = "preview-page-down",
          ["<C-u>"] = "preview-page-up",
        },
        fzf = {
          ["ctrl-q"] = "select-all+accept",
        },
      },
    })

    -- Register ui-select (replacement for telescope-ui-select)
    fzf.register_ui_select()

    -- Search keymaps
    vim.keymap.set("n", "<leader>sh", fzf.help_tags, { desc = "[S]earch [H]elp" })
    vim.keymap.set("n", "<leader>sk", fzf.keymaps, { desc = "[S]earch [K]eymaps" })
    vim.keymap.set("n", "<leader>sf", fzf.files, { desc = "[S]earch [F]iles" })
    vim.keymap.set("n", "<leader>ss", fzf.builtin, { desc = "[S]earch [S]elect fzf-lua" })
    vim.keymap.set("n", "<leader>sw", fzf.grep_cword, { desc = "[S]earch current [W]ord" })
    vim.keymap.set("v", "<leader>sw", fzf.grep_visual, { desc = "[S]earch visual selection" })

    -- Live grep with hidden files
    vim.keymap.set("n", "<leader>sg", function()
      fzf.live_grep({
        rg_opts = "--column --line-number --no-heading --color=always --smart-case --hidden",
      })
    end, { desc = "[S]earch by [G]rep" })

    vim.keymap.set("n", "<leader>sd", fzf.diagnostics_workspace, { desc = "[S]earch [D]iagnostics" })
    vim.keymap.set("n", "<leader>sr", fzf.resume, { desc = "[S]earch [R]esume" })
    vim.keymap.set("n", "<leader>s.", fzf.oldfiles, { desc = '[S]earch Recent Files ("." for repeat)' })
    vim.keymap.set("n", "<leader><leader>", fzf.buffers, { desc = "[ ] Find existing buffers" })

    -- Current buffer fuzzy find (dropdown style, no previewer)
    vim.keymap.set("n", "<leader>/", function()
      fzf.blines({
        winopts = {
          height = 0.40,
          width = 0.60,
          row = 0.40,
          preview = { hidden = "hidden" },
        },
      })
    end, { desc = "[/] Fuzzily search in current buffer" })

    -- Live grep in open files only
    vim.keymap.set("n", "<leader>s/", function()
      local buffers = vim.tbl_filter(function(buf)
        return vim.api.nvim_buf_is_loaded(buf) and vim.api.nvim_buf_get_name(buf) ~= ""
      end, vim.api.nvim_list_bufs())

      local filenames = vim.tbl_map(function(buf)
        return vim.fn.fnameescape(vim.api.nvim_buf_get_name(buf))
      end, buffers)

      if #filenames == 0 then
        vim.notify("No open files to search", vim.log.levels.WARN)
        return
      end

      fzf.live_grep({
        cmd = "rg --column --line-number --no-heading --color=always --smart-case",
        search = "",
        filespec = table.concat(filenames, " "),
        prompt = "Grep Open Files> ",
      })
    end, { desc = "[S]earch [/] in Open Files" })

    -- Search in Neovim config
    vim.keymap.set("n", "<leader>sn", function()
      fzf.files({ cwd = vim.fn.stdpath("config") })
    end, { desc = "[S]earch [N]eovim files" })

    -- Git pickers
    vim.keymap.set("n", "<leader>gc", fzf.git_commits, { desc = "[G]it [C]ommits" })
    vim.keymap.set("n", "<leader>gb", fzf.git_branches, { desc = "[G]it [B]ranches" })
    vim.keymap.set("n", "<leader>gs", fzf.git_status, { desc = "[G]it [S]tatus" })
  end,
}
