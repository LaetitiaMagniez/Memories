import 'package:flutter/material.dart';
import '../../../../core/utils/cached_image.dart';
import '../../models/memory.dart';
import '../video/video_thumbnail_widget.dart';

class MemoryGridItem extends StatelessWidget {
  final Memory memory;
  final bool isManaging;
  final bool isSelected;
  final VoidCallback onTap;

  const MemoryGridItem({
    super.key,
    required this.memory,
    required this.isManaging,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Positioned.fill(
            child: memory.type == 'image'
                ? CachedImage(url: memory.url, fit: BoxFit.cover)
                : VideoThumbnailWidget(memory.url),
          ),
          if (isManaging)
            Container(
              decoration: BoxDecoration(
                color: isSelected ? Colors.deepPurple.withOpacity(0.3) : null,
                border: isSelected ? Border.all(color: Colors.deepPurple, width: 2) : null,
              ),
            ),
          if (isManaging)
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.8),
                ),
                child: Icon(
                  isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: isSelected ? Colors.deepPurple : Colors.grey,
                  size: 20,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
