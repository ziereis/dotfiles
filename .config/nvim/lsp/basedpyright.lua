return {
  cmd = { "basedpyright-langserver", "--stdio" },
  filetypes = { "python" },
  root_markers = { "pyproject.toml", "setup.py", "requirements.txt" },
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
