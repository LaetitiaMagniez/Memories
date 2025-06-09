import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerProgressBar extends StatelessWidget {
  final double progress;

  const ShimmerProgressBar({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        width: 250,
        height: 24,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          children: [
            FractionallySizedBox(
              widthFactor: progress,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.deepPurple,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            Center(
              child: Text(
                '${(progress * 100).toStringAsFixed(0)}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(blurRadius: 3, color: Colors.black38)],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
