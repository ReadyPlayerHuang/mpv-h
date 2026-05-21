# Third-Party Notices

mpv-h combines original files with third-party projects. Original mpv-h code, configuration, scripts, and documentation are licensed under GPL-3.0-or-later. The top-level `LICENSE` contains the GPL-3.0 license text. Third-party components keep their original licenses.

This notice is intended to document provenance for the source repository and Release packages. It is not a substitute for the license texts in `LICENSES/`.

## Included in This Repository

| Component | Location | Upstream | License |
| --- | --- | --- | --- |
| uosc | `portable_config/scripts/uosc/`, `portable_config/fonts/` | https://github.com/tomasklaen/uosc | LGPL-2.1 |
| thumbfast | `portable_config/scripts/thumbfast.lua`, `portable_config/script-opts/thumbfast.conf` | https://github.com/po5/thumbfast | MPL-2.0 |
| Anime4K shaders | `portable_config/shaders/Anime4K/` | https://github.com/bloc97/Anime4K | MIT |
| FSRCNNX shader | `portable_config/shaders/FSRCNNX/` | https://github.com/igv/FSRCNN-TensorFlow | GPL-3.0 |

License texts mirrored in `LICENSES/`:

- `Anime4K-LICENSE.MIT`
- `FSRCNN-TensorFlow-LICENSE.GPL-3.0`
- `thumbfast-LICENSE.MPL-2.0`
- `uosc-LICENSE.LGPL`

## Distributed Only Through Releases

These runtime components are not committed to Git. If a Release package bundles them, the Release notes should list exact versions, upstream URLs, and checksums.

| Component | Upstream | Notes |
| --- | --- | --- |
| mpv | https://github.com/mpv-player/mpv | Confirm the license mode of the Windows build. |
| FFmpeg | https://ffmpeg.org | FFmpeg builds may be LGPL or GPL depending on enabled libraries. |
| yt-dlp | https://github.com/yt-dlp/yt-dlp | Keep upstream license and notice information. |
| VapourSynth | https://github.com/vapoursynth/vapoursynth | Include upstream license text in full packages. |
| vsmlrt | https://github.com/AmusementClub/vs-mlrt | Include plugin and dependency notices. |
| RIFE models | https://github.com/hzwer/Practical-RIFE | Practical-RIFE is MIT licensed. |
| NVIDIA CUDA/TensorRT runtime DLLs | https://developer.nvidia.com/tensorrt | Runtime redistribution is governed by NVIDIA license terms. `trtexec.exe` is not redistributed by mpv-h; users must obtain it from NVIDIA TensorRT if they want first-time local RIFE engine generation. |

## v2026.05.23 Runtime Record

The first public-ready full package was prepared with:

| Component | Version / Build |
| --- | --- |
| mpv | `v0.41.0-671-g059bc7025`, built on 2026-05-17 |
| FFmpeg | `N-124539-g7ac3d83e7` |
| yt-dlp | `2026.03.17` |
| Python in VapourSynth bundle | `3.14.0` |
| VapourSynth | `R76` |
| vsmlrt | `3.22.38` |
| NVIDIA driver on reference machine | `596.36` |
| NVIDIA-SMI reported CUDA compatibility on reference machine | `13.2` |
