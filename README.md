# geist-dictate

System-wide **local** dictation for Linux — one static binary on the
[geist](https://github.com/geisten/geistlib) engine. No cloud, no Python
stack, no Whisper pipeline: Gemma 4 E2B hears directly (measured on this
engine: **4.2 % WER English** / **7.1 % German**, LibriSpeech / FLEURS —
methodology in geistlib's `benchmark/results/PI5-audio.md`).

A streaming energy VAD segments your speech while you talk; each
utterance becomes one line of clean, punctuated text on stdout. Typing
into the focused window is composition, not configuration:

```sh
arecord -f S16_LE -r 16000 -c 1 -t raw | ./dictate model.gguf | wtype -   # wlroots
arecord ... | ./dictate model.gguf | while IFS= read -r l; do ydotool type -- "$l "; done  # GNOME
```

## Build & run

```sh
git clone --recurse-submodules https://github.com/geisten/geist-dictate
cd geist-dictate
make                    # builds dictate against the pinned geistlib
make setup              # model (~3.1 GB) + audio tower (~590 MB), SHA-pinned
bin/geist-dictate run   # mic → transcript lines on stdout
```

Needs ~4 GB RAM (Gemma 4 E2B Q4_K_M); runs on any x86-64 desktop and on
a Raspberry Pi 5. `GEIST_DICTATE_PROMPT` overrides the transcription
instruction; the default handles English and German without
configuration.

## Status / roadmap

- [x] dictation core (`dictate`, from geistlib's example) — #1
- [ ] `.deb` package: two-command install, hotkey toggle, ydotool wiring — #2
- [ ] IBus engine: dictation as an input source in every app, no root — #3
- [ ] Neovim plugin: `:Dictate`, mode-aware insertion via job-control — #4

Working name `geist-dictate`; product-name candidate: `geistschreiber`.

## License

Apache-2.0, same as the engine.
