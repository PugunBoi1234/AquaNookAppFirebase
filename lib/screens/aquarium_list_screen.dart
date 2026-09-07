import 'dart:convert'; // 1. Import ตัวแปลงข้อความ
import 'dart:typed_data';
import 'package:flutter/material.dart';

// 2. แก้ไขตรงจุดที่สร้าง UI แสดงรูปภาพ
Widget buildImageWidget(String? base64String) {
  // ตรวจสอบว่ามีข้อมูล Base64 หรือไม่
  if (base64String != null && base64String.isNotEmpty) {
    // แปลง Base64 String กลับมาเป็น Bytes
    Uint8List bytes = base64Decode(base64String);

    // เปลี่ยนจาก Image.network(...) มาเป็น Image.memory(...)
    return Image.memory(
      bytes,
      fit: BoxFit.cover,
    );
  }

  // กรณีไม่มีรูป
  return const Icon(Icons.image_not_supported); 
}