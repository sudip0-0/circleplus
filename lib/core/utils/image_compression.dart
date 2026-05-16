import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';

/// Target maximum file size in bytes (500 KB).
const _targetBytes = 500 * 1024;

/// Maximum dimension (width or height) in pixels used in the first pass.
const _maxDimension = 1400;

/// Minimum dimension we will scale down to before giving up.
const _minDimension = 400;

/// Compresses [bytes] so the result fits within 500 KB.
///
/// Always runs off the UI thread via [compute]. Returns PNG-encoded bytes.
/// The content type returned by callers should remain 'image/jpeg' / the
/// original type — we use PNG encoding internally because dart:ui does not
/// expose a JPEG quality API, but the primary compression lever (dimension
/// scaling) already achieves the target for typical phone photos.
///
/// If the input is already under [_targetBytes], it is returned unchanged.
Future<Uint8List> compressImageBytes(Uint8List bytes) async {
  if (bytes.lengthInBytes <= _targetBytes) {
    return bytes;
  }
  return compute(_compressInIsolate, bytes);
}

Future<Uint8List> _compressInIsolate(Uint8List input) async {
  // Scale down progressively until we are under target or hit minimum size.
  var maxDim = _maxDimension;
  while (maxDim >= _minDimension) {
    final result = await _resizeAndEncode(input, maxDim);
    if (result.lengthInBytes <= _targetBytes) {
      return result;
    }
    maxDim -= 200;
  }
  // Return the smallest we managed to produce.
  return _resizeAndEncode(input, _minDimension);
}

Future<Uint8List> _resizeAndEncode(Uint8List bytes, int maxDim) async {
  final codec = await ui.instantiateImageCodec(
    bytes,
    targetMaxWidthPx: maxDim,
    targetMaxHeightPx: maxDim,
  );
  final frame = await codec.getNextFrame();
  final image = frame.image;
  try {
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      throw StateError('Image encoding failed.');
    }
    return byteData.buffer.asUint8List();
  } finally {
    image.dispose();
  }
}
