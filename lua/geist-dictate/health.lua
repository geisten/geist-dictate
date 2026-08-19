-- :checkhealth geist-dictate
local M = {}

function M.check()
    local health = vim.health
    health.start("geist-dictate")

    local dictate = require("geist-dictate")
    -- Reach into the configured values via a throwaway pipeline string.
    local binary = vim.fn.exepath("dictate")
    if binary ~= "" then
        health.ok("dictate binary: " .. binary)
    else
        health.warn("dictate not on PATH — set setup({ binary = ... }) or install the .deb")
    end

    if vim.fn.executable("arecord") == 1 then
        health.ok("arecord found")
    else
        health.error("arecord missing (apt install alsa-utils)")
    end

    local model = (os.getenv("XDG_DATA_HOME") or (os.getenv("HOME") .. "/.local/share"))
        .. "/geist-dictate/gemma4-e2b-Q4_K_M.gguf"
    if vim.fn.filereadable(model) == 1 then
        health.ok("model: " .. model)
    else
        health.warn("model missing — run: geist-dictate setup (or set setup({ model = ... }))")
    end

    if dictate.is_active() then
        health.info("currently listening")
    end
end

return M
