if vim.g.loaded_diff then return end
vim.g.loaded_diff = true

vim.api.nvim_create_user_command('DiffCompare', function()
  require('diff').compare()
end, { desc = 'Select two commits from repository history to compare' })

vim.api.nvim_create_user_command('Diff', function(opts)
  if #opts.fargs > 2 then
    vim.notify('Usage: Diff [commit | pr-N | old new]', vim.log.levels.ERROR)
    return
  end
  require('diff').open(opts.fargs[1], opts.fargs[2])
end, { nargs = '*', desc = 'Unified diff: working tree, commit, two refs, or pr-N' })

vim.api.nvim_create_user_command('DiffBranch', function(opts)
  if #opts.fargs > 2 then
    vim.notify('Usage: DiffBranch [branch [base]]', vim.log.levels.ERROR)
    return
  end
  require('diff').branch(opts.fargs[1], opts.fargs[2])
end, { nargs = '*', desc = 'Browse branch changes and commits (branch base)' })
