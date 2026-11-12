# nvim-opener

Opens files in nvim inside the existing Ghostty window via AppleScript,
rather than spawning a new Ghostty instance.

Built with Platypus (wraps a shell script as a macOS .app) and duti
(sets file associations via CLI, scriptable from dotfiles).

## Dependencies

- [Platypus CLI](https://sveinbjorn.org/platypus) — install the CLI tool
  from Platypus.app → Platypus menu → Install Command Line Tool
- [duti](https://github.com/moretension/duti) — `brew install duti`
- nvim at `/opt/homebrew/bin/nvim`
- Ghostty at `/Applications/Ghostty.app`

## Install

```bash
bash install.sh
```

Builds `~/Applications/NvimOpener.app`, signs it, and registers file
associations. Safe to re-run.

## Adding file types

- **By UTI** — add a line to `nvim-opener.duti`, then re-run `install.sh`
- **By extension** — add the extension to the loop in `install.sh`, then re-run

## How it works

`nvim-opener.sh` uses Ghostty's AppleScript API (`new window with configuration`)
to open a new window in the running Ghostty instance with nvim as the command.
This avoids the two-instance problem caused by `open -n`.
