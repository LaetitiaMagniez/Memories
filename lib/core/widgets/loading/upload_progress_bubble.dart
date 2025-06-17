import 'package:flutter/material.dart';

class UploadProgressBubble extends StatelessWidget {
  final double progress; // de 0.0 à 1.0

  const UploadProgressBubble({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    final isComplete = progress >= 1.0;

    return AnimatedOpacity(
      opacity: isComplete ? 0.0 : 1.0,
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOut,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0.0, end: progress),
        duration: const Duration(milliseconds: 400),
        builder: (context, value, child) {
          final isDone = value >= 1.0;

          return SizedBox(
            width: 120,
            height: 120,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Contour violet
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.deepPurple,
                      width: 4,
                    ),
                  ),
                ),

                // Remplissage de bas en haut
                ClipOval(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    heightFactor: value,
                    child: Container(
                      width: 120,
                      height: 120,
                      color: Colors.deepPurple,
                    ),
                  ),
                ),

                // Contenu central : pourcentage ou checkmark
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: isDone
                      ? const Icon(
                    Icons.check_circle,
                    key: ValueKey("check"),
                    color: Colors.white,
                    size: 40,
                  )
                      : Text(
                    "${(value * 100).toInt()}%",
                    key: const ValueKey("percent"),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
