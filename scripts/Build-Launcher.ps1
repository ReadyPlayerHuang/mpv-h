param(
    [string]$OutputDir = "artifacts\launcher"
)

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$outputPath = Join-Path $repoRoot $OutputDir
$launcherPath = Join-Path $outputPath "mpv-h.exe"

$candidates = @(
    (Join-Path $env:WINDIR "Microsoft.NET\Framework64\v4.0.30319\csc.exe"),
    (Join-Path $env:WINDIR "Microsoft.NET\Framework\v4.0.30319\csc.exe")
)

$csc = $candidates | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $csc) {
    throw "Could not find the .NET Framework C# compiler. Expected csc.exe under %WINDIR%\Microsoft.NET\Framework64\v4.0.30319 or Framework\v4.0.30319."
}

New-Item -ItemType Directory -Path $outputPath -Force | Out-Null

$iconPath = Join-Path $repoRoot "installer\mpv-icon.ico"
$sourcePath = Join-Path $repoRoot "tools\mpv-h-launcher\Program.cs"
$arguments = @(
    "/nologo",
    "/target:winexe",
    "/platform:x64",
    "/optimize+",
    "/win32icon:$iconPath",
    "/out:$launcherPath",
    "/reference:System.dll",
    "/reference:System.Core.dll",
    "/reference:System.Windows.Forms.dll",
    $sourcePath
)

& $csc @arguments

if ($LASTEXITCODE -ne 0) {
    throw "csc.exe failed with exit code $LASTEXITCODE"
}

Write-Host "Built launcher: $launcherPath"
