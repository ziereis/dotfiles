local function trunk(root)
  local ref = vim.system({ "git", "-C", root, "symbolic-ref", "refs/remotes/origin/HEAD" }, { text = true }):wait()
  if ref.code == 0 then
    return (vim.trim(ref.stdout):gsub("^refs/remotes/", ""))
  end

  for _, candidate in ipairs({ "origin/main", "origin/master", "main", "master" }) do
    local exists =
      vim.system({ "git", "-C", root, "rev-parse", "--verify", "--quiet", candidate .. "^{commit}" }):wait()
    if exists.code == 0 then
      return candidate
    end
  end
  return nil
end

---@return string repository root of the current buffer
local function repo_root()
  return vim.fs.root(0, ".git") or vim.uv.cwd()
end

local function review(base)
  require("diff").branch("HEAD", base)
end

local function review_trunk()
  local base = trunk(repo_root())
  if not base then
    vim.notify("Could not resolve trunk (no origin/HEAD, main, or master)", vim.log.levels.WARN)
    return
  end
  review(base)
end

local function review_downstack()
  vim.system({ "gt", "parent" }, { cwd = repo_root(), text = true }, function(result)
    vim.schedule(function()
      if result.code ~= 0 then
        vim.notify("gt parent: " .. vim.trim(result.stderr or ""), vim.log.levels.WARN)
        return
      end
      review(vim.trim(result.stdout))
    end)
  end)
end

return {
  dir = vim.fn.stdpath("config") .. "/local-plugins/diff",
  name = "diff",
  lazy = false,
  dependencies = { "barrettruth/diffs.nvim" },
  opts = { panel_width = 40 },
  keys = {
    { "<leader>gr", review_trunk, desc = "Git: review vs trunk" },
    { "<leader>gD", review_downstack, desc = "Git: downstack review" },
    { "<leader>gd", function() require("diff").open() end, desc = "Git: working-tree diff" },
    { "<leader>gC", function() require("diff").open("HEAD") end, desc = "Git: latest commit review" },
    { "<leader>gq", function() require("diff.view").close() end, desc = "Git: close diff review" },
    { "<leader>gh", function()
      local path = vim.api.nvim_buf_get_name(0)
      if path == "" then vim.notify("Open a file to review its history", vim.log.levels.WARN); return end
      require("diff").history(path)
    end, desc = "Git: file history" },
    { "<leader>gH", function() require("diff").history() end, desc = "Git: repository history" },
  },
}
