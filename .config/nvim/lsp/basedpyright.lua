local project_markers = {
  "pyrightconfig.json",
  "pyproject.toml",
  "setup.py",
  "setup.cfg",
  "requirements.txt",
  "Pipfile",
  ".python-version",
  ".venv",
  "venv",
}

local function python_in(environment)
  if not environment or environment == "" then
    return nil
  end
  local executable = vim.fs.joinpath(environment, "bin", "python")
  return vim.fn.executable(executable) == 1 and executable or nil
end

return {
  cmd = { "basedpyright-langserver", "--stdio" },
  filetypes = { "python" },
  root_dir = function(bufnr, on_dir)
    -- Use the nearest Python project, with a repository as the next fallback.
    local root = vim.fs.root(bufnr, { project_markers, ".git" })
    if not root then
      local filename = vim.api.nvim_buf_get_name(bufnr)
      local directory = filename ~= "" and vim.fs.dirname(filename) or vim.fn.getcwd()
      local cwd = vim.fn.getcwd()
      -- Keep loose scripts under the working directory together, but do not
      -- assign unrelated files to whichever directory Neovim was started in.
      root = (directory == cwd or vim.startswith(directory, cwd .. "/")) and cwd or directory
    end
    on_dir(root)
  end,
  before_init = function(_, config)
    local root = config.root_dir
    local python = root and (python_in(vim.fs.joinpath(root, ".venv")) or python_in(vim.fs.joinpath(root, "venv")))
      or python_in(vim.env.VIRTUAL_ENV)
      or python_in(vim.env.CONDA_PREFIX)
    if not python then
      for _, command in ipairs({ "python3", "python" }) do
        local executable = vim.fn.exepath(command)
        if executable ~= "" then
          python = executable
          break
        end
      end
    end
    config.settings = config.settings or {}
    config.settings.python = config.settings.python or {}
    if not config.settings.python.pythonPath and python then
      config.settings.python.pythonPath = python
    end
  end,
  settings = {
    basedpyright = {
      analysis = {
        typeCheckingMode = "basic",
        autoSearchPaths = true,
        diagnosticMode = "openFilesOnly",
      },
    },
  },
}
