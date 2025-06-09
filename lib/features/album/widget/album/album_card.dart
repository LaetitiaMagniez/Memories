import 'package:flutter/material.dart';
import 'package:memories_project/features/album/models/album.dart';
import 'package:memories_project/features/memories/widget/video/video_thumbnail_widget.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/utils/cached_image.dart';

class AlbumCard extends StatelessWidget {
  final Album album;
  final VoidCallback onTap;

  const AlbumCard({
    super.key,
    required this.album,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildThumbnail(context),
          const SizedBox(height: 6),
          Text(
            album.name,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
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

  Widget _buildThumbnail(BuildContext context) {
    final double size = MediaQuery.of(context).size.width / 2 - 24;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: size,
        height: size,
        child: Hero(
          tag: 'albumThumbnail-${album.id}',
          child: _buildMediaContent(),
        ),
      ),
    );
  }

  Widget _buildMediaContent() {
    if (album.thumbnailUrl.isEmpty) {
      return _buildShimmer();
    }

    if (album.thumbnailType == 'image') {
      return CachedImage(
        url: album.thumbnailUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildError(),
      );
    } else if (album.thumbnailType == 'video') {
      return VideoThumbnailWidget(album.thumbnailUrl);
    } else {
      return _buildError();
    }
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        color: Colors.white,
      ),
    );
  }

  Widget _buildError() {
    return Container(
      color: Colors.grey[300],
      child: const Center(
        child: Icon(Icons.broken_image, color: Colors.grey),
      ),
    );
  }
}
