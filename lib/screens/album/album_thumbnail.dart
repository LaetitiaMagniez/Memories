import 'package:flutter/material.dart';
import '../../classes/album.dart';
import 'package:memories_project/souvenir_view/video_thumbnail_widget.dart';

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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildThumbnail(),
          if (showInfo)
            Container(
              padding: const EdgeInsets.only(top: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    album.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${album.itemCount} éléments',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildThumbnail() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8.0),
      child: SizedBox(
        width: 120,
        height: 120,
        child: album.thumbnailType == 'image'
            ? Image.network(
          album.thumbnailUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            print("Erreur de chargement de l'image: $error");
            return Container(
              color: Colors.grey,
              child: const Icon(Icons.error),
            );
          },
        )
            : album.thumbnailType == 'video'
            ? VideoThumbnailWidget(
            album.thumbnailUrl,
            )
            : Container(
          color: Colors.grey,
          child: const Icon(Icons.image),
        ),
      ),
    );
  }
}
