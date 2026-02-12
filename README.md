# clipshot

WSL2 screenshot bridge. Win+Shift+S → `~/.screenshots/latest.png`.

Event-driven clipboard listener (zero CPU when idle, instant detection). No polling, no clipboard interference, no Python dependencies.

## Install

```bash
git clone https://github.com/abzuev/clipshot.git
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
clipshot uninstall       # remove everything (keeps screenshots)
```

## How it works

Two components connected by a pipe:

1. **watcher.ps1** (Windows) — registers for `WM_CLIPBOARDUPDATE` events, saves clipboard images as PNG, prints filenames to stdout
2. **clipshot** (WSL2) — reads filenames, updates `latest.png` symlink, auto-cleans old files

Managed by systemd user service (auto-start, restart on crash, journal logs).

```
Win+Shift+S → Windows clipboard → watcher.ps1 → SAVED:filename → clipshot → ~/.screenshots/latest.png
```

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

- WSL2
- PowerShell (ships with Windows)
- systemd enabled in WSL (`/etc/wsl.conf` → `[boot] systemd=true`)

## License

MIT
