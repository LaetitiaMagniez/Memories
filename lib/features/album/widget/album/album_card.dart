import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/utils/cached_image.dart';
import '../../../memories/widget/video/video_thumbnail_widget.dart';
import '../../models/album.dart';

class AlbumCard extends StatelessWidget {
  final Album album;

  const AlbumCard({
    super.key,
    required this.album,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildThumbnail(),
        const SizedBox(height: 6),
        Flexible(
          child: Text(
            album.name,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ),
        Flexible(
          child: Text(
            '${album.itemCount} élément${album.itemCount == 1 ? '' : 's'}',
            style: const TextStyle(
              fontSize: 10,
              color: Colors.grey,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildThumbnail() {
    return AspectRatio(
      aspectRatio: 1,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
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
      child: Container(color: Colors.white),
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
