import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
// 1. Import helper ที่สร้างไว้
import '../utils/image_helper.dart'; 

class AddAquariumScreen extends StatefulWidget {
  const AddAquariumScreen({Key? key}) : super(key: key);

  @override
  State<AddAquariumScreen> createState() => _AddAquariumScreenState();
}

class _AddAquariumScreenState extends State<AddAquariumScreen> {
  File? _selectedImage;

  // ... โค้ดส่วนเลือกรูปภาพ (_pickImage) ...

  // 2. แก้ไขฟังก์ชันบันทึกข้อมูล
  Future<void> _saveData() async {
    if (_selectedImage == null) return;

    // เปลี่ยนจาก upload ขึ้น Storage มาใช้ helper แปลงเป็น Base64
    String? base64Image = await convertImageToBase64(_selectedImage!);

    if (base64Image != null) {
      // บันทึกลง Firestore โดยใส่ field 'imageBase64' แทน URL เดิม
      await FirebaseFirestore.instance.collection('aquariums').add({
        'name': 'ชื่อตู้ปลา',
        'imageBase64': base64Image, // <--- แก้ตรงนี้
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // ... UI ของคุณ ...
    return Container();
  }
}