# diff.nvim

A GitHub-style unified diff viewer for Neovim 0.10+.
It opens a dedicated tab with changed files on the left and one read-only diff
buffer on the right. Added, deleted, modified, and renamed files have status labels.
The header above the diff shows the checked-out branch and active comparison: `main..HEAD`
for snapshots, `main...HEAD` for changes since the merge base, or the selected
commit / PR. It updates when switching commits and stays visible while scrolling.
Detached checkouts show `detached HEAD at <sha>` instead of a branch name.

The diff has separate old/new line-number gutters, file change counts, and
subtle green/red backgrounds for additions/deletions. Code keeps its language's
syntax colors; `+` / `−` markers live in the gutter. Git's patch metadata is
hidden, while binary, rename, and mode-change details remain visible.
Installed Tree-sitter parsers are used when available, with Vim syntax as fallback.
Because a unified diff contains fragments and both versions, multiline syntax
can be less accurate than in the complete source file.

Colors follow your theme. Customize `DiffViewerAdd` and `DiffViewerDelete` with
background-only highlights to retain syntax foreground colors:

```lua
vim.api.nvim_set_hl(0, 'DiffViewerAdd', { bg = '#183022' })
vim.api.nvim_set_hl(0, 'DiffViewerDelete', { bg = '#351d23' })
```

## Try it locally

With lazy.nvim, add this to your plugin specs:

```lua
{
  dir = vim.fn.stdpath('config') .. '/local-plugins/diff',
  name = 'diff.nvim',
  config = function()
    require('diff').setup({ panel_width = 36 })
  end,
}
```

Alternatively, run this from a Git repository:

```sh
nvim -c 'set rtp+=/Users/ziereis/dotfiles/.config/nvim/local-plugins/diff' -c 'runtime plugin/diff.lua'
```

This loads the plugin after your configuration, including plugin managers that
reset the runtime path. Restart Neovim after installing through lazy.nvim.

## Usage

The dotfiles configuration uses the former diffview shortcuts:

| Key | Review |
| --- | --- |
| `<leader>gr` | Current branch vs trunk (auto-detected) |
| `<leader>gD` | Current branch vs Graphite downstack parent |
| `<leader>gd` | Working tree: unstaged, staged, untracked |
| `<leader>gC` | Latest commit |
| `<leader>gq` | Close the current review |
| `<leader>gh` | Current file history |
| `<leader>gH` | Repository history |

History shows up to 200 commits reachable from HEAD. File history is limited
to the current path and does not follow renames. Branch reviews show committed
changes; use the working-tree view for uncommitted edits.

To select two commits, open `<leader>gH`, focus the commit list with `Tab`, and
press `c`. Select the old commit, then the new commit. In file history (`gh`)
the comparison is limited to that file. `:DiffCompare` opens the picker directly
and includes the full history reachable from local/remote refs and HEAD.
`Escape` cancels either selection without changing the review.

```vim
:Diff                     " Separate unstaged, staged, and untracked changes
:Diff pr-226              " GitHub PR in the current repository
:Diff abc123              " Changes introduced by a commit
:Diff main feature        " Compare two snapshots
:DiffBranch feature main  " Changes since merge base; browse branch commits
```

Equivalent Lua API:

```lua
require('diff').open('pr-226')
require('diff').open('main', 'feature')
require('diff').branch('feature', 'main')
```

`DiffBranch` defaults to `HEAD` and `main`. It opens a persistent commit panel
below the file list. Move over a commit to preview its changes, or select
"All branch changes" to restore the full branch diff. Press `c` in the commit
panel to choose two commit snapshots. Selecting two endpoints
compares their trees; it does not combine arbitrary noncontiguous commits.
Repositories using another default branch should pass that base explicitly.

Move the cursor over a file (`j` / `k` or arrow keys) to preview its diff
immediately. `Enter` in the files focuses the diff; `Escape` returns to files.
`Enter` in commits focuses the files for that commit. Press `Tab` to cycle
files → diff → commits (when present), `[h` / `]h` to navigate hunks, and `q`
to close the review tab.

## Edit and stage files

Unchanged sections use native Neovim folds, with three lines of context around
each change. `zo` opens a fold, `zc` closes it, `za` toggles it, `zR` opens all
folds, and `zM` closes all folds. `[h` / `]h` still jump between change blocks.
Full context loads asynchronously for the selected file only, with a cache of
up to eight files. Staged and historical reviews read the reviewed Git blob;
working-tree context reads saved disk contents. PR context reads the selected
file at the PR's head commit through GitHub CLI. If context is unavailable,
the original patch remains visible.

In `:Diff`, files are grouped into **Unstaged** (index → disk), **Staged**
(HEAD → index), and **Untracked**. A file with both staged and unstaged edits
appears in both groups, with a separate preview for each.

- `e` in the diff: open the current checkout's file in an editing tab at the
  corresponding new-file line. Deleted lines jump to the next surviving line.
  `e` also works from the file list.
- Save with `:w`, then `<leader>db` returns to the review and refreshes the
  working-tree diff. Unsaved buffers stay open in their editing tab.
- `s`: stage the selected **whole file**, including additions or deletions.
- `u`: unstage the selected staged **whole file**, preserving disk contents.
- `r`: refresh changes made outside the viewer.

Staging reads saved disk contents; save modified buffers first. Stage/unstage
actions are available only in the working-tree view. Hunk and line staging
are not implemented yet. Editing from a commit, branch, or PR review opens
the current checkout, so line positions may differ from historical versions.
Files absent from the checkout cannot be opened for editing.

PRs require GitHub CLI (`gh`) installed and authenticated with `gh auth login`.
The plugin reads the PR diff without checking out or fetching its branch.
Local comparisons use existing Git refs. Commands run asynchronously.

## How the plugin works

Neovim loads `plugin/diff.lua` and registers the commands. Their implementations
live in `lua/diff/init.lua`, which is what `require('diff')` loads.
`source.lua` runs Git/GitHub CLI and splits patches into files; `view.lua` builds
scratch buffers, windows, and buffer-local mappings. `setup()` is configuration.
There are no third-party Lua dependencies.

Next steps: inline word highlights and file-tree grouping.
Hunk staging, editing patches, review comments, and merge conflict
resolution are not implemented. Binary changes display Git's metadata. Git-quoted
unusual paths are retained as labels. GitHub may limit very large PR diffs.
Single merge commits follow `git show` semantics and are not yet a dedicated
merge review workflow.

## Verify

```sh
nvim --headless -u NONE -l tests/smoke.lua
nvim --headless -u NONE -l tests/folds.lua
```

This creates a temporary Git repository and verifies additions, deletions,
renames, the two-pane view, snapshot comparison, and branch review.
