import 'dart:convert';
import 'package:flutter/material.dart';

/// Renders a user/seller avatar that can be either a short emoji string
/// (e.g. "🐠") or a photo the user uploaded, stored as a base64
/// "data:image/...;base64,..." string. Used everywhere an avatar shows up
/// so photo avatars render correctly instead of as raw text.
class AvatarDisplay extends StatelessWidget {
  final String avatar;
  final double size;

  const AvatarDisplay({super.key, required this.avatar, this.size = 22});

  bool get _isPhoto => avatar.startsWith('data:image');

  @override
  Widget build(BuildContext context) {
    if (_isPhoto) {
      try {
        final bytes = base64Decode(avatar.split(',').last);
        return ClipOval(
          child: Image.memory(
            bytes,
            width: size * 2,
            height: size * 2,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _emojiFallback(),
          ),
        );
      } catch (_) {
        return _emojiFallback();
      }
    }
    return Text(avatar, style: TextStyle(fontSize: size));
  }

  Widget _emojiFallback() {
    return Text('🐠', style: TextStyle(fontSize: size));
  }
}
