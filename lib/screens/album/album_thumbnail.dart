// album_thumbnail.dart
import 'package:flutter/material.dart';
import '../../class/album.dart';
import 'package:memories_project/souvenir_view/video_thumbnail.dart';

class AlbumThumbnail extends StatelessWidget {
  final Album album;
  final VoidCallback onTap;

  AlbumThumbnail({required this.album, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          _buildThumbnail(),
          Text(album.name),
          Text('${album.itemCount} éléments'),
        ],
      ),
    );
  }

  Widget _buildThumbnail() {
    if (album.thumbnailType == 'image') {
      return Image.network(
        album.thumbnailUrl,
        fit: BoxFit.cover,
        width: 100,
        height: 100,
        errorBuilder: (context, error, stackTrace) {
          print("Erreur de chargement de l'image: $error");
          return Container(
            width: 100,
            height: 100,
            color: Colors.grey,
            child: Icon(Icons.error),
          );
        },
      );
    } else if (album.thumbnailType == 'video') {
      return VideoThumbnail(album.thumbnailUrl);
    } else {
      return Container(
        width: 100,
        height: 100,
        color: Colors.grey,
        child: Icon(Icons.image),
      );
    }
  }
}
