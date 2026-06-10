/* 启用 minimp3 的浮点输出 —— 解码结果直接是 -1.0~1.0 的 float */
#define MINIMP3_FLOAT_OUTPUT
#define MINIMP3_IMPLEMENTATION
#include "minimp3.h"

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

EXPORT int mp3_decode_file(const char *path, float **out,
                           int *out_sr, int *out_ch) {
    FILE *f = fopen_utf8(path, "rb");
    if (!f) {
        fprintf(stderr, "MP3 decode error: cannot open file: %s\n", path);
        return -1;
    }

    fseek(f, 0, SEEK_END);
    long fsize = ftell(f);
    fseek(f, 0, SEEK_SET);
    unsigned char *buf = (unsigned char *)malloc(fsize);
    if (!buf) {
        fprintf(stderr, "MP3 decode error: malloc failed for %ld bytes\n", fsize);
        fclose(f); return -1;
    }
    fread(buf, 1, fsize, f);
    fclose(f);

    mp3dec_t dec;
    mp3dec_init(&dec);

    float frame_pcm[MINIMP3_MAX_SAMPLES_PER_FRAME];
    mp3dec_frame_info_t info;

    /* 逐帧解码 —— 第一帧同时拿元信息 */
    int cap = 4096;
    float *samples = (float *)malloc(cap * sizeof(float));
    if (!samples) {
        fprintf(stderr, "MP3 decode error: malloc failed for samples buffer\n");
        free(buf); return -1;
    }
    int total = 0;

    unsigned char *ptr = buf;
    int remaining = (int)fsize;

    while (remaining > 0) {
        int frame_samples = mp3dec_decode_frame(&dec, ptr, remaining, frame_pcm, &info);
        if (frame_samples <= 0) break;

        /* 每帧的 float 采样总数 = 每声道采样数 × 声道数 */
        int n = frame_samples * info.channels;

        /* 扩容 */
        if (total + n > cap) {
            do { cap *= 2; } while (total + n > cap);
            float *tmp = (float *)realloc(samples, cap * sizeof(float));
            if (!tmp) {
                fprintf(stderr, "MP3 decode error: realloc failed (cap=%d)\n", cap);
                free(samples); free(buf); return -1;
            }
            samples = tmp;
        }

        for (int i = 0; i < n; i++) {
            samples[total++] = frame_pcm[i];
        }

        /* info.frame_bytes 才是输入消耗的字节数，返回值是采样数 */
        ptr += info.frame_bytes;
        remaining -= info.frame_bytes;
    }

    free(buf);

    if (total == 0) {
        fprintf(stderr, "MP3 decode error: no valid MP3 frames found in file\n");
        free(samples);
        return -1;
    }

    *out_sr = info.hz;
    *out_ch = info.channels;

    /* 缩容到实际大小 */
    float *final = (float *)realloc(samples, total * sizeof(float));
    *out = final ? final : samples;

    printf("C DEBUG: total=%d sr=%d ch=%d first5=[%.4f %.4f %.4f %.4f %.4f]\n",
           total, info.hz, info.channels,
           (*out)[0], (*out)[1], (*out)[2], (*out)[3], (*out)[4]);
    fflush(stdout);

    return total;
}

EXPORT void mp3_free(float *ptr) {
    free(ptr);
}
