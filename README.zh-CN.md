# mpv-h

![Platform](https://img.shields.io/badge/platform-Windows-0078D4)
![mpv](https://img.shields.io/badge/player-mpv-3b3b3b)
![Super Resolution](https://img.shields.io/badge/Super_Resolution-Anime4K%20%7C%20FSRCNNX-2f80ed)
![VapourSynth](https://img.shields.io/badge/VapourSynth-included-5b6ee1)
![TensorRT](https://img.shields.io/badge/TensorRT-RIFE_engine-76B900)
![RIFE](https://img.shields.io/badge/RIFE-frame_interpolation-ff6b35)
![License](https://img.shields.io/badge/license-GPL--3.0--or--later-blue)
![Release](https://img.shields.io/github/v/release/ReadyPlayerHuang/mpv-h)

[English](README.md) | 简体中文

mpv-h 是一个面向 Windows 的个人便携式 mpv 配置和整合包。它组合了 mpv 配置、uosc、thumbfast、Anime4K/FSRCNNX 着色器预设，以及基于 VapourSynth/vsmlrt/TensorRT 的 RIFE 补帧配置。

这不是 mpv 官方版本。

![mpv-h 快速演示](docs/assets/mpv-h-demo.gif)

| Anime4K 着色器配置 | RIFE 补帧 |
| --- | --- |
| ![Anime4K 着色器配置](docs/assets/anime4k-enabled.webp) | ![RIFE 补帧](docs/assets/rife-stats.webp) |

[观看完整演示视频](https://github.com/ReadyPlayerHuang/mpv-h/releases/download/v2026.05.23/mpv-h-demo-v2026.05.23.mp4)

## 功能

- 便携式 Windows mpv 配置。
- uosc 界面和右键菜单。
- thumbfast 缩略图预览。
- Anime4K 和 FSRCNNX 超分辨率快捷切换。
- RIFE TensorRT 补帧快捷切换。
- `mpv-h.exe` 启动器会为 mpv 注入随包携带的 VapourSynth/vsmlrt 运行环境。
- 可选 Windows 默认应用和文件关联安装/卸载脚本。

## 运行要求

- Windows 10/11 x64。
- 使用随包 RIFE TensorRT 补帧配置时需要 NVIDIA GPU。
- 建议使用较新的 NVIDIA 驱动。首个 Release 在 `596.36` 驱动下测试；NVIDIA-SMI 显示 CUDA compatibility `13.2`。
- 解压分卷 Release 包需要 7-Zip。

完整 Release 包已经包含运行所需的便携环境：mpv、FFmpeg、yt-dlp、VapourSynth、vsmlrt、TensorRT runtime DLLs、随包 TensorRT 栈所需的 CUDA runtime DLLs 和 ONNX 模型。它不再分发 NVIDIA `trtexec.exe`。普通用户正常播放不需要额外安装 CUDA Toolkit、VapourSynth、Python 或 .NET SDK。

## 下载

如果只是使用，请下载最新 GitHub Release。把所有分卷压缩包下载到同一个文件夹，然后用 7-Zip 解压 `.7z.001` 文件。不要重命名 `.001` / `.002` 文件。

源码仓库只维护配置、脚本、启动器源码和文档。`mpv.exe`、FFmpeg、yt-dlp、VapourSynth、TensorRT runtime files、CUDA runtime DLLs、ONNX 模型等大体积运行时文件通过 GitHub Releases 分发，不放进 Git。

## RIFE TensorRT 设置

RIFE 补帧首次使用时需要 NVIDIA `trtexec.exe` 来构建本地 TensorRT engine。NVIDIA 文档将 `trtexec` 定义为 TensorRT command-line tool，但 mpv-h 不再分发它。

启用首次 RIFE engine 构建：

1. 从 NVIDIA 下载匹配的 TensorRT Windows zip：<https://developer.nvidia.com/tensorrt>。
2. 本 Release 推荐使用 NVIDIA 官方直链：<https://developer.nvidia.com/downloads/compute/machine-learning/tensorrt/10.14.1/zip/TensorRT-10.14.1.48.Windows.win10.cuda-13.0.zip>。
3. 解压 NVIDIA zip，把其中的 `bin\trtexec.exe` 复制到：

```text
mpv-h-2026.05.23-full\VapourSynth\Lib\site-packages\vapoursynth\plugins\vsmlrt-cuda\trtexec.exe
```

engine 构建完成后，后续启用 RIFE 可以复用本地 engine 缓存；除非 GPU、驱动、TensorRT runtime、模型、精度或输入形状发生变化。

## 使用

完整 Release 包：

1. 解压压缩包。
2. 运行 `mpv-h.exe`。
3. 如需注册到 Windows 默认应用，以管理员身份运行 `installer/mpv-h-install.bat`。

卸载 Windows 应用注册：

```powershell
.\installer\mpv-h-uninstall.bat
```

## 快捷键

| 快捷键 | 功能 |
| --- | --- |
| `Alt+1` | 切换 Anime4K |
| `Alt+2` | 切换 FSRCNNX |
| `Alt+0` | 关闭所有 GLSL shaders |
| `Alt+R` | 切换 RIFE TensorRT 补帧 |
| `Alt+9` | 关闭视频滤镜并恢复硬件解码 |
| 右键 | 打开 uosc 菜单 |

Anime4K/FSRCNNX 超分辨率和 RIFE TensorRT 补帧有意设置为互斥。两者同时开启通常负载过高，很少有电脑能稳定流畅播放视频。硬件解码也按负载切换：超分辨率会恢复 `hwdec=auto-safe`，因为测试机器不开硬件解码会掉帧；RIFE 会设置 `hwdec=no`，因为测试机器在 VapourSynth 补帧时开启硬件解码反而会掉帧。

## 仓库结构

```text
portable_config/        mpv 配置、脚本、uosc 资源、字体、着色器
tools/mpv-h-launcher/   启动器源码
installer/              Windows 注册脚本和图标
scripts/                维护用构建和 Release 打包脚本
docs/                   配置和 Release 维护文档
LICENSES/               第三方许可证文本
```

## 已知假设

- RIFE 配置默认使用 NVIDIA `device_id=0`。
- TensorRT engine 文件会在首次使用时本地生成，不应该跨机器复制。
- 首次启用 RIFE 可能较慢，因为 TensorRT 需要根据当前 GPU、驱动、模型、精度和输入形状构建 engine。
- 默认配置刻意保持中立。`display-fps-override=240` 这类高刷新率显示器调优项只保留为说明，不默认启用。

调优说明见 [docs/configuration.md](docs/configuration.md)。

## 维护说明

启动器可以用 Windows 自带的 .NET Framework C# 编译器重新构建：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\Build-Launcher.ps1
```

从同级 `mpv` 运行时目录构建完整 Release 包：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\New-ReleasePackage.ps1 -Version 2026.05.23
```

更多细节见 [docs/RELEASE.md](docs/RELEASE.md)。

## 许可证

mpv-h 原创代码和配置使用 GPL-3.0-or-later。随包第三方组件保留各自原始许可证。

组件许可信息见 [THIRD-PARTY-NOTICES.md](THIRD-PARTY-NOTICES.md) 和 [LICENSES/](LICENSES/)。
