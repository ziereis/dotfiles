vim.opt.runtimepath:prepend(vim.fn.getcwd())
local source, render = require('diff.source'), require('diff.render')
local api = vim.api
local root = vim.fn.tempname()
vim.fn.mkdir(root, 'p')
local function run(args)
  local result = vim.system(args, { cwd = root, text = true }):wait()
  assert(result.code == 0, result.stderr)
  return result.stdout
end
local function await(fn)
  local done, out, err = false
  fn(function(value, failure) out, err, done = value, failure, true end)
  assert(vim.wait(5000, function() return done end), 'Timed out')
  assert(out, err)
  return out
end
local ok, err = pcall(function()
  run({ 'git', 'init', '-b', 'main' })
  run({ 'git', 'config', 'user.name', 'Test' })
  run({ 'git', 'config', 'user.email', 'test@example.com' })
  local before, after = {}, {}
  for i = 1, 120 do
    before[#before + 1] = 'line ' .. i
    if i == 50 then after[#after + 1] = 'inserted' end
    if i ~= 80 then after[#after + 1] = i == 20 and 'changed' or 'line ' .. i end
  end
  vim.fn.writefile(before, root .. '/sample.txt')
  run({ 'git', 'add', '.' })
  run({ 'git', 'commit', '-m', 'before' })
  vim.fn.writefile(after, root .. '/sample.txt')
  local patch = await(function(cb) source.diff(root, {}, cb) end)
  local file = source.parse(patch)[1]
  file.section = 'Unstaged'
  local full = await(function(cb) source.context(root, file, cb) end)
  assert(#full.lines > #file.lines, 'Load omitted context only for the selected file')
  local cached = await(function(cb) source.context(root, file, cb) end)
  assert(cached == full, 'Repeated selections should reuse full context')
  local result = render.prepare(full)
  local newlines = {}
  for row, gutter in ipairs(result.gutters) do
    if gutter[2] ~= '' then
      newlines[#newlines + 1] = result.lines[row]
      assert(source.line(full, result.raw[row]) == gutter[2], 'Expanded lines must retain edit coordinates')
    end
  end
  assert(vim.deep_equal(newlines, after), 'Reconstruct the complete new file without losing additions or deletions')
  local stale = source.expand(file, 'unrelated contents\n')
  assert(not stale, 'Reject context from a changed file')
  local buf = api.nvim_create_buf(false, true)
  api.nvim_win_set_buf(0, buf)
  render.draw(buf, full)
  render.folds(api.nvim_get_current_win(), buf)
  local closed = {}
  for row = 1, api.nvim_buf_line_count(buf) do
    if vim.fn.foldclosed(row) == row then closed[#closed + 1] = row end
  end
  assert(#closed >= 3, 'Fold leading, intervening, and trailing context')
  for row, group in ipairs(render.data[buf].highlights) do
    if group == 'DiffViewerAdd' or group == 'DiffViewerDelete' then
      assert(vim.fn.foldclosed(row) == -1, 'Changes must remain visible')
    end
  end
  api.nvim_win_set_cursor(0, { closed[1], 0 })
  vim.cmd('normal! zo')
  assert(vim.fn.foldclosed(closed[1]) == -1)
  vim.cmd('normal! zc')
  assert(vim.fn.foldclosed(closed[1]) == closed[1])
  vim.cmd('normal! zR')
  for _, row in ipairs(closed) do assert(vim.fn.foldclosed(row) == -1) end
  vim.cmd('normal! zM')
  for _, row in ipairs(closed) do assert(vim.fn.foldclosed(row) == row) end
  run({ 'git', 'add', '.' })
  local staged = source.parse(await(function(cb) source.diff(root, { '--cached' }, cb) end))[1]
  staged.section = 'Staged'
  vim.fn.writefile({ 'different working tree' }, root .. '/sample.txt')
  local staged_full = await(function(cb) source.context(root, staged, cb) end)
  assert(vim.deep_equal(render.prepare(staged_full).lines, result.lines), 'Staged context must use the index blob, not disk')
  run({ 'git', 'commit', '-m', 'after' })
  local historical = source.parse(await(function(cb) source.diff(root, { 'HEAD~1', 'HEAD' }, cb) end))[1]
  local historical_full = await(function(cb) source.context(root, historical, cb) end)
  assert(vim.deep_equal(render.prepare(historical_full).lines, result.lines), 'Historical context must use the reviewed blob')
end)
vim.fn.delete(root, 'rf')
if not ok then error(err) end
print('Native fold and full-context tests passed')
