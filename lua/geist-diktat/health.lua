-- :checkhealth geist-diktat
local M = {}

function M.check()
    local health = vim.health
    health.start("geist-diktat")

    local diktat = require("geist-diktat")
    -- Reach into the configured values via a throwaway pipeline string.
    local binary = vim.fn.exepath("diktat")
    if binary ~= "" then
        health.ok("diktat binary: " .. binary)
    else
        health.warn("diktat not on PATH — set setup({ binary = ... }) or install the .deb")
    end

    if vim.fn.executable("arecord") == 1 then
        health.ok("arecord found")
    else
        health.error("arecord missing (apt install alsa-utils)")
    end

    local model = (os.getenv("XDG_DATA_HOME") or (os.getenv("HOME") .. "/.local/share"))
        .. "/geist-diktat/gemma4-e2b-Q4_K_M.gguf"
    if vim.fn.filereadable(model) == 1 then
        health.ok("model: " .. model)
    else
        health.warn("model missing — run: geist-diktat setup (or set setup({ model = ... }))")
    end

    if diktat.is_active() then
        health.info("currently listening")
    end
end

return M
