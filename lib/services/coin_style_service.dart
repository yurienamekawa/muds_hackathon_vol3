import 'package:flutter/material.dart';

class CoinStyleService {
  static const Map<String, IconData> iconMap = {
    'heart_pink': Icons.favorite,
    'star_blue': Icons.star,
    'star_yellow': Icons.star,
    'leaf_green': Icons.eco,
    'star_purple': Icons.star,
    'flower_orange': Icons.local_florist,
    'flower_pink': Icons.local_florist,
    'note_blue': Icons.music_note,
  };

  static const Map<String, Color> colorMap = {
    'heart_pink': Color(0xFFF06292),
    'star_blue': Color(0xFF64B5F6),
    'star_yellow': Color(0xFFFFEB3B),
    'leaf_green': Color(0xFF81C784),
    'star_purple': Color(0xFFBA68C8),
    'flower_orange': Color(0xFFFF8A65),
    'flower_pink': Color(0xFFF48FB1),
    'note_blue': Color(0xFF4FC3F7),
  };

  static Color resolveColor(dynamic colorValue) {
    if (colorValue is Color) return colorValue;
    if (colorValue is int) return Color(colorValue);
    if (colorValue is String) {
      final cleaned = colorValue.replaceAll('#', '').trim();
      if (cleaned.length == 6) {
        return Color(int.parse('0xFF$cleaned'));
      }
      if (cleaned.length == 8) {
        return Color(int.parse('0x$cleaned'));
      }
    }
    return const Color(0xFF64B5F6);
  }

  static Map<String, dynamic> buildCoinAppearance({String? coinType}) {
    final normalized = (coinType ?? '').trim().toLowerCase();
    return {
      'icon': iconMap[normalized] ?? Icons.monetization_on,
      'color': resolveColor(colorMap[normalized] ?? const Color(0xFF64B5F6)),
      'coin_type': normalized.isEmpty ? null : normalized,
    };
  }
}
