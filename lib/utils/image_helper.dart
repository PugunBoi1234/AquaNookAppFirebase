import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_image_compress/flutter_image_compress.dart'; // <-- เพิ่มบรรทัดนี้

Future<String?> convertImageToBase64(File imageFile) async {
  try {
    Uint8List? compressedBytes = await FlutterImageCompress.compressWithFile(
      imageFile.absolute.path,
      minWidth: 800,
      minHeight: 800,
      quality: 70,
    );

    if (compressedBytes == null) return null;
    return base64Encode(compressedBytes);
  } catch (e) {
    print("Error converting image: $e");
    return null;
  }
}