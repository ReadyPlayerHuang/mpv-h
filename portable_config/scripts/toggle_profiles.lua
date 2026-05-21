local utils = require("mp.utils")

local function has_text(value, text)
    return value and value:find(text, 1, true) ~= nil
end

local function clear_shaders()
    mp.commandv("change-list", "glsl-shaders", "clr", "")
end

local function clear_video_filters()
    mp.set_property("vf", "")
end

local function normalize_path(path)
    return path:gsub("\\", "/")
end

local function quote_filter_value(value)
    return '"' .. normalize_path(value):gsub('"', '\\"') .. '"'
end

local function get_rife_script_path()
    local ok, expanded = pcall(mp.command_native, {"expand-path", "~~/vs/rife_trt.vpy"})
    if ok and expanded and expanded ~= "" and expanded ~= "~~/vs/rife_trt.vpy" then
        return normalize_path(expanded)
    end

    local source = debug.getinfo(1, "S").source
    if source:sub(1, 1) == "@" then
        source = source:sub(2)
    end

    local script_dir = source:match("^(.*)[/\\][^/\\]+$") or "."
    local config_dir = script_dir:gsub("[/\\]scripts$", "")
    return normalize_path(config_dir .. "/vs/rife_trt.vpy")
end

local function get_trtexec_path()
    local rife_script = get_rife_script_path()
    local config_dir = rife_script:gsub("[/\\]vs[/\\]rife_trt%.vpy$", "")
    local root_dir = config_dir:gsub("[/\\]portable_config$", "")

    return normalize_path(root_dir .. "/VapourSynth/Lib/site-packages/vapoursynth/plugins/vsmlrt-cuda/trtexec.exe")
end

local function file_exists(path)
    local info = utils.file_info(path)
    return info ~= nil and info.is_file
end

local function enable_shader_profile(profile, label)
    clear_video_filters()
    mp.set_property("hwdec", "auto-safe")
    mp.commandv("apply-profile", profile)
    mp.osd_message(label .. " enabled")
end

local function toggle_shader_profile(profile, marker, label)
    local shaders = mp.get_property("glsl-shaders", "")

    if has_text(shaders, marker) then
        clear_shaders()
        mp.osd_message(label .. " disabled")
    else
        enable_shader_profile(profile, label)
    end
end

local function toggle_rife()
    local vf = mp.get_property("vf", "")

    if has_text(vf, "rife_trt.vpy") then
        clear_video_filters()
        mp.set_property("hwdec", "auto-safe")
        mp.osd_message("RIFE TensorRT disabled")
    else
        if not file_exists(get_trtexec_path()) then
            local message = "trtexec.exe is missing. See README RIFE setup."
            mp.msg.warn(message)
            mp.osd_message(message)
            return
        end
        clear_shaders()
        mp.set_property("hwdec", "no")
        local rife_script = quote_filter_value(get_rife_script_path())
        mp.set_property("vf", "vapoursynth=file=" .. rife_script .. ":buffered-frames=8:concurrent-frames=1")
        mp.osd_message("RIFE TensorRT enabled")
    end
end

mp.add_key_binding(nil, "toggle-anime", function()
    toggle_shader_profile("anime", "Anime4K_Upscale_CNN_x2_VL.glsl", "Anime4K")
end)

mp.add_key_binding(nil, "toggle-fsrcnnx", function()
    toggle_shader_profile("fsrcnnx", "FSRCNNX_x2_16-0-4-1.glsl", "FSRCNNX")
end)

mp.add_key_binding(nil, "toggle-rife", toggle_rife)
