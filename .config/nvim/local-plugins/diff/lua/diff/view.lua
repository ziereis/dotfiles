local M = {}
local api = vim.api
local render = require('diff.render')
local sessions = {}

function M.close()
  local close = sessions[api.nvim_get_current_tabpage()]
  if close then close() end
end

local function replace(buf, lines)
  vim.bo[buf].modifiable = true
  api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
end

local function buffer(lines, ft)
  local buf = api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = 'wipe'
  vim.bo[buf].swapfile = false
  vim.bo[buf].filetype = ft
  api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  return buf
end

function M.open(files, title, width, opts)
  opts = opts or {}
  vim.cmd('tabnew')
  local tab = api.nvim_get_current_tabpage()
  local diffwin = api.nvim_get_current_win()
  local diffbuf = buffer({ 'Select a file' }, 'diff')
  vim.b[diffbuf].diff_diff = true
  api.nvim_win_set_buf(diffwin, diffbuf)
  local function header(label)
    title = label
    if api.nvim_win_is_valid(diffwin) then
      -- Labels are literal text, not statusline expressions.
      local text = (opts.branch and ('Branch: ' .. opts.branch .. ' | ') or '') .. 'Viewing: ' .. label
      vim.wo[diffwin].winbar = text:gsub('[\r\n]', ' '):gsub('%%', '%%%%')
    end
  end
  header(title)
  vim.cmd('topleft vsplit')
  local panelwin = api.nvim_get_current_win()
  api.nvim_win_set_width(panelwin, width)
  local row_files, file_rows = {}, {}
  local function labels()
    row_files, file_rows = {}, {}
    local rows = { title, '', 'Files (' .. #files .. ')' }
    local section
    for index, file in ipairs(files) do
      if file.section and section ~= file.section then
        section = file.section
        rows[#rows + 1] = section
      end
      rows[#rows + 1] = file.status .. '  ' .. file.path:gsub('[\r\n\t]', ' ')
      row_files[#rows], file_rows[index] = index, #rows
    end
    if #files == 0 then rows[#rows + 1] = 'No changes' end
    return rows
  end
  local panelbuf = buffer(labels(), 'diff')
  api.nvim_win_set_buf(panelwin, panelbuf)
  render.panel(panelbuf, row_files, files)
  local commitwin, commitbuf
  if opts.commits then
    vim.cmd('belowright split')
    commitwin = api.nvim_get_current_win()
    api.nvim_win_set_height(commitwin, math.max(4, math.floor(vim.o.lines / 3)))
    local lines = { 'Commits (' .. (opts.commit_count or (#opts.commits - 1)) .. ')' .. (opts.compare and ' — c: compare' or ''), '' }
    for _, commit in ipairs(opts.commits) do lines[#lines + 1] = commit.label end
    commitbuf = buffer(lines, 'diff')
    api.nvim_win_set_buf(commitwin, commitbuf)
    api.nvim_set_current_win(panelwin)
  end
  local windows = { panelwin, diffwin }
  if commitwin then windows[#windows + 1] = commitwin end
  for _, win in ipairs(windows) do
    vim.wo[win].number = false
    vim.wo[win].relativenumber = false
    vim.wo[win].wrap = false
    vim.wo[win].signcolumn = 'no'
    -- Splits inherit window options, including a previous review's gutter.
    vim.wo[win].statuscolumn = ''
    vim.wo[win].foldcolumn = '0'
    vim.wo[win].numberwidth = 1
    vim.wo[win].list = false
    vim.wo[win].foldenable = false
    vim.wo[win].fillchars = 'eob: '
  end
  vim.wo[diffwin].number = true
  vim.wo[diffwin].statuscolumn = "%!v:lua.require'diff.render'.gutter()"
  vim.wo[diffwin].winhighlight = 'CursorLine:Visual'
  vim.wo[panelwin].winbar = 'Files  ·  Enter: diff  e: edit'
  if commitwin then vim.wo[commitwin].winbar = 'Commits' .. (opts.compare and '  ·  c: compare' or '') end
  vim.wo[panelwin].winfixwidth = true
  vim.wo[panelwin].cursorline = true
  if commitwin then
    vim.wo[commitwin].cursorline = true
    vim.wo[commitwin].winfixwidth = true
  end
  local selected, raw_rows, displayed_file
  local preview_id = 0
  local context_cache = {}
  local function select(index)
    local file = files[index]
    if not file or index == selected or not api.nvim_win_is_valid(diffwin)
      or not api.nvim_buf_is_valid(diffbuf) then return end
    preview_id = preview_id + 1
    local generation = preview_id
    displayed_file = file.full or file
    raw_rows = render.draw(diffbuf, displayed_file)
    render.folds(diffwin, diffbuf)
    api.nvim_win_set_cursor(diffwin, { 1, 0 })
    selected = index
    if file.section then
      local comparisons = { Staged = 'HEAD → index', Unstaged = 'index → working tree', Untracked = 'new file → working tree' }
      header(file.section .. ': ' .. comparisons[file.section])
    end
    if opts.root and not file.full then
      require('diff.source').context(opts.root, file, function(expanded, err)
        if generation ~= preview_id or files[selected or 0] ~= file or not api.nvim_buf_is_valid(diffbuf) or not api.nvim_win_is_valid(diffwin) then
          file.full = nil
          return
        end
        if not expanded then
          vim.notify('Context unavailable: ' .. tostring(err), vim.log.levels.WARN); return
        end
        if expanded == file then return end
        local old_raw = raw_rows[api.nvim_win_get_cursor(diffwin)[1]]
        local target_line = require('diff.source').line(file, old_raw or 1)
        raw_rows = render.draw(diffbuf, expanded)
        displayed_file = expanded
        render.folds(diffwin, diffbuf)
        local numbers = (render.data[diffbuf] or {}).gutters or {}
        for row, gutter in ipairs(numbers) do
          if gutter[2] == target_line then api.nvim_win_set_cursor(diffwin, { row, 0 }); break end
        end
        -- Bound full-file caching to the most recently viewed files.
        for i = #context_cache, 1, -1 do if context_cache[i] == file then table.remove(context_cache, i) end end
        context_cache[#context_cache + 1] = file
        if #context_cache > 8 then table.remove(context_cache, 1).full = nil end
      end)
    end
  end
  api.nvim_create_autocmd('CursorMoved', {
    buffer = panelbuf,
    desc = 'Preview the file under the cursor',
    callback = function()
      if api.nvim_win_is_valid(panelwin) then
        select(row_files[api.nvim_win_get_cursor(panelwin)[1]])
      end
    end,
  })
  local function close()
    sessions[tab] = nil
    if api.nvim_tabpage_is_valid(tab) then
      api.nvim_set_current_tabpage(tab)
      vim.cmd('tabclose')
    end
  end
  sessions[tab] = close
  api.nvim_create_autocmd('BufWipeout', { buffer = panelbuf, once = true, callback = function() sessions[tab] = nil end })
  local buffers = { panelbuf, diffbuf }
  if commitbuf then buffers[#buffers + 1] = commitbuf end
  for _, buf in ipairs(buffers) do
    vim.keymap.set('n', 'q', close, { buffer = buf, desc = 'Close diff' })
    vim.keymap.set('n', '<Tab>', function()
      local current = api.nvim_get_current_win()
      local target = current == panelwin and diffwin or (current == diffwin and (commitwin or panelwin) or panelwin)
      if api.nvim_win_is_valid(target) then api.nvim_set_current_win(target) end
    end, { buffer = buf, desc = 'Switch diff pane' })
  end
  vim.keymap.set('n', '<CR>', function()
    local index = row_files[api.nvim_win_get_cursor(panelwin)[1]]
    if files[index] and api.nvim_win_is_valid(diffwin) then
      select(index)
      api.nvim_set_current_win(diffwin)
    end
  end, { buffer = panelbuf, desc = 'Focus file diff' })
  vim.keymap.set('n', '<Esc>', function()
    if api.nvim_win_is_valid(panelwin) then api.nvim_set_current_win(panelwin) end
  end, { buffer = diffbuf, desc = 'Return to files' })
  local request = 0
  local function apply(patch, err, label)
    if not api.nvim_buf_is_valid(panelbuf) or not api.nvim_buf_is_valid(diffbuf) then return end
    if not patch then vim.notify('diff: ' .. err, vim.log.levels.ERROR); return end
    header(label)
    files, selected = require('diff.source').parse(patch), nil
    replace(panelbuf, labels())
    render.panel(panelbuf, row_files, files)
    api.nvim_buf_clear_namespace(diffbuf, render.ns, 0, -1)
    vim.b[diffbuf].diff_gutters = {}
    render.data[diffbuf] = nil
    replace(diffbuf, { 'No changes' })
    if api.nvim_win_is_valid(panelwin) and #files > 0 then
      api.nvim_win_set_cursor(panelwin, { file_rows[1], 0 })
      select(1)
    end
  end
  local refresh_id = 0
  local function refresh()
    if not opts.reload or not api.nvim_buf_is_valid(panelbuf) or not api.nvim_buf_is_valid(diffbuf) then return end
    refresh_id = refresh_id + 1
    local id = refresh_id
    local previous = files[selected or 0]
    local previous_row = api.nvim_win_is_valid(panelwin) and api.nvim_win_get_cursor(panelwin)[1] or 4
    local panel_view = api.nvim_win_is_valid(panelwin) and api.nvim_win_call(panelwin, vim.fn.winsaveview)
    local previous_cursor = api.nvim_win_is_valid(diffwin) and api.nvim_win_get_cursor(diffwin)
    opts.reload(function(updated, err)
      if id ~= refresh_id or not api.nvim_buf_is_valid(panelbuf) or not api.nvim_buf_is_valid(diffbuf) then return end
      if not updated then vim.notify('diff: ' .. err, vim.log.levels.ERROR); return end
      files, selected = updated, nil
      header('Working tree')
      replace(panelbuf, labels())
      render.panel(panelbuf, row_files, files)
      api.nvim_buf_clear_namespace(diffbuf, render.ns, 0, -1)
      vim.b[diffbuf].diff_gutters = {}
      render.data[diffbuf] = nil
      replace(diffbuf, { 'No changes' })
      local index, distance, same_section = 1, math.huge, false
      for i, file in ipairs(files) do
        if previous and file.path == previous.path and file.section == previous.section then index = i; break end
        local matches_section = previous and file.section == previous.section
        local delta = math.abs(file_rows[i] - previous_row)
        if (matches_section and not same_section) or (matches_section == same_section and delta < distance) then
          index, distance, same_section = i, delta, matches_section
        end
      end
      if #files > 0 and api.nvim_win_is_valid(panelwin) then
        api.nvim_win_set_cursor(panelwin, { file_rows[index], 0 })
        if panel_view then
          panel_view.lnum, panel_view.col = file_rows[index], 0
          api.nvim_win_call(panelwin, function() vim.fn.winrestview(panel_view) end)
        end
        select(index)
        if previous and files[index].path == previous.path and files[index].section == previous.section and previous_cursor then
          api.nvim_win_set_cursor(diffwin, { math.min(previous_cursor[1], api.nvim_buf_line_count(diffbuf)), previous_cursor[2] })
        end
      end
    end)
  end
  if opts.working then
    local busy = false
    for _, buf in ipairs({ panelbuf, diffbuf }) do
      vim.keymap.set('n', 'r', refresh, { buffer = buf, desc = 'Refresh working tree' })
      for key, unstage in pairs({ s = false, u = true }) do
        vim.keymap.set('n', key, function()
          local index = api.nvim_get_current_win() == panelwin and row_files[api.nvim_win_get_cursor(panelwin)[1]] or selected
          local file = files[index or 0]
          if not file or busy then return end
          if unstage and file.section ~= 'Staged' then return end
          if not unstage and file.section == 'Staged' then return end
          if vim.fn.bufnr(opts.root .. '/' .. file.path) ~= -1 then
            local loaded = vim.fn.bufnr(opts.root .. '/' .. file.path)
            if vim.bo[loaded].modified then
              vim.notify('Save the file before staging its disk contents', vim.log.levels.WARN); return
            end
          end
          busy = true
          require('diff.source').stage(opts.root, file, unstage, function(out, err)
            busy = false
            if not out then vim.notify('diff: ' .. err, vim.log.levels.ERROR); return end
            refresh()
          end)
        end, { buffer = buf, desc = unstage and 'Unstage file' or 'Stage file' })
      end
    end
    api.nvim_create_autocmd('TabEnter', { buffer = panelbuf, callback = refresh })
  end
  local function edit()
    local index = api.nvim_get_current_win() == panelwin and row_files[api.nvim_win_get_cursor(panelwin)[1]] or selected
    local file = files[index or 0]
    if not file or not opts.root then return end
    local path = opts.root .. '/' .. file.path
    if vim.fn.filereadable(path) ~= 1 then
      vim.notify('This file does not exist in the current checkout', vim.log.levels.WARN); return
    end
    local cursor = api.nvim_win_get_cursor(diffwin)
    local line = require('diff.source').line(displayed_file or file, raw_rows and raw_rows[cursor[1]] or 1)
    vim.cmd('tabnew')
    local edit_tab = api.nvim_get_current_tabpage()
    vim.cmd('edit ' .. vim.fn.fnameescape(path))
    local editbuf = api.nvim_get_current_buf()
    api.nvim_win_set_cursor(0, { math.min(line, api.nvim_buf_line_count(editbuf)), cursor[2] })
    -- Use a temporary buffer-local mapping, restoring any existing mapping on return.
    local previous = vim.fn.maparg('<leader>db', 'n', false, true)
    local function back()
      pcall(vim.keymap.del, 'n', '<leader>db', { buffer = editbuf })
      if previous.buffer == 1 then vim.fn.mapset('n', false, previous) end
      if api.nvim_tabpage_is_valid(tab) then
        api.nvim_set_current_tabpage(tab)
        if api.nvim_win_is_valid(diffwin) then api.nvim_set_current_win(diffwin) end
        refresh()
      end
      if api.nvim_tabpage_is_valid(edit_tab) and not vim.bo[editbuf].modified then
        local number = api.nvim_tabpage_get_number(edit_tab)
        pcall(vim.cmd, 'tabclose ' .. number)
      end
    end
    vim.keymap.set('n', '<leader>db', back, { buffer = editbuf, desc = 'Return to diff review' })
    vim.notify('Editing current checkout. Save with :w; return with <leader>db.')
  end
  for _, buf in ipairs({ panelbuf, diffbuf }) do
    vim.keymap.set('n', 'e', edit, { buffer = buf, desc = 'Edit file at diff line' })
  end
  if commitbuf then
    local active = 1
    local function preview()
      local index = api.nvim_win_get_cursor(commitwin)[1] - 2
      local choice = opts.commits[index]
      if not choice or active == index then return end
      active = index
      request = request + 1
      local id = request
      opts.load(choice, function(patch, err)
        if id == request then apply(patch, err, choice.title or choice.label) end
      end)
    end
    api.nvim_create_autocmd('CursorMoved', { buffer = commitbuf, callback = preview })
    api.nvim_win_set_cursor(commitwin, { 3, 0 })
    vim.keymap.set('n', '<CR>', function()
      preview()
      if api.nvim_win_is_valid(panelwin) then api.nvim_set_current_win(panelwin) end
    end, { buffer = commitbuf, desc = 'Focus files for commit' })
    if opts.compare then vim.keymap.set('n', 'c', function()
      opts.compare(function(patch, err, label)
        request = request + 1
        active = nil
        apply(patch, err, label)
      end)
    end, { buffer = commitbuf, desc = 'Compare two snapshots' }) end
  end
  local function jump_change(backward)
    local groups = (render.data[diffbuf] or {}).highlights or {}
    local starts, changing = {}, false
    for row, group in ipairs(groups) do
      local changed = group == 'DiffViewerAdd' or group == 'DiffViewerDelete'
      if changed and not changing then starts[#starts + 1] = row end
      changing = changed
    end
    local current = api.nvim_win_get_cursor(diffwin)[1]
    if backward then
      for i = #starts, 1, -1 do
        if starts[i] < current then api.nvim_win_set_cursor(diffwin, { starts[i], 0 }); return end
      end
    else
      for _, row in ipairs(starts) do
        if row > current then api.nvim_win_set_cursor(diffwin, { row, 0 }); return end
      end
    end
  end
  vim.keymap.set('n', ']h', function() jump_change(false) end, { buffer = diffbuf })
  vim.keymap.set('n', '[h', function() jump_change(true) end, { buffer = diffbuf })
  if #files > 0 then api.nvim_win_set_cursor(panelwin, { file_rows[1], 0 }); select(1) end
end

return M
