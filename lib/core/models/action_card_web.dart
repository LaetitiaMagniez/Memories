import 'package:flutter/material.dart';

class ActionCardWeb extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  const ActionCardWeb({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
    this.color = Colors.purple,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          minimumSize: const Size(220, 60),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 5,
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        icon: Icon(icon, color: Colors.white, size: 28),
        label: Text(
          title,
          style: const TextStyle(fontSize: 18, color: Colors.white),
        ),
        onPressed: onTap,
      ),
    );
  }
}
