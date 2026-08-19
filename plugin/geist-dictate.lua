-- :Dictate — toggle dictation at the cursor.
if vim.g.loaded_geist_dictate then
    return
end
vim.g.loaded_geist_dictate = true

vim.api.nvim_create_user_command("Dictate", function()
    require("geist-dictate").toggle()
end, { desc = "Toggle geist-dictate speech input" })
