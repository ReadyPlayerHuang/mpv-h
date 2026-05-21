# Configuration

This document records the assumptions behind the default mpv-h configuration and the author's reference machine.

## Reference Machine

The first public-ready package was tested on:

```text
OS: Microsoft Windows 11 Pro x64, version 10.0.26200
CPU: Intel Core i9-13980HX, 24 cores / 32 threads
Memory: 16 GB
GPU 0: NVIDIA GeForce RTX 4060 Laptop GPU, 8 GB VRAM
GPU 1: Intel UHD Graphics
NVIDIA driver: 596.36
NVIDIA-SMI reported CUDA compatibility: 13.2
mpv: v0.41.0-671-g059bc7025, built on 2026-05-17
FFmpeg: N-124539-g7ac3d83e7
yt-dlp: 2026.03.17
Python runtime in VapourSynth bundle: 3.14.0
VapourSynth: R76
vsmlrt: 3.22.38
```

This is a reference environment, not a strict requirement. Other NVIDIA systems may work, but TensorRT performance and engine compatibility depend on GPU, driver, TensorRT runtime, model, precision, and input shape.

## `portable_config/configs/video.conf`

currently uses:

```text
profile=high-quality
vo=gpu-next
gpu-api=d3d11
hwdec=auto-safe
cscale=catmull_rom
deband=yes
icc-profile-auto=yes
blend-subtitles=video
video-sync=audio
interpolation=no
```

The default config is intentionally neutral. `display-fps-override=240` is documented in the config file for the author's 240 Hz display, but it is not enabled by default because it is machine-specific and can be wrong on 60 Hz, 120 Hz, 144 Hz, VRR, or multi-monitor setups.

`target-colorspace-hint=no` is also documented but disabled by default. It is a workaround for an observed gpu-next/DXGI color-handling issue on the author's setup, not a universal setting.

## `portable_config/profiles.conf`

defines:

- `anime`: Anime4K shader chain.
- `fsrcnnx`: FSRCNNX shader.

## `portable_config/scripts/toggle_profiles.lua`

makes shader upscaling and RIFE interpolation mutually exclusive:

- Enabling Anime4K or FSRCNNX clears video filters and restores `hwdec=auto-safe`.
- Enabling RIFE clears GLSL shaders and sets `hwdec=no`.
- Enabling RIFE checks for a local `trtexec.exe` before applying the VapourSynth filter.

This is intentional. Shader upscaling and RIFE TensorRT interpolation are both expensive GPU workloads; running both at the same time is usually too heavy for smooth video playback. Hardware decoding is also switched by workload: on the author's machine, shader upscaling drops frames without hardware decoding, while RIFE interpolation drops frames when hardware decoding is enabled.

## RIFE TensorRT Profile

## `portable_config/vs/rife_trt.vpy`

currently uses:

```text
vsmlrt.RIFEModel.v4_4
TensorRT backend
FP16
device_id=0
static_shape=True
engine_folder=portable_config/vs/engines
```

`device_id=0` means the first NVIDIA GPU visible to CUDA/TensorRT. On most single-NVIDIA-GPU systems this is the correct default. Users with multiple NVIDIA GPUs can inspect device order with:

```powershell
nvidia-smi --query-gpu=index,name,uuid,pci.bus_id --format=csv
```

## Runtime Bundle

The full Release package includes portable runtime components required for normal playback:

```text
mpv
FFmpeg
yt-dlp
VapourSynth
Python
vsmlrt
TensorRT runtime DLLs
CUDA runtime DLLs required by the bundled TensorRT stack
ONNX models
```

Users do not need to install the CUDA Toolkit, VapourSynth, Python, or the .NET SDK separately when using the full Release package. A recent NVIDIA driver is still required.

`trtexec.exe` is not redistributed by mpv-h. To build a RIFE TensorRT engine for the first time, users should download the matching TensorRT Windows zip from NVIDIA and copy `bin\trtexec.exe` to:

```text
mpv-h-2026.05.23-full\VapourSynth\Lib\site-packages\vapoursynth\plugins\vsmlrt-cuda\trtexec.exe
```

Use the NVIDIA TensorRT download page as the stable entry point:

```text
https://developer.nvidia.com/tensorrt
```

For the first mpv-h Release, this NVIDIA direct link is recommended because it matches the bundled TensorRT runtime DLLs:

```text
https://developer.nvidia.com/downloads/compute/machine-learning/tensorrt/10.14.1/zip/TensorRT-10.14.1.48.Windows.win10.cuda-13.0.zip
```

## `portable_config/vs/engines`

TensorRT engine files are generated locally on first use. They depend on GPU model, driver, TensorRT runtime, model, precision, and input shape. They should not be copied between machines or packaged into Releases.
