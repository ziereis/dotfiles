local M = {}
local api = vim.api
M.ns = api.nvim_create_namespace('diff.render')

function M.highlights()
  local normal = api.nvim_get_hl(0, { name = 'Normal', link = false })
  local dark = vim.o.background == 'dark'
  local bg = normal.bg or (dark and 0x161b22 or 0xffffff)
  local function tint(color)
    local value = 0
    for _, shift in ipairs({ 16, 8, 0 }) do
      local power = 2 ^ shift
      local base, accent = math.floor(bg / power) % 256, math.floor(color / power) % 256
      value = value + math.floor(base * 0.86 + accent * 0.14) * power
    end
    return value
  end
  for name, attrs in pairs({
    DiffViewerAdd = { bg = tint(0x3fb950) },
    DiffViewerDelete = { bg = tint(0xf85149) },
    DiffViewerAddSign = { fg = dark and 0x7ee787 or 0x1a7f37, bold = true },
    DiffViewerDeleteSign = { fg = dark and 0xff7b72 or 0xcf222e, bold = true },
    DiffViewerHeader = { link = 'Title' },
    DiffViewerHunk = { link = 'DiffChange' },
    DiffViewerGutter = { link = 'LineNr' },
    DiffViewerMuted = { link = 'Comment' },
  }) do
    attrs.default = true
    api.nvim_set_hl(0, name, attrs)
  end
end

M.highlights()
api.nvim_create_autocmd('ColorScheme', { callback = M.highlights })

function M.prepare(file)
  local rows, mapping, gutters, highlights = {}, {}, {}, {}
  local added, deleted = 0, 0
  local old, new
  local function append(text, raw, left, right, hl)
    rows[#rows + 1], mapping[#rows + 1] = text, raw
    gutters[#rows] = { left, right }
    highlights[#rows] = hl or false
  end
  append(file.path:gsub('[\r\n\t]', ' '), 1, '', '', 'DiffViewerHeader')
  append('', 1, '', '')
  for raw, text in ipairs(file.lines) do
    local left, right = text:match('^@@ %-(%d+)[^ ]* %+(%d+)[^ ]* @@')
    if left then
      old, new = tonumber(left), tonumber(right)
      append(text, raw, '', '', 'DiffViewerHunk')
    elseif old then
      local sign = text:sub(1, 1)
      if sign == '+' then
        added = added + 1
        append(text:sub(2), raw, '', new, 'DiffViewerAdd')
        new = new + 1
      elseif sign == '-' then
        deleted = deleted + 1
        append(text:sub(2), raw, old, '', 'DiffViewerDelete')
        old = old + 1
      elseif sign == ' ' then
        append(text:sub(2), raw, old, new)
        old, new = old + 1, new + 1
      elseif text:match('^\\') then
        append(text, raw, '', '', 'DiffViewerMuted')
      end
    elseif text:match('^Binary files') or text:match('^GIT binary patch')
      or text:match('^rename ') or text:match('^old mode') or text:match('^new mode')
      or text:match('^similarity index') then
      append(text, raw, '', '', 'DiffViewerMuted')
    end
  end
  rows[1] = rows[1] .. string.format('    +%d −%d', added, deleted)
  if #rows == 2 then append('No textual changes', 1, '', '', 'DiffViewerMuted') end
  local width = 3
  for _, numbers in ipairs(gutters) do
    width = math.max(width, #tostring(numbers[1]), #tostring(numbers[2]))
  end
  return { lines = rows, raw = mapping, gutters = gutters, highlights = highlights, width = width }
end

function M.draw(buf, file)
  local result = M.prepare(file)
  api.nvim_buf_clear_namespace(buf, M.ns, 0, -1)
  vim.bo[buf].modifiable = true
  api.nvim_buf_set_lines(buf, 0, -1, false, result.lines)
  vim.bo[buf].modifiable = false
  vim.b[buf].diff_gutters = result.gutters
  vim.b[buf].diff_gutter_width = result.width
  vim.b[buf].diff_line_highlights = result.highlights
  local ft = vim.filetype.match({ filename = file.path, buf = buf }) or 'text'
  pcall(vim.treesitter.stop, buf)
  vim.bo[buf].filetype = ft
  vim.bo[buf].syntax = ft
  -- Use installed parsers where available, with ordinary Vim syntax as fallback.
  if ft ~= 'text' then pcall(vim.treesitter.start, buf) end
  for row, hl in ipairs(result.highlights) do
    if hl then
      api.nvim_buf_set_extmark(buf, M.ns, row - 1, 0, {
        end_row = row, end_col = 0, hl_group = hl, hl_eol = true,
        hl_mode = 'combine', priority = 110,
      })
    end
  end
  return result.raw
end

function M.gutter()
  local buf = api.nvim_win_get_buf(tonumber(vim.g.statusline_winid) or api.nvim_get_current_win())
  local numbers = (vim.b[buf].diff_gutters or {})[vim.v.lnum] or { '', '' }
  local width = vim.b[buf].diff_gutter_width or 3
  local hl = (vim.b[buf].diff_line_highlights or {})[vim.v.lnum]
  local sign = hl == 'DiffViewerAdd' and '%#DiffViewerAddSign#+ ' or (hl == 'DiffViewerDelete' and '%#DiffViewerDeleteSign#− ' or '  ')
  return '%#DiffViewerGutter#' .. string.format(' %' .. width .. 's %' .. width .. 's │ ', numbers[1], numbers[2]) .. sign .. '%*'
end

function M.panel(buf, row_files, files)
  api.nvim_buf_clear_namespace(buf, M.ns, 0, -1)
  for row, index in pairs(row_files) do
    local status = files[index].status
    local hl = status == 'D' and 'DiffViewerDeleteSign' or ((status == 'A' or status == '?') and 'DiffViewerAddSign' or 'DiffViewerHeader')
    api.nvim_buf_set_extmark(buf, M.ns, row - 1, 0, { end_col = 1, hl_group = hl })
  end
end

return M
