import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_luban/flutter_luban.dart';
import 'package:image/image.dart';

// 辅助函数：保存Uint8List到文件
void saveImage(Uint8List imageData, String outputPath) {
  final outputFile = File(outputPath);
  outputFile.writeAsBytesSync(imageData);
  print('图片已保存到: $outputPath');
}

void main() {
  late File testImageFile;
  late Uint8List testImage;
  late int originalFileSize;
  late Image originalImage;
  late int originalWidth;
  late int originalHeight;

  setUp(() {
    // 读取测试图片文件 - 使用JPG图片来测试质量参数的影响
    testImageFile = File('screenshot/test.jpg');
    testImage = testImageFile.readAsBytesSync();
    originalFileSize = testImageFile.lengthSync();

    // 解码原始图片获取宽高信息
    originalImage = decodeImage(testImage)!;
    originalWidth = originalImage.width;
    originalHeight = originalImage.height;
  });

  test('compressImage should return Uint8List', () async {
    // 打印原始文件信息
    print('原始图片路径: ${testImageFile.path}');
    print('原始图片大小: ${originalFileSize} 字节 (${(originalFileSize / 1024).toStringAsFixed(2)} KB)');
    print('原始图片尺寸: ${originalWidth}x${originalHeight}');
    print('-' * 50);

    // 创建CompressObject
    final compressObject = CompressObject(image: testImage);

    // 调用compressImage方法
    final CompressResult result = await Luban.compressImage(compressObject);

    // 打印压缩结果信息
    print(
        '压缩后图片大小: ${result.imageData.lengthInBytes} 字节 (${(result.imageData.lengthInBytes / 1024).toStringAsFixed(2)} KB)');
    print('压缩后图片尺寸: ${result.width}x${result.height}');
    print('压缩比例: ${((1 - result.imageData.lengthInBytes / originalFileSize) * 100).toStringAsFixed(2)}%');
    print('-' * 50);

    // 打印前后变化对比
    print('尺寸变化: ${originalWidth}x${originalHeight} -> ${result.width}x${result.height}');
    print(
        '大小变化: ${(originalFileSize / 1024).toStringAsFixed(2)} KB -> ${(result.imageData.lengthInBytes / 1024).toStringAsFixed(2)} KB');
    print(
        '节省空间: ${((originalFileSize - result.imageData.lengthInBytes) / 1024).toStringAsFixed(2)} KB (${((1 - result.imageData.lengthInBytes / originalFileSize) * 100).toStringAsFixed(2)}%)');

    // 保存压缩后的图片
    final outputPath = 'screenshot/compressed_test_${compressObject.quality}.jpg';
    saveImage(result.imageData, outputPath);

    // 验证结果类型
    expect(result, isA<CompressResult>());
    expect(result.imageData, isA<Uint8List>());

    // 验证结果不为空
    expect(result.imageData.isNotEmpty, true);

    // 验证压缩后的大小小于原始大小
    expect(result.imageData.lengthInBytes, lessThan(originalFileSize));

    // 验证尺寸信息有效
    expect(result.width, greaterThan(0));
    expect(result.height, greaterThan(0));
  });
}
