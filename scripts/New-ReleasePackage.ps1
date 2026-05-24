param(
    [string]$Version = (Get-Date -Format "yyyy.MM.dd"),
    [string]$RuntimeRoot = "",
    [string]$VolumeSize = "1900m",
    [switch]$CleanStage,
    [switch]$SkipArchiveTest
)

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$distRoot = Join-Path $repoRoot "dist"

if ([string]::IsNullOrWhiteSpace($RuntimeRoot)) {
    $RuntimeRoot = $repoRoot
}

if (-not (Test-Path -LiteralPath $RuntimeRoot -PathType Container)) {
    throw "Runtime root was not found: $RuntimeRoot. Put the mpv-h release runtime in the repository root, or pass -RuntimeRoot."
}

$runtimePath = (Resolve-Path -LiteralPath $RuntimeRoot).Path
$packageVersion = $Version
if ($packageVersion -like "mpv-h-*") {
    $packageVersion = $packageVersion.Substring(6)
}
if ($packageVersion -like "*-full") {
    $packageVersion = $packageVersion.Substring(0, $packageVersion.Length - 5)
}

$packageName = "mpv-h-$packageVersion-full"
$stageRoot = Join-Path $distRoot $packageName
$archivePath = Join-Path $distRoot "$packageName.7z"
$checksumPath = Join-Path $distRoot "$packageName.7z.sha256"
$assetReadmePath = Join-Path $distRoot "$packageName.README.txt"

function Resolve-ArchiveTool {
    $candidatePaths = @(
        "D:\Huang\Softwares\7-Zip\7z.exe",
        "$env:ProgramFiles\7-Zip\7z.exe",
        "${env:ProgramFiles(x86)}\7-Zip\7z.exe"
    )

    foreach ($candidatePath in $candidatePaths) {
        if (-not [string]::IsNullOrWhiteSpace($candidatePath) -and (Test-Path -LiteralPath $candidatePath)) {
            return (Resolve-Path -LiteralPath $candidatePath).Path
        }
    }

    $pathCommand = Get-Command "7z" -ErrorAction SilentlyContinue
    if ($pathCommand) {
        return $pathCommand.Source
    }

    throw "7-Zip was not found. Install 7-Zip to D:\Huang\Softwares\7-Zip, a standard Program Files location, or add 7z.exe to PATH."
}

function Copy-IfExists {
    param(
        [Parameter(Mandatory=$true)][string]$Source,
        [Parameter(Mandatory=$true)][string]$Destination
    )

    if (Test-Path -LiteralPath $Source) {
        Copy-Item -LiteralPath $Source -Destination $Destination -Recurse -Force
    }
}

function Remove-PackageJunk {
    param([Parameter(Mandatory=$true)][string]$Root)

    $relativeDirs = @(
        "portable_config\cache",
        "portable_config\watch_later",
        "portable_config\restore",
        "portable_config\state",
        "portable_config\vs\engines"
    )

    foreach ($relativeDir in $relativeDirs) {
        $path = Join-Path $Root $relativeDir
        if (Test-Path -LiteralPath $path) {
            Remove-Item -LiteralPath $path -Recurse -Force
        }
    }

    Get-ChildItem -LiteralPath $Root -Recurse -File -Force -ErrorAction SilentlyContinue |
        Where-Object {
            $_.Name -like "*.engine" -or
            $_.Name -like "*.engine.cache" -or
            $_.Name -eq "trtexec.exe" -or
            $_.Name -like "*.pyc" -or
            $_.FullName -match "\\__pycache__\\"
        } |
        Remove-Item -Force

    Get-ChildItem -LiteralPath $Root -Recurse -Directory -Force -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -eq "__pycache__" } |
        ForEach-Object {
            Remove-Item -LiteralPath $_.FullName -Recurse -Force
        }
}

function New-ReleaseManifest {
    param([Parameter(Mandatory=$true)][string]$Root)

    $manifestPath = Join-Path $Root "RELEASE-MANIFEST.txt"
    Get-ChildItem -LiteralPath $Root -Recurse -File -Force |
        Where-Object { $_.FullName -ne $manifestPath } |
        Sort-Object FullName |
        ForEach-Object {
            $relative = $_.FullName.Substring($Root.Length).TrimStart("\", "/")
            $hash = Get-FileHash -Algorithm SHA256 -LiteralPath $_.FullName
            "{0}  {1}" -f $hash.Hash, $relative
        } |
        Set-Content -Encoding UTF8 -LiteralPath $manifestPath
}

function Invoke-GitText {
    param([Parameter(Mandatory=$true)][string[]]$Arguments)

    try {
        $output = @(& git @Arguments 2>$null)
        if ($LASTEXITCODE -eq 0 -and $output.Count -gt 0) {
            return ($output -join "`n").Trim()
        }
    } catch {
    }

    return "unknown"
}

function New-SourceCommitFile {
    param(
        [Parameter(Mandatory=$true)][string]$Root,
        [Parameter(Mandatory=$true)][string]$Version
    )

    $head = Invoke-GitText -Arguments @("-C", $repoRoot, "rev-parse", "HEAD")
    $shortHead = Invoke-GitText -Arguments @("-C", $repoRoot, "rev-parse", "--short", "HEAD")
    $describe = Invoke-GitText -Arguments @("-C", $repoRoot, "describe", "--tags", "--always", "--dirty")
    $status = Invoke-GitText -Arguments @("-C", $repoRoot, "status", "--short")

    if ([string]::IsNullOrWhiteSpace($status)) {
        $status = "clean"
    }

    $content = @(
        "mpv-h source commit",
        "",
        "Package version: $Version",
        "Generated at: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss zzz')",
        "Source commit: $head",
        "Short source commit: $shortHead",
        "Git describe: $describe",
        "Git status: $status"
    )

    Set-Content -Encoding UTF8 -LiteralPath (Join-Path $Root "SOURCE-COMMIT.txt") -Value $content
}

function Invoke-TextCommand {
    param(
        [Parameter(Mandatory=$true)][string]$FilePath,
        [string[]]$Arguments = @()
    )

    if (-not (Test-Path -LiteralPath $FilePath)) {
        return @()
    }

    try {
        return @(& $FilePath @Arguments 2>&1)
    } catch {
        return @()
    }
}

function Select-FirstMatchingLine {
    param(
        [string[]]$Lines,
        [Parameter(Mandatory=$true)][string]$Pattern
    )

    foreach ($line in $Lines) {
        if ($line -match $Pattern) {
            return $line.Trim()
        }
    }

    return "unknown"
}

function Assert-PackageFile {
    param(
        [Parameter(Mandatory=$true)][string]$Root,
        [Parameter(Mandatory=$true)][string]$RelativePath
    )

    $path = Join-Path $Root $RelativePath
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "Release package is missing required file: $RelativePath"
    }
}

function Assert-FileContains {
    param(
        [Parameter(Mandatory=$true)][string]$Path,
        [Parameter(Mandatory=$true)][string]$Text
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "Cannot validate missing file: $Path"
    }

    $content = Get-Content -LiteralPath $Path -Raw
    if (-not $content.Contains($Text)) {
        throw "Release package validation failed. '$Path' does not contain required text: $Text"
    }
}

function Test-ReleasePackage {
    param([Parameter(Mandatory=$true)][string]$Root)

    $requiredFiles = @(
        "mpv-h.exe",
        "mpv.exe",
        "mpv.com",
        "portable_config\input.conf",
        "portable_config\scripts\toggle_profiles.lua",
        "portable_config\vs\rife_trt.vpy",
        "VapourSynth\Lib\site-packages\vapoursynth\vsscript.dll",
        "VapourSynth\Lib\site-packages\vapoursynth\plugins\models\rife\rife_v4.4.onnx"
    )

    foreach ($relativePath in $requiredFiles) {
        Assert-PackageFile -Root $Root -RelativePath $relativePath
    }

    $toggleScript = Join-Path $Root "portable_config\scripts\toggle_profiles.lua"
    Assert-FileContains -Path $toggleScript -Text "expand-path"
    Assert-FileContains -Path $toggleScript -Text "quote_filter_value"

    $trtexecPath = Join-Path $Root "VapourSynth\Lib\site-packages\vapoursynth\plugins\vsmlrt-cuda\trtexec.exe"
    if (Test-Path -LiteralPath $trtexecPath) {
        throw "Release package must not include trtexec.exe. NVIDIA TensorRT trtexec is a developer tool and is not redistributed by mpv-h."
    }
}

function New-RuntimeVersions {
    param(
        [Parameter(Mandatory=$true)][string]$Root,
        [Parameter(Mandatory=$true)][string]$RuntimeRoot,
        [Parameter(Mandatory=$true)][string]$Version
    )

    $mpvLines = Invoke-TextCommand -FilePath (Join-Path $RuntimeRoot "mpv.exe") -Arguments @("--version")
    $ffmpegLines = Invoke-TextCommand -FilePath (Join-Path $RuntimeRoot "ffmpeg.exe") -Arguments @("-version")
    $ytDlpLines = Invoke-TextCommand -FilePath (Join-Path $RuntimeRoot "yt-dlp.exe") -Arguments @("--version")
    $vsPython = Join-Path $RuntimeRoot "VapourSynth\python.exe"

    $pythonVersion = Select-FirstMatchingLine -Lines (Invoke-TextCommand -FilePath $vsPython -Arguments @("--version")) -Pattern ".+"
    $vapourSynthVersion = Select-FirstMatchingLine -Lines (Invoke-TextCommand -FilePath $vsPython -Arguments @("-c", "import vapoursynth as vs; print(vs.__version__)")) -Pattern ".+"
    $vsmlrtVersion = Select-FirstMatchingLine -Lines (Invoke-TextCommand -FilePath $vsPython -Arguments @("-c", "import vsmlrt; print(getattr(vsmlrt, '__version__', 'unknown'))")) -Pattern "^\d+(\.\d+)*$|^unknown$"

    $content = @(
        "mpv-h runtime versions",
        "",
        "Package version: $Version",
        "Generated at: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss zzz')",
        "Runtime root: $RuntimeRoot",
        "",
        "mpv: $(Select-FirstMatchingLine -Lines $mpvLines -Pattern '^mpv .+')",
        "FFmpeg: $(Select-FirstMatchingLine -Lines $ffmpegLines -Pattern '^ffmpeg version .+')",
        "yt-dlp: $(Select-FirstMatchingLine -Lines $ytDlpLines -Pattern '.+')",
        "Python in VapourSynth bundle: $pythonVersion",
        "VapourSynth: $vapourSynthVersion",
        "vsmlrt: $vsmlrtVersion",
        "",
        "Notes:",
        "- TensorRT engine files are generated locally and are not packaged.",
        "- trtexec.exe is not redistributed. Users must obtain it from NVIDIA TensorRT and place it next to the bundled TensorRT DLLs before first RIFE use.",
        "- NVIDIA driver and CUDA compatibility are properties of the user's system, not this package.",
        "- The reference machine is documented in docs/configuration.md."
    )

    Set-Content -Encoding UTF8 -LiteralPath (Join-Path $Root "RUNTIME-VERSIONS.txt") -Value $content
}

New-Item -ItemType Directory -Path $distRoot -Force | Out-Null

if (Test-Path -LiteralPath $stageRoot) {
    Remove-Item -LiteralPath $stageRoot -Recurse -Force
}
New-Item -ItemType Directory -Path $stageRoot | Out-Null

$sourceItems = @(
    "portable_config",
    "installer",
    "README.md",
    "README.zh-CN.md",
    "LICENSE",
    "THIRD-PARTY-NOTICES.md",
    "CHANGELOG.md",
    "LICENSES"
)

foreach ($item in $sourceItems) {
    Copy-IfExists -Source (Join-Path $repoRoot $item) -Destination $stageRoot
}

$stageDocsRoot = Join-Path $stageRoot "docs"
New-Item -ItemType Directory -Path $stageDocsRoot -Force | Out-Null
Copy-IfExists -Source (Join-Path $repoRoot "docs\configuration.md") -Destination $stageDocsRoot

$runtimeFiles = @(
    "mpv.exe",
    "mpv.com",
    "ffmpeg.exe",
    "yt-dlp.exe",
    "d3dcompiler_43.dll",
    "updater.bat"
)

foreach ($file in $runtimeFiles) {
    Copy-IfExists -Source (Join-Path $runtimePath $file) -Destination $stageRoot
}

$launcher = Join-Path $runtimePath "mpv-h.exe"
if (Test-Path -LiteralPath $launcher) {
    Copy-Item -LiteralPath $launcher -Destination $stageRoot -Force
} else {
    Copy-IfExists -Source (Join-Path $repoRoot "artifacts\launcher\mpv-h.exe") -Destination $stageRoot
}

$runtimeDirs = @(
    "mpv",
    "doc",
    "VapourSynth"
)

foreach ($dir in $runtimeDirs) {
    Copy-IfExists -Source (Join-Path $runtimePath $dir) -Destination $stageRoot
}

Remove-PackageJunk -Root $stageRoot
Test-ReleasePackage -Root $stageRoot
New-RuntimeVersions -Root $stageRoot -RuntimeRoot $runtimePath -Version $packageVersion
New-SourceCommitFile -Root $stageRoot -Version $packageVersion
New-ReleaseManifest -Root $stageRoot

Get-ChildItem -LiteralPath $distRoot -File -Force |
    Where-Object {
        $_.Name -eq "$packageName.7z" -or
        $_.Name -like "$packageName.7z.*" -or
        $_.Name -eq "$packageName.README.txt"
    } |
    Remove-Item -Force

$archiveTool = Resolve-ArchiveTool
$archiveArgs = @(
    "a",
    "-t7z",
    "-mx=9",
    "-mmt=on",
    "-v$VolumeSize",
    $archivePath,
    $stageRoot
)

& $archiveTool @archiveArgs | Out-Host
if ($LASTEXITCODE -ne 0) {
    throw "7-Zip archive creation failed with exit code $LASTEXITCODE"
}

$volumeFiles = @(Get-ChildItem -LiteralPath $distRoot -File -Force |
    Where-Object { $_.Name -like "$packageName.7z.*" -or $_.Name -eq "$packageName.7z" } |
    Sort-Object Name)

if ($volumeFiles.Count -eq 0) {
    throw "No archive output was created."
}

$volumeFiles |
    ForEach-Object {
        $hash = Get-FileHash -Algorithm SHA256 -LiteralPath $_.FullName
        "{0}  {1}" -f $hash.Hash, $_.Name
    } |
    Set-Content -Encoding UTF8 -LiteralPath $checksumPath

@(
    "Download all .7z parts into the same folder.",
    "Extract $packageName.7z.001 with 7-Zip.",
    "Do not rename the .001/.002 files.",
    "Use $packageName.7z.sha256 to verify downloaded release assets.",
    "",
    "RIFE TensorRT setup:",
    "mpv-h does not redistribute NVIDIA trtexec.exe.",
    "To use Alt+R interpolation for the first time, download the matching TensorRT Windows zip from NVIDIA:",
    "https://developer.nvidia.com/tensorrt",
    "Recommended direct link for this release:",
    "https://developer.nvidia.com/downloads/compute/machine-learning/tensorrt/10.14.1/zip/TensorRT-10.14.1.48.Windows.win10.cuda-13.0.zip",
    "Copy bin\trtexec.exe from the NVIDIA TensorRT zip to:",
    "$packageName\VapourSynth\Lib\site-packages\vapoursynth\plugins\vsmlrt-cuda\trtexec.exe"
) | Set-Content -Encoding UTF8 -LiteralPath $assetReadmePath

if (-not $SkipArchiveTest) {
    $testArchive = Join-Path $distRoot "$packageName.7z.001"
    if (-not (Test-Path -LiteralPath $testArchive)) {
        $testArchive = $archivePath
    }

    & $archiveTool t $testArchive | Out-Host
    if ($LASTEXITCODE -ne 0) {
        throw "7-Zip archive test failed with exit code $LASTEXITCODE"
    }
}

if ($CleanStage) {
    Remove-Item -LiteralPath $stageRoot -Recurse -Force
}

Write-Host "Staged package: $stageRoot"
Write-Host "Release assets:"
foreach ($file in $volumeFiles) {
    Write-Host "  $($file.FullName)"
}
Write-Host "  $checksumPath"
Write-Host "  $assetReadmePath"
