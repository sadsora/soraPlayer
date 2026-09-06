import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import '../models/song.dart';

class AudioMetadataReader {
  static Future<Song?> readMetadata(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) return null;

    final raf = await file.open(mode: FileMode.read);

    try {
      final magic = await raf.read(4);
      if (magic.length < 4) return _fallback(filePath);

      //FLAC
      if (latin1.decode(magic) == "fLaC") {
        return await _readFlacMetadata(raf, filePath);
      }
      if (utf8.decode(magic.sublist(0, 3)) != "ID3") {
        return _fallback(filePath);
      }
      final rest = await raf.read(6);
      if (rest.length < 6) return _fallback(filePath);
      final header = [...magic, ...rest];
      if (header.length < 10) return _fallback(filePath);

      if (utf8.decode(header.sublist(0, 3)) != 'ID3') {
        return _fallback(filePath);
      }

      final version = header[3];
      final hasExtendedHeader = (header[5] & 0x40) != 0;
      final tagSize = _syncSafeInt(header, 6);

      if (hasExtendedHeader) {
        final ext = await raf.read(4);
        final extSize = _syncSafeInt(ext, 0);
        await raf.read(extSize);
      }

      final body = await raf.read(tagSize);

      String? title, artist, album;
      Uint8List? cover;
      int pos = 0;

      while (pos + 10 <= body.length) {
        final frameId = latin1.decode(body.sublist(pos, pos + 4));
        if (frameId.codeUnitAt(0) == 0) break; // padding
        pos += 4;

        final frameSize = version >= 4
            ? _syncSafeInt(body, pos)
            : _int32(body, pos);
        pos += 6; // size(4) + flags(2)

        if (frameSize <= 0 || pos + frameSize > body.length) break;

        final data = body.sublist(pos, pos + frameSize);
        pos += frameSize;

        switch (frameId) {
          case 'TIT2':
            title = _decodeText(data);
          case 'TPE1':
            artist = _decodeText(data);
          case 'TALB':
            album = _decodeText(data);
          case 'APIC':
            cover = _decodeAPIC(data);
        }
      }

      return Song(
        title: title ?? _filenameFromPath(filePath),
        artist: artist ?? 'Unknown Artist',
        album: album ?? 'Unknown Album',
        filePath: filePath,
        cover: cover,
      );
    } catch (e, st) {
      print('AudioMetadataReader error ($filePath): $e\n$st');
      return _fallback(filePath);
    } finally {
      await raf.close();
    }
  }

  //FLAC decoder
  static Future<Song> _readFlacMetadata(
    RandomAccessFile raf,
    String filePath,
  ) async {
    String? title, album, artist;
    Uint8List? cover;
    bool isLast = false;
    while (!isLast) {
      final header = await raf.read(4);
      if (header.length < 4) break;

      isLast = (header[0] & 0x80) != 0;
      final type = header[0] & 0x7F;
      final length = _int24(header, 1); // 大端

      final data = await raf.read(length);
      if (data.length < length) break;

      switch (type) {
        case 4: // VORBIS_COMMENT
          final tags = _parseVorbisComment(data);
          title = tags['TITLE'] ?? title;
          artist = tags['ARTIST'] ?? artist;
          album = tags['ALBUM'] ?? album;
        case 6: // PICTURE
          cover ??= _parseFlacPicture(data);
      }
    }

    return Song(
      title: title ?? _filenameFromPath(filePath),
      artist: artist ?? 'Unknown Artist',
      album: album ?? 'Unknown Album',
      filePath: filePath,
      cover: cover,
    );
  }

  static Map<String, String> _parseVorbisComment(List<int> data) {
    final result = <String, String>{};
    if (data.length < 4) return result;

    int pos = 0;
    final vendorLen = _leInt32(data, pos); // 小端
    pos += 4 + vendorLen;
    if (pos + 4 > data.length) return result;

    final count = _leInt32(data, pos); // 小端
    pos += 4;

    for (int i = 0; i < count; i++) {
      if (pos + 4 > data.length) break;
      final len = _leInt32(data, pos); // 小端
      pos += 4;
      if (pos + len > data.length) break;

      final bytes = data.sublist(pos, pos + len);
      String raw;
      try {
        raw = utf8.decode(bytes);
      } on FormatException {
        raw = latin1.decode(bytes);
      }
      pos += len;

      final eq = raw.indexOf('=');
      if (eq > 0) {
        result[raw.substring(0, eq).toUpperCase()] = raw.substring(eq + 1);
      }
    }
    return result;
  }

  static Uint8List? _parseFlacPicture(List<int> data) {
    int pos = 4; // 跳过 picture type (4 字节)
    if (pos + 4 > data.length) return null;

    final mimeLen = _int32(data, pos); // 大端
    pos += 4;
    if (pos + mimeLen > data.length) return null;
    pos += mimeLen;

    if (pos + 4 > data.length) return null;
    final descLen = _int32(data, pos); // 大端
    pos += 4;
    if (pos + descLen > data.length) return null;
    pos += descLen;

    pos += 16; // width(4) + height(4) + depth(4) + colors(4)

    if (pos + 4 > data.length) return null;
    final picLen = _int32(data, pos); // 大端
    pos += 4;
    if (pos + picLen > data.length) return null;

    return Uint8List.fromList(data.sublist(pos, pos + picLen));
  }

  static int _int24(List<int> bytes, int start) {
    return (bytes[start] << 16) | (bytes[start + 1] << 8) | bytes[start + 2];
  }

  static int _leInt32(List<int> bytes, int start) {
    return bytes[start] |
        (bytes[start + 1] << 8) |
        (bytes[start + 2] << 16) |
        (bytes[start + 3] << 24);
  }

  static Song _fallback(String filePath) {
    return Song(
      title: _filenameFromPath(filePath),
      artist: 'Unknown Artist',
      album: 'Unknown Album',
      filePath: filePath,
      cover: null,
    );
  }

  static String _filenameFromPath(String path) {
    final name = path.split(RegExp(r'[/\\]')).last;
    final dot = name.lastIndexOf('.');
    return dot > 0 ? name.substring(0, dot) : name;
  }

  static int _syncSafeInt(List<int> bytes, int start) {
    return (bytes[start] << 21) |
        (bytes[start + 1] << 14) |
        (bytes[start + 2] << 7) |
        bytes[start + 3];
  }

  static int _int32(List<int> bytes, int start) {
    return (bytes[start] << 24) |
        (bytes[start + 1] << 16) |
        (bytes[start + 2] << 8) |
        bytes[start + 3];
  }

  static String _decodeText(List<int> data) {
    if (data.isEmpty) return '';
    final encoding = data[0];
    final raw = data.sublist(1);

    switch (encoding) {
      case 0:
        return latin1.decode(raw.where((b) => b != 0).toList());
      case 1:
        return _decodeUtf16(raw);
      case 2:
        return _decodeUtf16BE(raw);
      case 3:
        return utf8.decode(raw.where((b) => b != 0).toList());
      default:
        return latin1.decode(raw.where((b) => b != 0).toList());
    }
  }

  static String _decodeUtf16(List<int> bytes) {
    if (bytes.length < 2) return '';
    final bom = (bytes[0] << 8) | bytes[1];
    if (bom == 0xFFFE) {
      return _decodeUtf16LE(bytes.sublist(2));
    } else {
      return _decodeUtf16BE(bytes.sublist(2));
    }
  }

  static String _decodeUtf16LE(List<int> bytes) {
    final chars = <int>[];
    for (int i = 0; i + 1 < bytes.length; i += 2) {
      final c = bytes[i] | (bytes[i + 1] << 8);
      if (c == 0) break;
      chars.add(c);
    }
    return String.fromCharCodes(chars);
  }

  static String _decodeUtf16BE(List<int> bytes) {
    final chars = <int>[];
    for (int i = 0; i + 1 < bytes.length; i += 2) {
      final c = (bytes[i] << 8) | bytes[i + 1];
      if (c == 0) break;
      chars.add(c);
    }
    return String.fromCharCodes(chars);
  }

  static Uint8List? _decodeAPIC(List<int> data) {
    if (data.isEmpty) return null;
    int pos = 1;

    while (pos < data.length && data[pos] != 0) {
      pos++;
    }
    pos++;

    if (pos >= data.length) return null;
    pos++;

    while (pos < data.length && data[pos] != 0) {
      pos++;
    }
    pos++;

    if (pos >= data.length) return null;
    return Uint8List.fromList(data.sublist(pos));
  }
}
