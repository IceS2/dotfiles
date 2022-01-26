local present, lualine = pcall(require, "lualine")
if not present then
  return
end

lualine.setup {
  options = {
    theme = "auto",
    disabled_filetypes = {
      "toggleterm",
      "NvimTree",
      "vista_kind",
      "dapui_scopes",
      "dapui_breakpoints",
      "dapui_stacks",
      "dapui_watches",
      "dap-repl"
    },

    section_separators = { left = " ", right = " " },
    component_separators = { left = "│", right = "│" },
  },
  extensions = { "fugitive" },
}
