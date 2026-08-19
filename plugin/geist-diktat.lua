-- :Diktat — toggle dictation at the cursor.
if vim.g.loaded_geist_diktat then
    return
end
vim.g.loaded_geist_diktat = true

vim.api.nvim_create_user_command("Diktat", function()
    require("geist-diktat").toggle()
end, { desc = "Toggle geist-diktat speech input" })
