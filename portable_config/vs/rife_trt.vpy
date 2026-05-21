import vapoursynth as vs
from vapoursynth import core

from pathlib import Path

import vsmlrt


clip = video_in
source_format = clip.format

# TensorRT engines are generated per machine and should not be packaged.
engine_folder = Path(__file__).resolve().parent / "engines"
engine_folder.mkdir(exist_ok=True)

work = core.resize.Bicubic(
    clip,
    format=vs.RGBH,
    matrix_in_s="709",
    range_in_s="limited",
)

pad_w = (-work.width) % 32
pad_h = (-work.height) % 32
if pad_w or pad_h:
    work = core.std.AddBorders(work, right=pad_w, bottom=pad_h)

work = vsmlrt.RIFE(
    work,
    multi=2,
    scale=1.0,
    model=vsmlrt.RIFEModel.v4_4,
    backend=vsmlrt.Backend.TRT(
        fp16=True,
        force_fp16=True,
        output_format=1,
        # device_id=0 selects the first NVIDIA GPU visible to CUDA/TensorRT.
        device_id=0,
        workspace=2048,
        use_cuda_graph=True,
        num_streams=1,
        static_shape=True,
        max_aux_streams=2,
        engine_folder=str(engine_folder),
    ),
)

if pad_w or pad_h:
    work = core.std.Crop(work, right=pad_w, bottom=pad_h)

if source_format.color_family == vs.YUV:
    work = core.resize.Bicubic(
        work,
        format=source_format.id,
        matrix_s="709",
        range_s="limited",
        dither_type="error_diffusion",
    )
elif source_format.color_family == vs.RGB and work.format.id != source_format.id:
    work = core.resize.Bicubic(work, format=source_format.id)

work.set_output()
