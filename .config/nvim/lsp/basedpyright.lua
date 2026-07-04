return {
  cmd = { "basedpyright-langserver", "--stdio" },
  filetypes = { "python" },
  root_markers = {
    "pyrightconfig.json",
    "pyproject.toml",
    "setup.py",
    "setup.cfg",
    "requirements.txt",
    ".python-version",
    ".venv",
    "venv",
    ".git",
  },
  settings = {
    basedpyright = {
      usePyprojectToml = true,
    },
    python = {
      analysis = {
        typeCheckingMode = "basic",
        autoSearchPaths = true,
        diagnosticMode = "openFilesOnly",
        useLibraryCodeForTypes = true,
        exclude = {
          "**/.venv",
          "**/venv",
          "**/.env",
          "**/env",
          "**/node_modules",
          "**/__pycache__",
          "**/.git",
          "**/build",
          "**/dist",
          "**/*.egg-info",
        },
      },
    },
  },
}
