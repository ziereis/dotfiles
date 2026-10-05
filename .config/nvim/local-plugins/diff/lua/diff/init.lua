local M = {}
local source = require('diff.source')
local config = { panel_width = 36 }

function M.setup(opts)
  config = vim.tbl_extend('force', config, opts or {})
end

local function error_message(err)
  vim.notify('diff: ' .. err, vim.log.levels.ERROR)
end

local function display(title, current_branch, root)
  return function(patch, err)
    if not patch then error_message(err); return end
    require('diff.view').open(source.parse(patch), title, config.panel_width, { branch = current_branch, root = root })
  end
end

local function with_root(fn)
  source.root(function(root, err)
    if not root then error_message(err); return end
    source.run({ 'git', 'branch', '--show-current' }, root, function(out, brancherr)
      if not out then error_message(brancherr); return end
      local name = vim.trim(out)
      if name ~= '' then
        fn(root, name)
      else
        source.run({ 'git', 'rev-parse', '--short', 'HEAD' }, root, function(sha, failure)
          if not sha then error_message(failure); return end
          fn(root, 'detached HEAD at ' .. vim.trim(sha))
        end)
      end
    end)
  end)
end

-- No argument: separate unstaged, staged, and untracked changes.
-- One revision: that commit versus its first parent. Two: compare snapshots.
function M.open(target, other)
  with_root(function(root, current_branch)
    local pr = type(target) == 'string' and target:match('^pr%-(%d+)$')
    if pr then
      source.run({ 'gh', 'pr', 'diff', pr, '--color=never' }, root, display('PR #' .. pr, current_branch, root))
    elseif other then
      source.diff(root, { target, other }, display(target .. '..' .. other .. ' (snapshots)', current_branch, root))
    elseif target then
      source.run({ 'git', 'show', '--format=', '--no-ext-diff', '--no-textconv', '--no-color', '--find-renames', target, '--' }, root, display('Commit ' .. target, current_branch, root))
    else
      source.working(root, function(files, err)
        if not files then error_message(err); return end
        require('diff.view').open(files, 'Working tree', config.panel_width, {
          branch = current_branch, root = root, working = true,
          reload = function(callback) source.working(root, callback) end,
        })
      end)
    end
  end)
end

local function select_pair(commits, callback)
  local function pick(prompt, cb)
    vim.ui.select(commits, { prompt = prompt, format_item = function(item) return item.label end }, cb)
  end
  pick('Diff: select OLD commit', function(old)
    if not old then return end
    pick('Diff: select NEW commit (from ' .. old.sha:sub(1, 8) .. ')', function(new)
      if new then callback(old, new) end
    end)
  end)
end

function M.compare()
  with_root(function(root, current_branch)
    source.run({ 'git', 'log', '--all', 'HEAD', '--date=short', '--format=%H %ad %s', '--' }, root, function(log, err)
      if not log then error_message(err); return end
      local commits = {}
      for line in log:gmatch('[^\n]+') do
        local sha, text = line:match('^(%x+) (.*)$')
        if sha then commits[#commits + 1] = { sha = sha, label = sha:sub(1, 8) .. ' ' .. text } end
      end
      if #commits == 0 then vim.notify('No commits found', vim.log.levels.INFO); return end
      select_pair(commits, function(old, new)
        source.diff(root, { old.sha, new.sha }, display(old.sha:sub(1, 8) .. '..' .. new.sha:sub(1, 8) .. ' (snapshots)', current_branch, root))
      end)
    end)
  end)
end

function M.history(path)
  with_root(function(root, current_branch)
    local relative
    if path then
      local normalized = vim.fs.normalize(vim.uv.fs_realpath(path) or path)
      local prefix = vim.fs.normalize(root) .. '/'
      if normalized:sub(1, #prefix) ~= prefix then error_message('File is outside the current repository'); return end
      relative = normalized:sub(#prefix + 1)
    end
    local args = { 'git', '--literal-pathspecs', 'log', '-n', '200', '--format=%H %s', '--' }
    if relative then args[#args + 1] = relative end
    source.run(args, root, function(log, err)
      if not log then error_message(err); return end
      local commits = {}
      for line in log:gmatch('[^\n]+') do
        local sha, subject = line:match('^(%x+) (.*)$')
        if sha then commits[#commits + 1] = {
          sha = sha, label = sha:sub(1, 8) .. ' ' .. subject,
          title = 'Commit ' .. sha:sub(1, 8) .. (relative and (' · ' .. relative) or '') .. ' — ' .. subject,
        } end
      end
      if #commits == 0 then vim.notify('No commits found', vim.log.levels.INFO); return end
      local function load(choice, callback)
        local show = { 'git', '--literal-pathspecs', 'show', '--format=', '--no-ext-diff', '--no-textconv', '--no-color', '--find-renames', choice.sha, '--' }
        if relative then show[#show + 1] = relative end
        source.run(show, root, callback)
      end
      load(commits[1], function(patch, failure)
        if not patch then error_message(failure); return end
        require('diff.view').open(source.parse(patch), commits[1].title, config.panel_width, {
          root = root, branch = current_branch, commits = commits, commit_count = #commits, load = load,
          compare = function(callback)
            select_pair(commits, function(old, new)
              source.diff(root, { old.sha, new.sha }, function(result, failure)
                callback(result, failure, old.sha:sub(1, 8) .. '..' .. new.sha:sub(1, 8) .. ' (snapshots)')
              end, relative and { relative } or nil)
            end)
          end,
        })
      end)
    end)
  end)
end

function M.branch(branch, base)
  branch, base = branch or 'HEAD', base or 'main'
  with_root(function(root, current_branch)
    source.run({ 'git', 'merge-base', base, branch }, root, function(out, err)
      if not out then error_message(err); return end
      local merge_base = vim.trim(out)
      local range = merge_base .. '..' .. branch
      source.run({ 'git', 'log', '--format=%H %s', range, '--' }, root, function(log, logerr)
        if not log then error_message(logerr); return end
        local commits = {}
        for line in log:gmatch('[^\n]+') do
          local sha, subject = line:match('^(%x+) (.*)$')
          if sha then commits[#commits + 1] = {
            sha = sha,
            label = sha:sub(1, 8) .. ' ' .. subject,
            title = 'Commit ' .. sha:sub(1, 8) .. ' — ' .. subject,
          } end
        end
        local comparison = base .. '...' .. branch .. ' (since merge base)'
        local choices = { { label = 'All branch changes', title = comparison, kind = 'all' } }
        vim.list_extend(choices, commits)
        source.diff(root, { merge_base, branch }, function(patch, failure)
          if not patch then error_message(failure); return end
          require('diff.view').open(source.parse(patch), comparison, config.panel_width, {
            branch = current_branch,
            root = root,
            commits = choices,
            load = function(choice, callback)
              if choice.kind == 'all' then
                source.diff(root, { merge_base, branch }, callback)
              else
                source.run({ 'git', 'show', '--format=', '--no-ext-diff', '--no-textconv', '--no-color', '--find-renames', choice.sha, '--' }, root, callback)
              end
            end,
            compare = function(callback)
              local endpoints = { { sha = merge_base, label = 'Merge base (' .. merge_base:sub(1, 8) .. ')' } }
              vim.list_extend(endpoints, commits)
              local function pick(prompt, cb)
                vim.ui.select(endpoints, { prompt = prompt, format_item = function(item) return item.label end }, cb)
              end
              pick('Select OLD snapshot', function(old)
                if old then pick('Select NEW snapshot', function(new)
                  if new then
                    source.diff(root, { old.sha, new.sha }, function(result, err)
                      callback(result, err, old.sha:sub(1, 8) .. '..' .. new.sha:sub(1, 8) .. ' (snapshots)')
                    end)
                  end
                end) end
              end)
            end,
          })
        end)
      end)
    end)
  end)
end

return M
