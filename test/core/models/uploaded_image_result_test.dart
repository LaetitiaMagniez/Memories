import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:memories_project/core/models/uploaded_image_result.dart';

void main() {
  group('UploadedImageResult', () {
    test('should create instance with given selectedImage and imageUrl', () {
      final file = File('dummy.jpg');
      const url = 'https://example.com/image.jpg';

      final result = UploadedImageResult(selectedImage: file, imageUrl: url);

      expect(result.selectedImage, file);
      expect(result.imageUrl, url);
    });

    test('should allow null selectedImage and imageUrl', () {
      final result = UploadedImageResult();

      expect(result.selectedImage, isNull);
      expect(result.imageUrl, isNull);
    });
  });
}
