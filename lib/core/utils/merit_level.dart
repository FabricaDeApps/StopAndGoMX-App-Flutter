import 'package:flutter/material.dart';

Color meritLevelColor(String level) {
  switch (level) {
    case 'grizly':
      return const Color(0xFFB8860B);
    case 'polar':
      return const Color(0xFF5B8DB8);
    case 'pardo':
      return const Color(0xFF8B5E34);
    default:
      return Colors.grey;
  }
}

IconData meritLevelIcon(String level) {
  switch (level) {
    case 'grizly':
      return Icons.workspace_premium;
    case 'polar':
      return Icons.ac_unit;
    case 'pardo':
      return Icons.pets;
    default:
      return Icons.military_tech_outlined;
  }
}

String meritLevelLabel(String level) {
  if (level.isEmpty || level == 'none') return 'Sin nivel';
  return level[0].toUpperCase() + level.substring(1);
}
