import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

/// Compresses a captured JPEG in place to shrink upload size/time.
/// Falls back to the original path if compression fails for any reason.
Future<String> compressCapturedImage(String sourcePath) async {
  try {
    final tempDir = await getTemporaryDirectory();
    final targetPath =
        '${tempDir.path}/${DateTime.now().microsecondsSinceEpoch}.jpg';

    final compressed = await FlutterImageCompress.compressAndGetFile(
      sourcePath,
      targetPath,
      quality: 70,
      minWidth: 1280,
      minHeight: 1280,
      format: CompressFormat.jpeg,
    );

    return compressed?.path ?? sourcePath;
  } catch (e) {
    debugPrint('Image compression failed, using original file: $e');
    return sourcePath;
  }
}
