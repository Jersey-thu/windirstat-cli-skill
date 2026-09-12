# windirstat-cli-skill

An agent skill that lets coding agents (Codex, Claude Code, ZCode, ...) operate [WinDirStat](https://github.com/windirstat/windirstat) from PowerShell on Windows: scripted disk scans, quiet CSV/JSON exports, duplicate-file reports, permission reports, and loading saved reports back into the GUI.

Behavior documented here was verified against WinDirStat 2.8.0.

## What it does

| Mode | Behavior |
|------|----------|
| `Scan` | Open the WinDirStat GUI and scan one or more directories. |
| `Export` | Quietly scan and save the complete result as CSV or JSON. |
| `Duplicates` | Quietly scan and save a duplicate-file report. |
| `Permissions` | Quietly scan and save a permission report. |
| `Load` | Open a saved WinDirStat CSV/JSON report in the GUI. |

The bundled wrapper `scripts/Invoke-WinDirStat.ps1` handles executable discovery, path quoting, output-extension validation, and exit-code/output verification, so agents do not have to guess at WinDirStat's automation model. `references/cli-reference.md` documents the full behavior model.

## Requirements

- Windows with PowerShell.
- [WinDirStat](https://windirstat.net) 2.x installed. The `/saveto`, `/savedupesto`, `/savepermsto`, and `/loadfrom` switches are 2.x features.

## Install

### With the skills CLI (recommended)

```bash
npx skills add Jersey-thu/windirstat-cli-skill -g -a codex -y
```

`-a` accepts any supported agent (`claude-code`, `codex`, `zcode`, `opencode`, ...); repeat the flag to target several agents at once. Omit `-g` to install into the current project instead of the user directory.

### With git

```bash
git clone https://github.com/Jersey-thu/windirstat-cli-skill.git ~/.codex/skills/windirstat-cli-skill
```

Point the target directory at whichever skills folder your agent reads (`~/.claude/skills/`, `~/.zcode/skills/`, `~/.agents/skills/`, ...).

## Usage

Ask your agent in natural language, for example: *"Export a duplicate-file report for D:\Photos as CSV."* Or call the wrapper directly:

```powershell
& "$env:USERPROFILE\.codex\skills\windirstat-cli-skill\scripts\Invoke-WinDirStat.ps1" `
  -Mode Export `
  -Path 'C:\Users' `
  -OutputPath 'D:\Reports\users-disk-usage.json'
```

The output format follows the file extension: `.json` produces JSON; WinDirStat treats every other extension as CSV, so the wrapper rejects anything that is not `.json` or `.csv`.

## Safety boundaries

The skill instructs agents to:

- Treat scanning as read-intensive: warn before scanning an entire large drive, network share, or latency-sensitive path, and never broaden a scan root without explicit approval.
- Not request elevation unless the user authorizes it.
- Not overwrite an existing report without `-Force` and user authorization.
- Never invoke WinDirStat's internal `/legacyuninstall` switch.
- Report `Scan` and `Load` as "GUI started", not "completed"; only quiet exports produce a verified result.

## Notes on WinDirStat's CLI

- Quiet exports return exit code `0` on success and `1` on malformed arguments, invalid roots, or save failures. Verify the output file even after exit code `0`.
- WinDirStat is not a stdout-oriented CLI. The automation model is: scan, save CSV/JSON, then analyze the file with PowerShell, Python, DuckDB, or a spreadsheet.
- `--help` and `/?` do not produce console help; see `references/cli-reference.md` instead.

## Related

- [WinDirStat](https://github.com/windirstat/windirstat) — the underlying disk-usage analyzer and its source code.
- [skills.sh](https://skills.sh) — the open agent skills CLI used for installation.
