import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class HoverableStatCardWeb extends StatefulWidget {
  final String title;
  final int count;
  final Color color;
  final VoidCallback onTap;

  const HoverableStatCardWeb({
    required this.title,
    required this.count,
    required this.color,
    required this.onTap,
  });

  @override
  State<HoverableStatCardWeb> createState() => HoverableStatCardWebState();
}

class HoverableStatCardWebState extends State<HoverableStatCardWeb> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _isHovering ? widget.color.withOpacity(0.8) : widget.color,
            borderRadius: BorderRadius.circular(12),
            boxShadow: _isHovering
                ? [BoxShadow(color: widget.color.withOpacity(0.5), blurRadius: 12, offset: Offset(0, 4))]
                : [],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.count.toString(),
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                widget.title,
                style: const TextStyle(fontSize: 16, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
