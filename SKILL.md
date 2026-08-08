---
name: windirstat-cli-skill
description: Operate WinDirStat from PowerShell on Windows to locate the installed executable, scan one or more folders, silently export disk-usage results, duplicate-file reports, or permission reports as CSV/JSON, load saved reports in the GUI, validate exit codes, and troubleshoot PATH or permissions. Use when a user mentions WinDirStat command-line use, scripted disk scans, scheduled disk-usage snapshots, WinDirStat CSV/JSON export, duplicate reports, permission reports, or loading saved WinDirStat scans.
---

# WinDirStat CLI

Use WinDirStat as a GUI scanner or as a quiet scan-to-file worker. Prefer the bundled wrapper for deterministic quoting, validation, executable discovery, and exit-code handling.

## Workflow

1. Confirm Windows and locate `WinDirStat.exe` with `Get-Command WinDirStat.exe`, then fall back to `C:\Program Files\WinDirStat\WinDirStat.exe`.
2. Read `references/cli-reference.md` when choosing a mode, output format, or troubleshooting a failure.
3. Resolve the requested scan roots exactly. Do not broaden a path such as a project folder to an entire drive without explicit user approval.
4. Use `scripts/Invoke-WinDirStat.ps1` for scanning, exporting, duplicate reports, permission reports, or loading a saved report.
5. For quiet exports, check both the process exit code and output-file existence before reporting success.
6. Report whether the operation merely started a GUI scan or completed a quiet export.

## Run the wrapper

Set the skill directory and invoke the script:

```powershell
$skill = 'C:\path\to\windirstat-cli-skill'

& "$skill\scripts\Invoke-WinDirStat.ps1" `
  -Mode Export `
  -Path 'C:\Users' `
  -OutputPath 'D:\Reports\users-disk-usage.json'
```

Supported modes:

- `Scan`: open the GUI and scan one or more existing directories.
- `Export`: quietly scan and save the complete result.
- `Duplicates`: quietly scan and save duplicate-file results.
- `Permissions`: quietly scan and save permission entries.
- `Load`: open a previously saved WinDirStat CSV or JSON report in the GUI.

Use `.json` for JSON. Use `.csv` for CSV. The wrapper rejects other output extensions to avoid WinDirStat silently treating them as CSV.

## Safety boundaries

- Treat scanning as read-intensive: warn before scanning an entire large drive, network share, or latency-sensitive path.
- Do not request elevation by default. Use `-Elevated` only when the user authorizes it and inaccessible paths require it.
- Do not overwrite an existing report unless the user authorizes replacement and `-Force` is supplied.
- Never invoke WinDirStat's internal `/legacyuninstall` switch. It is destructive maintenance behavior, not a scan feature.
- Do not claim that `Scan` or `Load` completed; those modes only start the GUI. Quiet export modes wait and return a verified result.
- Do not present WinDirStat as a stdout-oriented CLI. Its automation model is scan, save CSV/JSON, then analyze that file with PowerShell or another tool.

## Direct commands

Use direct commands only when the wrapper is unavailable:

```powershell
WinDirStat.exe 'D:\Data'
WinDirStat.exe /saveto 'D:\Reports\usage.json' 'D:\Data'
WinDirStat.exe /savedupesto 'D:\Reports\duplicates.csv' 'D:\Data'
WinDirStat.exe /savepermsto 'D:\Reports\permissions.json' 'D:\Shared'
WinDirStat.exe /loadfrom 'D:\Reports\usage.json'
```

Quote every path containing spaces. Do not combine `/loadfrom` with scan-root arguments.
