local present, telescope = pcall(require, "telescope")
if not present then
    return
end

telescope.setup {
  extensions = {
    fzf = {
      fuzzy = true,
      override_generic_sorter = true,
      override_file_sorter = true,
      case_mode = "smart_case",
    },
  }
}
telescope.load_extension("fzf")
telescope.load_extension("projects")
telescope.load_extension("neoclip")
telescope.load_extension("aerial")
telescope.load_extension("dap")
