# Release Process

This document is for maintainers preparing GitHub Releases.

## Repository Rule

Keep Git focused on source/configuration:

- Track mpv configuration, scripts, shaders, launcher source, installer scripts, and documentation.
- Do not track runtime binaries, VapourSynth, TensorRT DLLs, ONNX model packs, generated TensorRT engines, or release archives.

`.gitignore` is configured to ignore `artifacts/`, `dist/`, runtime binaries, VapourSynth, mpv cache, and TensorRT engine files.

## Workspace Layout

This repository is intentionally kept next to, not inside, the runtime directory:

```text
Tools/
  mpv-h/    source repository: configuration, scripts, launcher source, docs
  mpv/      external runtime root: mpv.exe, FFmpeg, yt-dlp, VapourSynth, models, DLLs
```

`mpv-h` is the Git repository. The sibling `mpv` directory is treated as an external runtime root used only when building a full Release package.

Release outputs are written under:

```text
mpv-h/dist/
```

Do not initialize Git inside the runtime `mpv` directory for this project. Keeping the runtime outside Git prevents large third-party binaries, generated TensorRT engines, caches, and machine-local state from entering repository history.

## Build Launcher

The launcher is built with Windows' built-in .NET Framework C# compiler:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\Build-Launcher.ps1
```

Output:

```text
artifacts/launcher/mpv-h.exe
```

`scripts/New-ReleasePackage.ps1` uses this launcher if present. Otherwise it falls back to `mpv-h.exe` from `-RuntimeRoot`.

## Build Release Assets

Assuming the complete runtime is in a sibling `mpv` directory:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\New-ReleasePackage.ps1 -Version 2026.05.23
```

The script creates a full package directory and split 7-Zip Release assets:

```text
dist/mpv-h-2026.05.23-full/
dist/mpv-h-2026.05.23-full.7z.001
dist/mpv-h-2026.05.23-full.7z.002
dist/mpv-h-2026.05.23-full.7z.sha256
dist/mpv-h-2026.05.23-full.README.txt
```

The package includes the repository's user-facing files plus the runtime files from `-RuntimeRoot`:

```text
README.md
README.zh-CN.md
LICENSE
THIRD-PARTY-NOTICES.md
CHANGELOG.md
LICENSES/
docs/configuration.md
RUNTIME-VERSIONS.txt
installer/
portable_config/
mpv-h.exe
mpv.exe
mpv.com
ffmpeg.exe
yt-dlp.exe
d3dcompiler_43.dll
updater.bat
mpv/
doc/
VapourSynth/
```

Maintainer-only files such as `scripts/`, `tools/`, `docs/RELEASE.md`, `.git*`, `dist/`, and `artifacts/` are not copied into the package.

The script removes generated or machine-local files before archiving:

```text
portable_config/cache/
portable_config/watch_later/
portable_config/restore/
portable_config/state/
portable_config/vs/engines/
*.engine
*.engine.cache
trtexec.exe
__pycache__/
*.pyc
```

It also writes:

```text
RUNTIME-VERSIONS.txt
RELEASE-MANIFEST.txt
```

`RUNTIME-VERSIONS.txt` is a human-readable runtime version summary. `RELEASE-MANIFEST.txt` contains SHA-256 hashes for packaged files.

`trtexec.exe` is intentionally removed from public Release packages. NVIDIA documents `trtexec` as a TensorRT command-line tool, and mpv-h does not redistribute it. Users who want RIFE first-time engine generation must download TensorRT from NVIDIA and copy `bin\trtexec.exe` into the packaged `vsmlrt-cuda` directory.

## Packaging Options

The default split volume size is `1900m`, which keeps each GitHub Release asset below the 2 GB upload limit:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\New-ReleasePackage.ps1 `
  -Version 2026.05.23 `
  -VolumeSize 1900m
```

If the runtime directory is not the default sibling `mpv` folder, pass it with `-RuntimeRoot`.

The script automatically looks for 7-Zip in `D:\Huang\Softwares\7-Zip\7z.exe`, the standard `Program Files` locations, and then `PATH`.

Use `-CleanStage` to remove the staged package directory after the archive is created:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\New-ReleasePackage.ps1 `
  -Version 2026.05.23 `
  -CleanStage
```

Use `-SkipArchiveTest` only when you intentionally want to skip the 7-Zip integrity test.

## Upload to GitHub Releases

Upload all split archive parts, the checksum file, and the README asset:

```text
mpv-h-2026.05.23-full.7z.001
mpv-h-2026.05.23-full.7z.002
mpv-h-2026.05.23-full.7z.sha256
mpv-h-2026.05.23-full.README.txt
```

Users should download every `.7z.*` part into the same folder, then extract the `.7z.001` file with 7-Zip.

## Version Naming

Use date-based tags while this remains a personal distribution:

```text
v2026.05.23
v2026.06.01
```

Use matching archive names:

```text
mpv-h-2026.05.23-full.7z.001
mpv-h-2026.05.23-full.7z.002
```
