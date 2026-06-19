local function find_iree_server()
  local cwd = vim.fn.getcwd()
  local paths = {
    cwd .. "/build/tools/iree-mlir-lsp-server",
    cwd .. "/bazel-bin/external/iree/tools/iree-mlir-lsp-server",
  }
  for _, path in ipairs(paths) do
    if vim.uv.fs_stat(path) then
      return path
    end
  end
  return "iree-mlir-lsp-server" -- fallback to $PATH
end

return {
  cmd = { find_iree_server() },
  filetypes = { "mlir" },
  root_markers = { ".git" },
  single_file_support = true,
}
