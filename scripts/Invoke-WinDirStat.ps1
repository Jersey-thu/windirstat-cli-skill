[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateSet('Scan', 'Export', 'Duplicates', 'Permissions', 'Load')]
    [string]$Mode,

    [Parameter()]
    [string[]]$Path,

    [Parameter()]
    [string]$OutputPath,

    [Parameter()]
    [string]$InputPath,

    [Parameter()]
    [string]$ExecutablePath,

    [Parameter()]
    [switch]$Elevated,

    [Parameter()]
    [switch]$Force
)

$ErrorActionPreference = 'Stop'

function Resolve-WinDirStatExecutable {
    param([string]$RequestedPath)

    if ($RequestedPath) {
        $resolved = Resolve-Path -LiteralPath $RequestedPath -ErrorAction Stop
        return $resolved.Path
    }

    $command = Get-Command WinDirStat.exe -ErrorAction SilentlyContinue
    if ($command) {
        return $command.Source
    }

    $standardPath = 'C:\Program Files\WinDirStat\WinDirStat.exe'
    if (Test-Path -LiteralPath $standardPath -PathType Leaf) {
        return $standardPath
    }

    throw 'WinDirStat.exe was not found on PATH or in C:\Program Files\WinDirStat.'
}

function Resolve-ExistingDirectory {
    param([string]$Directory)

    $resolved = Resolve-Path -LiteralPath $Directory -ErrorAction Stop
    if (-not (Test-Path -LiteralPath $resolved.Path -PathType Container)) {
        throw "Scan root is not a directory: $Directory"
    }
    return $resolved.Path
}

function Quote-NativeArgument {
    param([string]$Value)

    if ($Value.Contains('"')) {
        throw "Windows paths cannot contain a double quote: $Value"
    }
    return '"' + $Value + '"'
}

$exe = Resolve-WinDirStatExecutable -RequestedPath $ExecutablePath
$arguments = [System.Collections.Generic.List[string]]::new()
$waitForExit = $false
$expectedOutput = $null

if ($Mode -eq 'Load') {
    if ($Path -or $OutputPath) {
        throw 'Load accepts only -InputPath; do not combine it with scan roots or -OutputPath.'
    }
    if (-not $InputPath) {
        throw 'Load requires -InputPath.'
    }
    $input = (Resolve-Path -LiteralPath $InputPath -ErrorAction Stop).Path
    if ([IO.Path]::GetExtension($input) -notin @('.csv', '.json')) {
        throw 'InputPath must end in .csv or .json.'
    }
    $arguments.Add('/loadfrom')
    $arguments.Add((Quote-NativeArgument $input))
}
else {
    if (-not $Path -or $Path.Count -eq 0) {
        throw "$Mode requires at least one directory in -Path."
    }
    $roots = @($Path | ForEach-Object { Resolve-ExistingDirectory $_ })

    if ($Mode -ne 'Scan') {
        if (-not $OutputPath) {
            throw "$Mode requires -OutputPath."
        }

        $extension = [IO.Path]::GetExtension($OutputPath).ToLowerInvariant()
        if ($extension -notin @('.csv', '.json')) {
            throw 'OutputPath must end in .csv or .json.'
        }

        $outputParent = Split-Path -Parent $OutputPath
        if (-not $outputParent) {
            $outputParent = (Get-Location).Path
        }
        $resolvedParent = (Resolve-Path -LiteralPath $outputParent -ErrorAction Stop).Path
        $expectedOutput = Join-Path $resolvedParent (Split-Path -Leaf $OutputPath)

        if ((Test-Path -LiteralPath $expectedOutput) -and -not $Force) {
            throw "Output already exists. Use -Force only after overwrite is authorized: $expectedOutput"
        }

        if ($Force -and (Test-Path -LiteralPath $expectedOutput)) {
            Remove-Item -LiteralPath $expectedOutput -Force
        }

        $flag = switch ($Mode) {
            'Export' { '/saveto' }
            'Duplicates' { '/savedupesto' }
            'Permissions' { '/savepermsto' }
        }
        $arguments.Add($flag)
        $arguments.Add((Quote-NativeArgument $expectedOutput))
        $waitForExit = $true
    }

    foreach ($root in $roots) {
        $arguments.Add((Quote-NativeArgument $root))
    }
}

$startParameters = @{
    FilePath = $exe
    ArgumentList = $arguments.ToArray()
    PassThru = $true
}
if ($waitForExit) {
    $startParameters.Wait = $true
}
if ($Elevated) {
    $startParameters.Verb = 'RunAs'
}

$process = Start-Process @startParameters

if (-not $waitForExit) {
    [pscustomobject]@{
        Mode = $Mode
        Started = $true
        ProcessId = $process.Id
        Executable = $exe
    }
    return
}

$succeeded = $process.ExitCode -eq 0 -and (Test-Path -LiteralPath $expectedOutput -PathType Leaf)
$result = [pscustomobject]@{
    Mode = $Mode
    Succeeded = $succeeded
    ExitCode = $process.ExitCode
    OutputPath = $expectedOutput
    OutputExists = Test-Path -LiteralPath $expectedOutput -PathType Leaf
    Executable = $exe
}
$result

if (-not $succeeded) {
    throw "WinDirStat $Mode failed with exit code $($process.ExitCode)."
}
