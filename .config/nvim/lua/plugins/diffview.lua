-- Trunk lookup mirrors what `gt` calls the trunk without shelling out to it:
-- `gt trunk` initializes Graphite in repos that never opted in, which litters
-- .git/ with metadata. origin/HEAD is the same answer in every repo that has it.
---@param root string
---@return string? branch usable as a review base
local function trunk(root)
  local ref = vim.system({ "git", "-C", root, "symbolic-ref", "refs/remotes/origin/HEAD" }, { text = true }):wait()
  if ref.code == 0 then
    return (vim.trim(ref.stdout):gsub("^refs/remotes/", ""))
  end

  for _, candidate in ipairs({ "origin/main", "origin/master", "main", "master" }) do
    local exists = vim.system({ "git", "-C", root, "rev-parse", "--verify", "--quiet", candidate .. "^{commit}" })
      :wait()
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

-- `<base>...HEAD` is the review diff (merge base, so trunk commits landed after
-- the branch started stay out of it). --imply-local swaps the right side from
-- HEAD blobs to the worktree files, so uncommitted edits show up and are
-- editable in place instead of being read-only copies of HEAD.
---@param base string
local function review(base)
  vim.cmd("DiffviewOpen " .. base .. "...HEAD --imply-local")
end

local function review_trunk()
  local root = repo_root()
  local base = trunk(root)
  if not base then
    vim.notify("could not resolve trunk (no origin/HEAD, main, or master)", vim.log.levels.WARN)
    return
  end
  review(base)
end

-- Graphite keeps stack parents in .git/.graphite_metadata.db (SQLite), so the
-- CLI is the only supported way to resolve the branch directly downstack.
local function review_downstack()
  local result = vim.system({ "gt", "parent" }, { cwd = repo_root(), text = true }):wait()
  if result.code ~= 0 then
    vim.notify("gt parent: " .. vim.trim(result.stderr or "no downstack branch"), vim.log.levels.WARN)
    return
  end
  review(vim.trim(result.stdout))
end

return {
  "sindrets/diffview.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  cmd = { "DiffviewOpen", "DiffviewFileHistory" },
  keys = {
    { "<leader>gr", review_trunk, desc = "[G]it [R]eview (vs trunk)" },
    { "<leader>gd", review_downstack, desc = "[G]it [D]ownstack review" },
    { "<leader>gD", "<cmd>DiffviewOpen<cr>", desc = "[G]it [D]iffview (working tree)" },
    { "<leader>gq", "<cmd>DiffviewClose<cr>", desc = "[G]it diffview [Q]uit" },
    { "<leader>gh", "<cmd>DiffviewFileHistory %<cr>", desc = "[G]it file [H]istory" },
    { "<leader>gH", "<cmd>DiffviewFileHistory<cr>", desc = "[G]it repo [H]istory" },
  },
  opts = {
    enhanced_diff_hl = true,
    keymaps = {
      view = { { "n", "R", "<cmd>DiffviewRefresh<cr>", { desc = "Refresh" } } },
      file_panel = { { "n", "R", "<cmd>DiffviewRefresh<cr>", { desc = "Refresh" } } },
      file_history_panel = { { "n", "R", "<cmd>DiffviewRefresh<cr>", { desc = "Refresh" } } },
    },
  },
}
