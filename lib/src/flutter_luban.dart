import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart';

class CompressObject {
  final Uint8List image;
  final int quality;
  final int step;
  final bool autoRatio;
  final double ignoreSize;

  CompressObject({
    required this.image,
    this.quality = 85,
    this.step = 10,
    this.autoRatio = true,
    this.ignoreSize = 200,
  });
}

class CompressResult {
  final Uint8List imageData;
  final int width;
  final int height;

  CompressResult({
    required this.imageData,
    required this.width,
    required this.height,
  });
}

class Luban {
  Luban._();

  static Future<CompressResult> compressImage(CompressObject object) async {
    return compute<CompressObject, CompressResult>(_compress, object);
  }

  static CompressResult _compress(CompressObject object) {
    var bytes = object.image;
    var imageSize = bytes.length / 1024;
    if (imageSize <= object.ignoreSize) {
      Image image = decodeImage(bytes)!;
      return CompressResult(
        imageData: bytes,
        width: image.width,
        height: image.height,
      );
    }
    Image image = decodeImage(bytes)!;
    bool isLandscape = false;
    double targetSize;
    int fixelW = image.width;
    int fixelH = image.height;
    double thumbW = (fixelW % 2 == 1 ? fixelW + 1 : fixelW).toDouble();
    double thumbH = (fixelH % 2 == 1 ? fixelH + 1 : fixelH).toDouble();
    double scale = 0;
    if (fixelW > fixelH) {
      scale = fixelH / fixelW;
      var tempFixelH = fixelW;
      var tempFixelW = fixelH;
      fixelH = tempFixelH;
      fixelW = tempFixelW;
      isLandscape = true;
    } else {
      scale = fixelW / fixelH;
    }
    if (scale <= 1 && scale > 0.5625) {
      if (fixelH < 1664) {
        targetSize = (fixelW * fixelH) / pow(1664, 2) * 150;
      } else if (fixelH >= 1664 && fixelH < 4990) {
        thumbW = fixelW / 2;
        thumbH = fixelH / 2;
        targetSize = (thumbH * thumbW) / pow(2495, 2) * 300;
      } else if (fixelH >= 4990 && fixelH < 10240) {
        thumbW = fixelW / 4;
        thumbH = fixelH / 4;
        targetSize = (thumbW * thumbH) / pow(2560, 2) * 300;
      } else {
        int multiple = fixelH / 1280 == 0 ? 1 : fixelH ~/ 1280;
        thumbW = fixelW / multiple;
        thumbH = fixelH / multiple;
        targetSize = (thumbW * thumbH) / pow(2560, 2) * 300;
      }
    } else if (scale <= 0.5625 && scale >= 0.5) {
      int multiple = fixelH / 1280 == 0 ? 1 : fixelH ~/ 1280;
      thumbW = fixelW / multiple;
      thumbH = fixelH / multiple;
      targetSize = (thumbW * thumbH) / (1440.0 * 2560.0) * 200;
    } else {
      int multiple = (fixelH / (1280.0 / scale)).ceil();
      thumbW = fixelW / multiple;
      thumbH = fixelH / multiple;
      targetSize = ((thumbW * thumbH) / (1280.0 * (1280 / scale))) * 500;
    }
    targetSize = targetSize < object.ignoreSize ? object.ignoreSize : targetSize;
    if (imageSize < targetSize) {
      return CompressResult(
        imageData: encodeJpg(image, quality: object.quality),
        width: image.width,
        height: image.height,
      );
    }
    if (isLandscape) {
      image = copyResize(image, width: thumbH.toInt(), height: object.autoRatio ? null : thumbW.toInt());
    } else {
      image = copyResize(image, width: thumbW.toInt(), height: object.autoRatio ? null : thumbH.toInt());
    }
    var compressedData = _doCompress(
      oldImage: image,
      quality: object.quality,
      targetSize: targetSize,
      step: object.step,
    );
    return CompressResult(
      imageData: compressedData,
      width: image.width,
      height: image.height,
    );
  }

  static Uint8List _doCompress({
    Image? oldImage,
    quality,
    targetSize,
    step,
  }) {
    var newImage = encodeJpg(oldImage!, quality: quality);
    print('压缩后图片大小: ${newImage.lengthInBytes} 字节 (${(newImage.lengthInBytes / 1024).toStringAsFixed(2)} KB)');
    if (newImage.lengthInBytes / 1024 > targetSize && quality > step) {
      quality -= step;
      return _doCompress(
        oldImage: oldImage,
        quality: quality,
        targetSize: targetSize,
        step: step,
      );
    }
    return newImage;
  }
}
