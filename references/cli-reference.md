# WinDirStat 2.8 command-line reference

This reference records behavior verified against WinDirStat 2.8.0. Recheck the installed version and release behavior after major upgrades.

## Locate and identify the executable

```powershell
$command = Get-Command WinDirStat.exe -ErrorAction SilentlyContinue
$exe = if ($command) { $command.Source } else { 'C:\Program Files\WinDirStat\WinDirStat.exe' }
(Get-Item -LiteralPath $exe).VersionInfo.ProductVersion
```

If the standard install directory is absent, inspect the uninstall registry entries before guessing another path.

## Modes and native syntax

| Operation | Syntax | Window behavior | Completion behavior |
|---|---|---|---|
| Scan folders | `WinDirStat.exe <folder> [folder...]` | GUI visible | Returns control after starting GUI |
| Export results | `WinDirStat.exe /saveto <output> <folder> [folder...]` | Hidden | Wait for scan, save, exit |
| Export duplicates | `WinDirStat.exe /savedupesto <output> <folder> [folder...]` | Hidden | Enable duplicate scan, save, exit |
| Export permissions | `WinDirStat.exe /savepermsto <output> <folder> [folder...]` | Hidden | Scan permissions, save, exit |
| Load saved results | `WinDirStat.exe /loadfrom <input>` | GUI visible | Load report and remain open |

Quiet export modes return `0` on success and `1` on malformed arguments, invalid roots, scan startup failure, or save failure. Verify the output file even after exit code `0`.

## Output formats

WinDirStat selects JSON only when the output path ends in `.json`, case-insensitively. Other names are handled as CSV. Prefer explicit `.json` or `.csv` extensions.

Complete result exports may contain name/path, file count, folder count, logical size, physical size, attributes, last-change time, WinDirStat attributes, index, and optionally owner. Duplicate reports contain hash, path, logical size, physical size, last-change time, and attributes. Permission reports contain path, account, allow/deny access, rights level, scope, access mask, and inheritance state.

## PATH setup

Add the default installation directory to the user-level PATH without using `setx`, which can mishandle long values in older environments:

```powershell
$target = 'C:\Program Files\WinDirStat'
$userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
$parts = @($userPath -split ';' | Where-Object { $_ })

if (-not ($parts | Where-Object { $_.TrimEnd('\') -ieq $target.TrimEnd('\') })) {
    [Environment]::SetEnvironmentVariable(
        'Path',
        (@($parts) + $target) -join ';',
        'User'
    )
}
```

Open a new terminal before expecting the persistent PATH change to appear. Confirm with:

```powershell
Get-Command WinDirStat.exe
```

## Troubleshooting

- `WinDirStat.exe` not found: open a new terminal, inspect the user PATH, and verify the standard executable exists.
- Exit code `1`: validate that every scan root is an existing directory, the output parent exists, the output is writable, and exactly one operation flag is present.
- Missing protected content: retry elevated only with explicit user authorization.
- Slow scan: explain that full-drive, duplicate, permission, and network scans may be expensive; narrow the root when possible.
- Garbled non-ASCII text while previewing JSON/CSV: read the generated file explicitly as UTF-8 before treating it as corrupt.
- Need terminal aggregation: export JSON/CSV first, then parse it with PowerShell, Python, DuckDB, or a spreadsheet tool.

## Unsupported assumptions

- Do not rely on `--help` or `/?` producing console help.
- Do not expect scan rows on stdout.
- Do not combine `/loadfrom` with folder arguments.
- Do not use the internal `/legacyuninstall` switch.
