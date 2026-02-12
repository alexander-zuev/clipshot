# clipshot

WSL2 screenshot bridge. Take a screenshot with Win+Shift+S — it's instantly available at `~/.screenshots/latest.png`.

Built for CLI workflows where you need to reference screenshots (Claude Code, scripts, etc.) without leaving the terminal.

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/alexander-zuev/clipshot/main/install.sh | bash
clipshot start
```

Or clone the repo:

```bash
git clone https://github.com/alexander-zuev/clipshot.git
cd clipshot
./clipshot install
clipshot start
```

## Usage

```bash
clipshot status          # service state, file count, disk usage
clipshot latest          # print path to latest screenshot
clipshot clean 20        # keep 20 most recent, delete rest
clipshot logs            # follow service logs
clipshot stop            # stop the service
clipshot version         # print installed version
clipshot uninstall       # remove everything (keeps screenshots)
```

## How it works

A PowerShell clipboard listener runs on Windows and watches for image events via `WM_CLIPBOARDUPDATE`. When you take a screenshot, it saves the image as PNG and signals the WSL2 side over stdout. The bash daemon picks it up, updates a `latest.png` symlink, and auto-cleans old files.

Runs as a systemd user service — starts on boot, restarts on crash, logs to journal.

```
Win+Shift+S → clipboard → watcher.ps1 → stdout → clipshot → ~/.screenshots/latest.png
```

The clipboard listener is read-only — it never writes to the clipboard, so copy/paste works normally.

## Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `CLIPSHOT_MAX` | `50` | Max screenshots to keep |

## File locations

| File | Path |
|------|------|
| CLI | `~/.local/bin/clipshot` |
| Watcher | `~/.local/share/clipshot/watcher.ps1` |
| Service | `~/.config/systemd/user/clipshot.service` |
| Screenshots | `~/.screenshots/*.png` |
| Latest | `~/.screenshots/latest.png` (symlink) |

## Requirements

- WSL2 with systemd enabled (`/etc/wsl.conf` → `[boot] systemd=true`)
- PowerShell (ships with Windows)

## License

MIT
