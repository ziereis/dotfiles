local M = {}

local function unquote(path)
  if path:sub(1, 1) ~= '"' then return path end
  local escapes = { n = '\n', t = '\t', r = '\r', b = '\b', f = '\f', v = '\v', a = '\7' }
  return (path:sub(2, -2):gsub('\\(%d%d%d)', function(o) return string.char(tonumber(o, 8)) end)
    :gsub('\\(.)', function(c) return escapes[c] or c end))
end

function M.run(argv, cwd, callback)
  local ok, failure = pcall(vim.system, argv, { cwd = cwd, text = true }, function(result)
    vim.schedule(function()
      if result.code ~= 0 then
        callback(nil, vim.trim(result.stderr or '') ~= '' and vim.trim(result.stderr) or 'Command failed: ' .. table.concat(argv, ' '))
      else
        callback(result.stdout or '')
      end
    end)
  end)
  if not ok then vim.schedule(function() callback(nil, tostring(failure)) end) end
end

function M.root(callback)
  M.run({ 'git', 'rev-parse', '--show-toplevel' }, vim.fn.getcwd(), function(out, err)
    callback(out and vim.trim(out), err)
  end)
end

function M.diff(root, refs, callback, paths)
  local args = { 'git', '--literal-pathspecs', 'diff', '--no-ext-diff', '--no-textconv', '--no-color', '--find-renames' }
  vim.list_extend(args, refs)
  args[#args + 1] = '--'
  vim.list_extend(args, paths or {})
  M.run(args, root, callback)
end

-- Metadata is only valid before hunks; code can itself start with --- or +++.
function M.parse(patch)
  local files, current, body = {}, nil, false
  for line in (patch .. '\n'):gmatch('(.-)\n') do
    if line:match('^diff %-%-git ') then
      current = { path = line:match(' b/(.*)$') or line:sub(12), status = 'M', lines = {} }
      body = false
      files[#files + 1] = current
    end
    if current then
      if line:match('^@@') or line == 'GIT binary patch' then body = true end
      if not body then
        if line:match('^new file mode') then current.status = 'A' end
        if line:match('^deleted file mode') then current.status = 'D' end
        if line:match('^%+%+%+ ') and line ~= '+++ /dev/null' then
          current.path = unquote(line:sub(5)):gsub('^b/', '')
        elseif line:match('^%-%-%- ') and current.status == 'D' then
          current.path = unquote(line:sub(5)):gsub('^a/', '')
        elseif line:match('^rename from ') then
          current.old_path = unquote(line:sub(13))
        elseif line:match('^rename to ') then
          current.status, current.path = 'R', unquote(line:sub(11))
        end
      end
      current.lines[#current.lines + 1] = line
    end
  end
  return files
end

-- Map unified patch lines to the new file. Deleted lines use the next surviving line.
function M.line(file, row)
  local nextline
  for index, text in ipairs(file.lines) do
    local start = text:match('^@@ .* %+(%d+)')
    if start then nextline = tonumber(start)
    elseif nextline and (text:sub(1, 1) == ' ' or text:sub(1, 1) == '+') then
      if index == row then return math.max(1, nextline) end
      nextline = nextline + 1
    end
    if index == row then return math.max(1, nextline or 1) end
  end
  return 1
end

function M.working(root, callback)
  M.diff(root, {}, function(unstaged, err)
    if not unstaged then callback(nil, err); return end
    M.diff(root, { '--cached' }, function(staged, failure)
      if not staged then callback(nil, failure); return end
      local files = {}
      for _, group in ipairs({ { 'Unstaged', unstaged }, { 'Staged', staged } }) do
        for _, file in ipairs(M.parse(group[2])) do
          file.section = group[1]
          files[#files + 1] = file
        end
      end
      M.run({ 'git', 'ls-files', '--others', '--exclude-standard', '-z' }, root, function(names, list_error)
        if not names then callback(nil, list_error); return end
        local paths = {}
        for path in names:gmatch('([^%z]+)%z') do paths[#paths + 1] = path end
        local function next_file(index)
          local path = paths[index]
          if not path then callback(files); return end
          vim.system({ 'git', 'diff', '--no-index', '--no-color', '--', '/dev/null', root .. '/' .. path }, { cwd = root, text = true }, function(result)
            vim.schedule(function()
              if result.code > 1 then callback(nil, result.stderr); return end
              local parsed = M.parse(result.stdout or '')
              files[#files + 1] = { path = path, status = '?', section = 'Untracked', lines = parsed[1] and parsed[1].lines or { 'Empty file' } }
              next_file(index + 1)
            end)
          end)
        end
        next_file(1)
      end)
    end)
  end)
end

function M.stage(root, file, unstage, callback)
  local args = unstage and { 'git', '--literal-pathspecs', 'restore', '--staged', '--' }
    or { 'git', '--literal-pathspecs', 'add', '--' }
  args[#args + 1] = file.path
  if file.old_path then args[#args + 1] = file.old_path end
  M.run(args, root, callback)
end

return M
