import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// Target maximum file size in bytes (500 KB).
const _targetBytes = 500 * 1024;

/// Maximum dimension (width or height) in pixels used in the first pass.
const _maxDimension = 1400;

/// Minimum dimension we will scale down to before giving up.
const _minDimension = 400;

const _qualityPasses = [88, 78, 68, 58];

/// Compresses [bytes] so the result fits within 500 KB.
///
/// Always runs off the UI thread via [compute]. Returns JPEG-encoded bytes.
///
/// The implementation intentionally avoids `dart:ui` image decoding because
/// Flutter's internal decoder registry is not available from background
/// isolates on all runtimes.
Future<Uint8List> compressImageBytes(Uint8List bytes) async {
  return compute(_compressInIsolate, bytes);
}

Uint8List _compressInIsolate(Uint8List input) {
  final decoded = img.decodeImage(input);
  if (decoded == null) {
    throw const FormatException('Selected photo could not be decoded.');
  }

  final oriented = img.bakeOrientation(decoded);
  Uint8List? smallest;

  // Scale down progressively until we are under target or hit minimum size.
  var maxDim = _maxDimension;
  while (maxDim >= _minDimension) {
    final resized = _resizeToFit(oriented, maxDim);
    for (final quality in _qualityPasses) {
      final result = Uint8List.fromList(
        img.encodeJpg(resized, quality: quality),
      );
      if (smallest == null || result.lengthInBytes < smallest.lengthInBytes) {
        smallest = result;
      }
      if (result.lengthInBytes <= _targetBytes) {
        return result;
      }
    }
    maxDim -= 200;
  }

  return smallest!;
}

img.Image _resizeToFit(img.Image image, int maxDim) {
  final longestSide = math.max(image.width, image.height);
  if (longestSide <= maxDim) {
    return image;
  }

  return image.width >= image.height
      ? img.copyResize(
          image,
          width: maxDim,
          interpolation: img.Interpolation.average,
        )
      : img.copyResize(
          image,
          height: maxDim,
          interpolation: img.Interpolation.average,
        );
}
