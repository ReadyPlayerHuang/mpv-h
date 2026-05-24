# Release Process

This document is for maintainers preparing GitHub Releases.

## Repository Rule

Keep Git focused on source/configuration:

- Track mpv configuration, scripts, shaders, launcher source, installer scripts, and documentation.
- Do not track runtime binaries, VapourSynth, TensorRT DLLs, ONNX model packs, generated TensorRT engines, or release archives.

`.gitignore` is configured to ignore root-level runtime binaries and runtime directories, `artifacts/`, `dist/`, mpv cache, and TensorRT engine files.

## Workspace Layout

The repository root is also the local runnable mpv-h directory:

```text
mpv-h/
  mpv-h.exe         ignored launcher binary
  mpv.exe           ignored mpv runtime binary
  ffmpeg.exe        ignored FFmpeg binary
  yt-dlp.exe        ignored yt-dlp binary
  VapourSynth/      ignored VapourSynth, models, and runtime DLLs
  mpv/              ignored mpv runtime directory
  doc/              ignored upstream runtime documentation
  portable_config/  tracked mpv-h configuration source
  scripts/          tracked maintenance scripts
  tools/            tracked launcher source
  docs/             tracked mpv-h documentation
```

Root-level runtime files are dedicated to mpv-h packaging and local release testing. Keep any personal mpv installation outside this repository so local playback experiments do not leak into mpv-h Release packages.

Release outputs are written under:

```text
mpv-h/dist/
```

Do not force-add ignored runtime files. Keeping them ignored prevents large third-party binaries, generated TensorRT engines, caches, and machine-local state from entering repository history.

`portable_config/` in the repository root is the only mpv-h configuration source.

Maintain root-level runtime files manually as the mpv-h release runtime. They are not synchronized from a personal mpv installation by repository scripts. When updating mpv, FFmpeg, yt-dlp, VapourSynth, model files, or runtime DLLs, place the chosen mpv-h release versions directly in the repository root and then test by running `mpv-h.exe`.

## Build Launcher

The launcher is built with Windows' built-in .NET Framework C# compiler:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\Build-Launcher.ps1
```

Output:

```text
artifacts/launcher/mpv-h.exe
```

`scripts/Build-Launcher.ps1` writes `mpv-h.exe` to the repository root by default, so the local runnable directory uses the rebuilt launcher immediately.

`scripts/New-ReleasePackage.ps1` uses the root-level `mpv-h.exe` by default. If `-RuntimeRoot` points elsewhere and that directory has no `mpv-h.exe`, the script falls back to `artifacts/launcher/mpv-h.exe`.

## Build Release Assets

Assuming the complete mpv-h runtime is in the repository root:

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

The package includes the repository's user-facing files plus root-level runtime files:

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
SOURCE-COMMIT.txt
RELEASE-MANIFEST.txt
```

`RUNTIME-VERSIONS.txt` is a human-readable runtime version summary. `SOURCE-COMMIT.txt` records the Git commit used to generate the staged package. `RELEASE-MANIFEST.txt` contains SHA-256 hashes for packaged files.

`trtexec.exe` is intentionally removed from public Release packages. NVIDIA documents `trtexec` as a TensorRT command-line tool, and mpv-h does not redistribute it. Users who want RIFE first-time engine generation must download TensorRT from NVIDIA and copy `bin\trtexec.exe` into the packaged `vsmlrt-cuda` directory.

## Packaging Options

The default split volume size is `1900m`, which keeps each GitHub Release asset below the 2 GB upload limit:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\New-ReleasePackage.ps1 `
  -Version 2026.05.23 `
  -VolumeSize 1900m
```

If you intentionally want to build from another runtime directory, pass it with `-RuntimeRoot`.

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

## Release Tag Rule

The Release tag must point to the exact commit used to generate the uploaded package.

Use this order:

1. Merge the release-ready code to `main`.
2. Confirm `git status` has no tracked changes.
3. Build and validate the package from that exact `main` commit.
4. Confirm `git rev-parse HEAD` has not changed after packaging.
5. Create the annotated tag on that commit.
6. Push `main` and the tag.
7. Create the GitHub Release from that tag and upload the generated assets.

Do not edit tracked files between package generation and tag creation. If a tracked file changes, commit it first and rebuild the package before tagging.

The generated package includes `SOURCE-COMMIT.txt`; use it to verify which source commit produced a Release asset.

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
