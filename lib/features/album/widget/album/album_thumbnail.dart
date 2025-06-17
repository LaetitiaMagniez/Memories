import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:memories_project/features/memories/widget/video/video_thumbnail_widget.dart';
import '../../../../core/utils/cached_image.dart';
import '../../../album/models/album.dart';

class AlbumThumbnail extends StatelessWidget {
  final Album album;
  final VoidCallback onTap;
  final bool showInfo;

  const AlbumThumbnail({
    super.key,
    required this.album,
    required this.onTap,
    this.showInfo = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double size = constraints.maxWidth;

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildThumbnail(size),
              if (showInfo) _buildInfo(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildThumbnail(double size) {
    final borderRadius = BorderRadius.circular(10.0);

    return ClipRRect(
      borderRadius: borderRadius,
      child: SizedBox(
        width: size,
        height: size,
        child: _buildContentByType(),
      ),
    );
  }

  Widget _buildContentByType() {
    final url = album.thumbnailUrl;

    if (url.isEmpty) {
      return _buildPlaceholder();
    }

    switch (album.thumbnailType) {
      case 'image':
        return CachedImage(
          url: url,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            debugPrint("Erreur de chargement image: $error");
            return _buildErrorFallback();
          },
        );
      case 'video':
        return VideoThumbnailWidget(url);
      default:
        return _buildErrorFallback();
    }
  }

  Widget _buildPlaceholder() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        color: Colors.white,
      ),
    );
  }

  Widget _buildErrorFallback() {
    return Container(
      color: Colors.grey.shade300,
      alignment: Alignment.center,
      child: const Icon(
        Icons.broken_image,
        color: Colors.grey,
        size: 40,
      ),
    );
  }

  Widget _buildInfo() {
    return Padding(
      padding: const EdgeInsets.only(top: 6.0),
      child: Column(
        children: [
          Text(
            album.name,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          Text(
            '${album.itemCount} élément${album.itemCount == 1 ? '' : 's'}',
            style: const TextStyle(
              fontSize: 10,
              color: Colors.grey,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
