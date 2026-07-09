import 'package:flutter/material.dart';

class CoinStyleService {
  static const Map<String, IconData> iconMap = {
    'sunny_blue': Icons.wb_sunny_rounded,
    'heart_pink': Icons.favorite_rounded,
    'home_orange': Icons.home_rounded,
    'star_yellow': Icons.star_rounded,
    'food_green': Icons.restaurant_rounded,
    'music_purple': Icons.music_note_rounded,
    'run_teal': Icons.directions_run_rounded,
    'car_indigo': Icons.directions_car_rounded,
    'bulb_red': Icons.lightbulb_rounded,
  };

  static const Map<String, Color> colorMap = {
    'sunny_blue': Color(0xFF64B5F6),
    'heart_pink': Color(0xFFF06292),
    'home_orange': Color(0xFFFFB74D),
    'star_yellow': Color(0xFFFFD54F),
    'food_green': Color(0xFF81C784),
    'music_purple': Color(0xFFBA68C8),
    'run_teal': Color(0xFF4DB6AC),
    'car_indigo': Color(0xFF7986CB),
    'bulb_red': Color(0xFFE57373),
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
    String normalized = (coinType ?? '').trim().toLowerCase();
    
    // Map legacy coin_types to new IDs
    const legacyMap = {
      'star_blue': 'sunny_blue',
      'leaf_green': 'run_teal',
      'star_purple': 'music_purple',
      'flower_orange': 'home_orange',
      'flower_pink': 'heart_pink',
      'note_blue': 'sunny_blue',
    };
    
    if (legacyMap.containsKey(normalized)) {
      normalized = legacyMap[normalized]!;
    }
    
    return {
      'icon': iconMap[normalized] ?? Icons.monetization_on,
      'color': resolveColor(colorMap[normalized] ?? const Color(0xFF64B5F6)),
      'coin_type': normalized.isEmpty ? null : normalized,
    };
  }
}
