import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/utils/file_cache.dart';

class CachedImage extends StatelessWidget {
  final String url;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget Function(BuildContext, Object, StackTrace?)? errorBuilder;

  const CachedImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.errorBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: getCachedFilePath(url, extension: 'jpg'),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.deepPurple[400]!,
            child: Container(
              width: width,
              height: height,
              decoration: const BoxDecoration(
                color: Colors.white,
              ),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          if (errorBuilder != null) {
            return errorBuilder!(
              context,
              snapshot.error ?? 'Erreur inconnue',
              null,
            );
          } else {
            return const Icon(Icons.broken_image);
          }
        }

        final filePath = snapshot.data!;
        return Image.file(
          File(filePath),
          width: width,
          height: height,
          fit: fit,
          errorBuilder: errorBuilder,
        );
      },
    );
  }
}
