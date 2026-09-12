import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lgbtindernew/core/utils/image_upload_compressor.dart';

void main() {
  group('ImageUploadCompressor', () {
    test('prepareForUpload returns missing files unchanged', () async {
      final missing = File(
        'missing-upload-${DateTime.now().microsecondsSinceEpoch}.jpg',
      );
      final result = await ImageUploadCompressor.prepareForUpload(missing);
      expect(result.path, missing.path);
    });

    test('prepareForPreview returns missing files unchanged', () async {
      final missing = File(
        'missing-preview-${DateTime.now().microsecondsSinceEpoch}.jpg',
      );
      final result = await ImageUploadCompressor.prepareForPreview(missing);
      expect(result.path, missing.path);
    });

    test('prepareForUpload skips re-encode under the size threshold', () async {
      final dir = await Directory.systemTemp.createTemp('img_compress_');
      addTearDown(() => dir.delete(recursive: true));

      final file = File('${dir.path}/tiny.jpg');
      await file.writeAsBytes(List<int>.filled(1024, 7));

      final result = await ImageUploadCompressor.prepareForUpload(file);
      expect(result.path, file.path);
    });
  });
}
