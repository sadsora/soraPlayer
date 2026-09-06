/*
 * FLAC 解码器（基于 dr_flac 单头文件库）
 *
 * 与 mp3_decoder.c 同构：把 FLAC 文件解码为 -1.0~1.0 的 float 交错 PCM，
 * 通过 FFI 暴露给 Dart 侧（flac_decoder_ffi.dart）。
 */

/*
 * 按需裁剪 dr_flac（官方编译期开关，非手工删代码）：
 *   - DR_FLAC_NO_STDIO：不用 drflac_open_file，我们自己读文件到内存
 *   - DR_FLAC_NO_OGG：只处理原生 .flac，不处理 Ogg 封装的 FLAC
 *   - DR_FLAC_NO_CRC：跳过帧 CRC 校验，更快更小（需要完整性校验可删掉这行）
 */
#define DR_FLAC_NO_STDIO
#define DR_FLAC_NO_OGG
#define DR_FLAC_NO_CRC

#define DR_FLAC_IMPLEMENTATION
#include "dr_flac.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#ifdef _WIN32
#define EXPORT __declspec(dllexport)
#include <windows.h>
#else
#define EXPORT __attribute__((visibility("default")))
#endif

static FILE* fopen_utf8(const char *path, const char *mode) {
#ifdef _WIN32
    /* 将 UTF-8 路径转为宽字符，解决中文路径在 Windows 上无法打开的问题 */
    int wlen = MultiByteToWideChar(CP_UTF8, 0, path, -1, NULL, 0);
    if (wlen <= 0) return NULL;
    wchar_t *wpath = (wchar_t *)malloc(wlen * sizeof(wchar_t));
    if (!wpath) return NULL;
    MultiByteToWideChar(CP_UTF8, 0, path, -1, wpath, wlen);

    int wmlen = MultiByteToWideChar(CP_UTF8, 0, mode, -1, NULL, 0);
    wchar_t *wmode = (wchar_t *)malloc(wmlen * sizeof(wchar_t));
    if (!wmode) { free(wpath); return NULL; }
    MultiByteToWideChar(CP_UTF8, 0, mode, -1, wmode, wmlen);

    FILE *f = _wfopen(wpath, wmode);
    free(wpath);
    free(wmode);
    return f;
#else
    return fopen(path, mode);
#endif
}

EXPORT int flac_decode_file(const char *path, float **out,
                            int *out_sr, int *out_ch) {
    FILE *f = fopen_utf8(path, "rb");
    if (!f) {
        fprintf(stderr, "FLAC decode error: cannot open file: %s\n", path);
        return -1;
    }

    fseek(f, 0, SEEK_END);
    long fsize = ftell(f);
    fseek(f, 0, SEEK_SET);
    unsigned char *buf = (unsigned char *)malloc(fsize);
    if (!buf) {
        fprintf(stderr, "FLAC decode error: malloc failed for %ld bytes\n", fsize);
        fclose(f); return -1;
    }
    fread(buf, 1, fsize, f);
    fclose(f);

    drflac *flac = drflac_open_memory(buf, (size_t)fsize, NULL);
    if (!flac) {
        fprintf(stderr, "FLAC decode error: not a valid FLAC stream\n");
        free(buf); return -1;
    }

    drflac_uint32 sampleRate = flac->sampleRate;
    drflac_uint8  channels   = flac->channels;
    drflac_uint64 totalFrames = flac->totalPCMFrameCount;
    size_t total = (size_t)(totalFrames * channels);

    float *samples = (float *)malloc(total * sizeof(float));
    if (!samples) {
        fprintf(stderr, "FLAC decode error: malloc failed for samples buffer\n");
        drflac_close(flac); free(buf); return -1;
    }

    drflac_uint64 framesRead =
        drflac_read_pcm_frames_f32(flac, totalFrames, samples);
    drflac_close(flac);
    free(buf);

    size_t actual = (size_t)(framesRead * channels);
    if (actual == 0) {
        fprintf(stderr, "FLAC decode error: no PCM frames decoded\n");
        free(samples);
        return -1;
    }

    *out_sr = (int)sampleRate;
    *out_ch = (int)channels;
    *out    = samples;

    printf("C DEBUG(FLAC): total=%zu sr=%u ch=%u first5=[%.4f %.4f %.4f %.4f %.4f]\n",
           actual, sampleRate, channels,
           samples[0], samples[1], samples[2], samples[3], samples[4]);
    fflush(stdout);

    return (int)actual;
}

EXPORT void flac_free(float *ptr) {
    free(ptr);
}
