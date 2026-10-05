vim.opt.runtimepath:prepend(vim.fn.getcwd())
local source = require('diff.source')
local root = vim.fn.tempname()
vim.fn.mkdir(root, 'p')
local function run(args)
  local result = vim.system(args, { cwd = root, text = true }):wait()
  assert(result.code == 0, result.stderr)
  return result.stdout
end
local function await(fn)
  local done, value, err = false
  fn(function(out, failure) value, err, done = out, failure, true end)
  assert(vim.wait(5000, function() return done end), 'Timed out')
  assert(value, err)
  return value
end
local ok, err = pcall(function()
  local headers = table.concat({
    'diff --git a/deleted.lua b/deleted.lua',
    'deleted file mode 100644', '--- a/deleted.lua', '+++ /dev/null',
    '@@ -1,2 +0,0 @@', '--- a/fake-path', '--- content and misattribute them.',
    'diff --git a/added.txt b/added.txt',
    'new file mode 100644', '--- /dev/null', '+++ b/added.txt',
    '@@ -0,0 +1,1 @@', '+++ b/not-a-filename',
    'diff --git a/normal.lua b/normal.lua',
    '--- a/normal.lua', '+++ b/normal.lua',
    '@@ -1 +1 @@', '--- removed comment', '+++ added comment',
  }, '\n')
  local parsed = source.parse(headers)
  assert(#parsed == 3)
  assert(parsed[1].path == 'deleted.lua' and parsed[1].status == 'D', 'Deleted comments must not replace the filename')
  assert(parsed[2].path == 'added.txt' and parsed[2].status == 'A', 'Added code must not replace the filename')
  assert(parsed[3].path == 'normal.lua' and parsed[3].status == 'M', 'Header state must reset for each file')
  assert(parsed[1].lines[#parsed[1].lines] == '--- content and misattribute them.', 'Keep hunk content intact')
  local sample = { lines = { '@@ -10,3 +20,3 @@', ' context', '-removed', '+added', ' tail' } }
  assert(source.line(sample, 2) == 20)
  assert(source.line(sample, 3) == 21)
  assert(source.line(sample, 4) == 21)
  assert(source.line(sample, 5) == 22)
  local render = require('diff.render')
  sample.path = 'example.lua'
  local rendered = render.prepare(sample)
  assert(rendered.lines[4] == 'context' and rendered.lines[5] == 'removed' and rendered.lines[6] == 'added')
  assert(rendered.gutters[5][1] == 11 and rendered.gutters[5][2] == '')
  assert(rendered.gutters[6][1] == '' and rendered.gutters[6][2] == 21)
  assert(source.line(sample, rendered.raw[6]) == 21, 'Rendered rows must map to editable file lines')
  local testbuf = vim.api.nvim_create_buf(false, true)
  render.draw(testbuf, sample)
  assert(vim.bo[testbuf].filetype == 'lua', 'Use the reviewed file language for syntax')
  for _, group in ipairs({ 'DiffViewerAdd', 'DiffViewerDelete' }) do
    local hl = vim.api.nvim_get_hl(0, { name = group, link = false })
    assert(hl.bg and not hl.fg, 'Diff colors should only change the background')
  end
  assert(#vim.api.nvim_buf_get_extmarks(testbuf, render.ns, 0, -1, {}) > 0)
  vim.api.nvim_buf_delete(testbuf, { force = true })
  run({ 'git', 'init', '-b', 'main' })
  run({ 'git', 'config', 'user.email', 'test@example.com' })
  run({ 'git', 'config', 'user.name', 'Test' })
  vim.fn.writefile({ 'one', 'two' }, root .. '/original.txt')
  vim.fn.writefile({ 'delete me' }, root .. '/deleted.txt')
  run({ 'git', 'add', '.' })
  run({ 'git', 'commit', '-m', 'initial' })
  run({ 'git', 'switch', '-c', 'feature' })
  run({ 'git', 'mv', 'original.txt', 'renamed file.txt' })
  vim.fn.delete(root .. '/deleted.txt')
  vim.fn.writefile({ 'new' }, root .. '/added.txt')
  run({ 'git', 'add', '.' })
  run({ 'git', 'commit', '-m', 'changes' })
  local patch = await(function(cb) source.diff(root, { 'main', 'feature' }, cb) end)
  local files = source.parse(patch)
  assert(#files == 3, 'Expected three files')
  local statuses = {}
  for _, file in ipairs(files) do statuses[file.status] = file.path end
  assert(statuses.A == 'added.txt')
  assert(statuses.D == 'deleted.txt')
  assert(statuses.R == 'renamed file.txt')
  vim.wo.statuscolumn = '    %l'
  vim.wo.foldcolumn = '2'
  require('diff.view').open(files, 'Test', 30)
  assert(#vim.api.nvim_tabpage_list_wins(0) == 2)
  local panel = vim.api.nvim_get_current_buf()
  assert(vim.bo[panel].filetype == 'diff')
  local wins = vim.api.nvim_tabpage_list_wins(0)
  local diffwin = wins[1] == vim.api.nvim_get_current_win() and wins[2] or wins[1]
  assert(vim.b[vim.api.nvim_win_get_buf(diffwin)].diff_diff)
  local diffbuf = vim.api.nvim_win_get_buf(diffwin)
  assert(vim.api.nvim_eval_statusline(vim.wo[diffwin].statuscolumn,
    { winid = diffwin, use_statuscol_lnum = 4 }).str:match('│'), 'Render the old/new gutter')
  assert(vim.wo[diffwin].winbar == 'Viewing: Test', 'Comparison should appear above the diff')
  local panelwin = vim.api.nvim_get_current_win()
  assert(vim.wo[panelwin].statuscolumn == '' and vim.wo[panelwin].foldcolumn == '0',
    'File panel must not inherit editor gutters')
  local api = vim.api
  api.nvim_win_set_cursor(panelwin, { 5, 0 })
  api.nvim_exec_autocmds('CursorMoved', { buffer = panel })
  assert(vim.deep_equal(api.nvim_buf_get_lines(diffbuf, 0, -1, false), require('diff.render').prepare(files[2]).lines),
    'Cursor movement should preview the second file')
  assert(api.nvim_get_current_win() == panelwin, 'Preview must preserve file panel focus')
  api.nvim_win_set_cursor(diffwin, { 2, 0 })
  api.nvim_win_set_cursor(panelwin, { 5, 1 })
  api.nvim_exec_autocmds('CursorMoved', { buffer = panel })
  assert(api.nvim_win_get_cursor(diffwin)[1] == 2, 'Same file must preserve diff scroll position')
  api.nvim_win_set_cursor(panelwin, { 3, 0 })
  api.nvim_exec_autocmds('CursorMoved', { buffer = panel })
  assert(vim.deep_equal(api.nvim_buf_get_lines(diffbuf, 0, -1, false), require('diff.render').prepare(files[2]).lines),
    'Panel headings should preserve the preview')
  api.nvim_win_set_cursor(panelwin, { 5, 0 })
  local function press(buf, key)
    for _, map in ipairs(api.nvim_buf_get_keymap(buf, 'n')) do
      if map.lhs == key then map.callback(); return end
    end
    error('Missing mapping: ' .. key)
  end
  press(panel, '<CR>')
  assert(api.nvim_get_current_win() == diffwin, 'Enter should focus the diff')
  press(diffbuf, '<Esc>')
  assert(api.nvim_get_current_win() == panelwin, 'Escape should return to files')
  vim.cmd('tabclose')
  vim.cmd('tcd ' .. vim.fn.fnameescape(root))
  require('diff').open('main', 'feature')
  assert(vim.wait(5000, function() return #vim.api.nvim_list_tabpages() == 2 end))
  for _, win in ipairs(api.nvim_tabpage_list_wins(0)) do
    if vim.b[api.nvim_win_get_buf(win)].diff_diff then
      assert(vim.wo[win].winbar == 'Branch: feature | Viewing: main..feature (snapshots)')
    end
  end
  vim.cmd('tabclose')
  require('diff').branch('feature', 'main')
  assert(vim.wait(5000, function() return #vim.api.nvim_list_tabpages() == 2 end))
  assert(#api.nvim_tabpage_list_wins(0) == 3, 'Branch view should keep a commit pane')
  panelwin = api.nvim_get_current_win()
  panel = api.nvim_get_current_buf()
  local commitwin, commitbuf
  for _, win in ipairs(api.nvim_tabpage_list_wins(0)) do
    local buf = api.nvim_win_get_buf(win)
    if api.nvim_buf_get_lines(buf, 0, 1, false)[1]:match('^Commits') then
      commitwin, commitbuf = win, buf
    end
  end
  assert(commitwin, 'Expected persistent commits list')
  api.nvim_set_current_win(commitwin)
  api.nvim_win_set_cursor(commitwin, { 4, 0 })
  api.nvim_exec_autocmds('CursorMoved', { buffer = commitbuf })
  assert(vim.wait(5000, function()
    return api.nvim_buf_get_lines(panel, 0, 1, false)[1]:match('changes$') ~= nil
  end), 'Commit selection should update files in place')
  assert(#api.nvim_list_tabpages() == 2, 'Commit preview must reuse the tab')
  assert(api.nvim_get_current_win() == commitwin, 'Commit preview must preserve focus')
  press(commitbuf, '<CR>')
  assert(api.nvim_get_current_win() == panelwin)
  api.nvim_set_current_win(commitwin)
  api.nvim_win_set_cursor(commitwin, { 3, 0 })
  api.nvim_exec_autocmds('CursorMoved', { buffer = commitbuf })
  assert(vim.wait(5000, function()
    return api.nvim_buf_get_lines(panel, 0, 1, false)[1] == 'main...feature (since merge base)'
  end))
  vim.cmd('tabclose')
  local callbacks = {}
  require('diff.view').open(files, 'Race test', 30, {
    commits = { { label = 'All' }, { label = 'Old' }, { label = 'Newest' } },
    load = function(_, cb) callbacks[#callbacks + 1] = cb end,
  })
  panel = api.nvim_get_current_buf()
  for _, win in ipairs(api.nvim_tabpage_list_wins(0)) do
    if api.nvim_buf_get_lines(api.nvim_win_get_buf(win), 0, 1, false)[1]:match('^Commits') then
      commitwin, commitbuf = win, api.nvim_win_get_buf(win)
    end
  end
  api.nvim_set_current_win(commitwin)
  for _, row in ipairs({ 4, 5 }) do
    api.nvim_win_set_cursor(commitwin, { row, 0 })
    api.nvim_exec_autocmds('CursorMoved', { buffer = commitbuf })
  end
  callbacks[2](patch)
  callbacks[1]('')
  assert(api.nvim_buf_get_lines(panel, 0, 1, false)[1] == 'Newest', 'Ignore stale responses')
  for _, win in ipairs(api.nvim_tabpage_list_wins(0)) do
    if vim.b[api.nvim_win_get_buf(win)].diff_diff then
      assert(vim.wo[win].winbar == 'Viewing: Newest', 'Header must track the displayed comparison')
    end
  end
  vim.cmd('tabclose')
  callbacks[2](patch) -- A late response after closing must be harmless.
  run({ 'git', 'checkout', '--detach' })
  require('diff').open()
  assert(vim.wait(5000, function() return #api.nvim_list_tabpages() == 2 end))
  for _, win in ipairs(api.nvim_tabpage_list_wins(0)) do
    if vim.b[api.nvim_win_get_buf(win)].diff_diff then
      assert(vim.wo[win].winbar:match('^Branch: detached HEAD at %x+ | Viewing: Working tree'))
    end
  end
  vim.cmd('tabclose')
  run({ 'git', 'switch', 'feature' })
  vim.fn.writefile({ 'staged' }, root .. '/added.txt')
  run({ 'git', 'add', 'added.txt' })
  vim.fn.writefile({ 'unstaged' }, root .. '/added.txt')
  vim.fn.writefile({ 'brand new' }, root .. '/new file.txt')
  local working = await(function(cb) source.working(root, cb) end)
  local sections = {}
  for _, file in ipairs(working) do sections[file.section] = file end
  assert(sections.Staged and sections.Unstaged and sections.Untracked)
  assert(sections.Staged.path == 'added.txt' and sections.Unstaged.path == 'added.txt')
  assert(sections.Untracked.path == 'new file.txt')
  await(function(cb) source.stage(root, sections.Untracked, false, cb) end)
  assert(run({ 'git', 'show', ':new file.txt' }):match('brand new'))
  await(function(cb) source.stage(root, { path = 'new file.txt' }, true, cb) end)
  assert(run({ 'git', 'diff', '--cached', '--name-only' }) == 'added.txt\n')
  require('diff').open()
  assert(vim.wait(5000, function() return #api.nvim_list_tabpages() == 2 end))
  panel = api.nvim_get_current_buf()
  panelwin = api.nvim_get_current_win()
  for _, win in ipairs(api.nvim_tabpage_list_wins(0)) do
    if vim.b[api.nvim_win_get_buf(win)].diff_diff then diffwin = win end
  end
  diffbuf = api.nvim_win_get_buf(diffwin)
  assert(vim.wo[diffwin].winbar:match('Unstaged: index → working tree'))
  press(panel, '<CR>')
  api.nvim_win_set_cursor(diffwin, { 5, 0 })
  press(diffbuf, 'e')
  assert(vim.uv.fs_realpath(api.nvim_buf_get_name(0)) == vim.uv.fs_realpath(root .. '/added.txt'))
  assert(vim.bo.modifiable, 'Jump must open an editable file')
  assert(api.nvim_win_get_cursor(0)[1] == 1)
  local editbuf = api.nvim_get_current_buf()
  api.nvim_buf_set_lines(editbuf, 0, -1, false, { 'edited' })
  vim.cmd('write')
  local backkey = (vim.g.mapleader or '\\') .. 'db'
  press(editbuf, backkey)
  assert(api.nvim_get_current_win() == diffwin, 'Return should restore diff focus')
  assert(vim.wait(5000, function()
    return table.concat(api.nvim_buf_get_lines(diffbuf, 0, -1, false), '\n'):match('edited') ~= nil
  end), 'Returning should refresh saved changes')
  press(diffbuf, 's')
  assert(vim.wait(5000, function() return run({ 'git', 'show', ':added.txt' }):match('edited') ~= nil end))
  assert(vim.wait(5000, function()
    return vim.wo[diffwin].winbar:match('Staged: HEAD → index') ~= nil
  end), 'Staging should refresh the review')
  press(diffbuf, 'u')
  assert(vim.wait(5000, function()
    return vim.wo[diffwin].winbar:match('Unstaged: index → working tree') ~= nil
  end), 'Unstaging should refresh the review')
  vim.cmd('tabclose')
  for _, name in ipairs({ 'alpha.txt', 'beta.txt', 'gamma.txt' }) do
    vim.fn.writefile({ 'before' }, root .. '/' .. name)
  end
  run({ 'git', 'add', '.' })
  run({ 'git', 'commit', '-m', 'cursor test fixtures' })
  for _, name in ipairs({ 'alpha.txt', 'beta.txt', 'gamma.txt' }) do
    vim.fn.writefile({ 'after' }, root .. '/' .. name)
  end
  require('diff').open()
  assert(vim.wait(5000, function() return #api.nvim_list_tabpages() == 2 end))
  panel, panelwin = api.nvim_get_current_buf(), api.nvim_get_current_win()
  local function row_for(name)
    for row, text in ipairs(api.nvim_buf_get_lines(panel, 0, -1, false)) do
      if text == 'M  ' .. name then return row end
    end
  end
  local beta_row = assert(row_for('beta.txt'))
  api.nvim_win_set_cursor(panelwin, { beta_row, 0 })
  api.nvim_exec_autocmds('CursorMoved', { buffer = panel })
  press(panel, 's')
  assert(vim.wait(5000, function()
    local row = api.nvim_win_get_cursor(panelwin)[1]
    return row == beta_row and api.nvim_buf_get_lines(panel, row - 1, row, false)[1] == 'M  gamma.txt'
  end), 'Staging a middle file should keep its row and select the next unstaged file')
  press(panel, 's')
  assert(vim.wait(5000, function()
    local row = api.nvim_win_get_cursor(panelwin)[1]
    return api.nvim_buf_get_lines(panel, row - 1, row, false)[1] == 'M  alpha.txt'
  end), 'Staging the last file in a section should select the nearest remaining file')
  assert(api.nvim_get_current_win() == panelwin, 'Staging must preserve panel focus')
  require('diff.view').close()
  require('diff').history(root .. '/added.txt')
  assert(vim.wait(5000, function() return #api.nvim_list_tabpages() == 2 end))
  assert(#api.nvim_tabpage_list_wins(0) == 3, 'File history should have a commit list')
  local history_panel = api.nvim_get_current_buf()
  assert(table.concat(api.nvim_buf_get_lines(history_panel, 0, -1, false), '\n'):match('added.txt'))
  require('diff.view').close()
  assert(#api.nvim_list_tabpages() == 1, 'Close should close the review tab')
  require('diff.view').close()
  assert(#api.nvim_list_tabpages() == 1, 'Close outside a review must do nothing')
  local original_select = vim.ui.select
  local prompts = {}
  vim.ui.select = function(items, opts, callback)
    prompts[#prompts + 1] = opts.prompt
    callback(#prompts == 1 and items[#items] or items[1])
  end
  require('diff').compare()
  assert(vim.wait(5000, function() return #api.nvim_list_tabpages() == 2 end))
  assert(#prompts == 2 and prompts[1]:match('OLD') and prompts[2]:match('NEW'))
  assert(#api.nvim_tabpage_list_wins(0) == 2, 'Selected pair should open snapshot diff')
  require('diff.view').close()
  local canceled = false
  vim.ui.select = function(_, _, callback) canceled = true; callback(nil) end
  require('diff').compare()
  assert(vim.wait(5000, function() return canceled end))
  assert(#api.nvim_list_tabpages() == 1, 'Cancel must not open a diff')
  vim.ui.select = original_select
end)
vim.fn.delete(root, 'rf')
if not ok then error(err) end
print('diff smoke tests passed')
