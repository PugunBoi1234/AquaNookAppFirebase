import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../models/product.dart';

/// ฟังก์ชันเลือกสีตามประเภทปลา (แก้ไข Error getFishColor)
Color getFishColor(String? fishType) {
  if (fishType == null) return Colors.grey;

  switch (fishType.toLowerCase().trim()) {
    case 'betta':
    case 'ปลากัด':
      return Colors.blueAccent;
    case 'goldfish':
    case 'ปลาทอง':
      return Colors.orangeAccent;
    case 'guppy':
    case 'ปลาหางนกยูง':
      return Colors.teal;
    case 'cichlid':
    case 'ปลาหมอสี':
      return Colors.purpleAccent;
    case 'tetras':
    case 'ปลานีออน':
      return Colors.cyan;
    default:
      return Colors.blueGrey; // สีตั้งต้นหากไม่ตรงกับประเภทใดๆ
  }
}

/// Widget สำหรับแสดงรูปภาพปลา/ตู้ปลาจาก Base64 String
class ProductImage extends StatelessWidget {
  final Product? product;
  final String? base64String;
  final String? fishType;
  final double width;
  final double height;
  final BoxFit fit;
  final double? iconSize;

  const ProductImage({
    super.key,
    this.product,
    this.base64String,
    this.fishType,
    this.width = 100,
    this.height = 100,
    this.fit = BoxFit.cover,
    this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    // 1. ดึงสีตามประเภทปลา
    final imageUrl = product?.imageUrl;
    final Color fallbackColor = getFishColor(fishType ?? product?.category);

    if (imageUrl != null && imageUrl.isNotEmpty) {
      final inlineBytes = _decodeInlineImage(imageUrl);
      if (inlineBytes != null) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.memory(
            inlineBytes,
            width: width,
            height: height,
            fit: fit,
            errorBuilder: (_, _, _) => _buildFallbackWidget(fallbackColor),
          ),
        );
      }

      final image =
          imageUrl.startsWith('http://') || imageUrl.startsWith('https://')
          ? Image.network(
              imageUrl,
              fit: fit,
              errorBuilder: (_, _, _) => _buildFallbackWidget(fallbackColor),
            )
          : Image.asset(
              imageUrl,
              fit: fit,
              errorBuilder: (_, _, _) => _buildFallbackWidget(fallbackColor),
            );

      return SizedBox(width: width, height: height, child: image);
    }

    // 2. ตรวจสอบข้อมูล Base64
    if (base64String != null && base64String!.isNotEmpty) {
      try {
        // แปลงข้อความ Base64 กลับเป็น Uint8List (Bytes)
        final Uint8List bytes = _decodeInlineImage(base64String!)!;

        return ClipRRect(
          borderRadius: BorderRadius.circular(8.0),
          child: Image.memory(
            bytes,
            width: width,
            height: height,
            fit: fit,
            // แสดงกรณีที่เกิดความผิดพลาดขณะ Decode รูปภาพ
            errorBuilder: (context, error, stackTrace) {
              return _buildFallbackWidget(fallbackColor);
            },
          ),
        );
      } catch (e) {
        // หาก String ไม่ใช่รูปแบบ Base64 ที่ถูกต้อง
        return _buildFallbackWidget(fallbackColor);
      }
    }

    // 3. กรณีไม่มีข้อมูล Base64 ให้แสดงไอคอนตามสีที่ได้จาก getFishColor
    return _buildFallbackWidget(fallbackColor);
  }

  Uint8List? _decodeInlineImage(String value) {
    try {
      final encoded = value.contains(',') ? value.split(',').last : value;
      if (value.startsWith('data:image') ||
          (value.length > 100 &&
              !value.contains('.') &&
              RegExp(r'^[A-Za-z0-9+/=\s]+$').hasMatch(value))) {
        return base64Decode(encoded);
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  /// Widget สำรองกรณีไม่มีรูปภาพหรือข้อมูลผิดพลาด
  Widget _buildFallbackWidget(Color color) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Icon(
        Icons.set_meal_rounded, // ไอคอนปลา
        color: color,
        size: iconSize ?? width * 0.5,
      ),
    );
  }
}
