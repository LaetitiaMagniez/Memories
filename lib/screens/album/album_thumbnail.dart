import 'package:flutter/material.dart';
import '../../class/album.dart';
import 'package:memories_project/souvenir_view/video_thumbnail.dart';

class AlbumThumbnail extends StatelessWidget {
  final Album album;
  final VoidCallback onTap;
  final bool showInfo; // Nouveau paramètre

  const AlbumThumbnail({
    super.key,
    required this.album,
    required this.onTap,
    this.showInfo = true, // Par défaut, afficher les infos
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min, // Ajuste la taille de la colonne pour éviter le débordement
        children: [
          _buildThumbnail(),
          if (showInfo)
            Container(
              padding: const EdgeInsets.only(top: 8.0), // Un peu d'espace entre la thumbnail et les infos
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Nom de l'album avec une taille de police ajustée
                  Text(
                    album.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold, // Nom en gras
                      fontSize: 12, // Taille de police ajustée
                    ),
                    textAlign: TextAlign.center, // Centrer le texte
                    overflow: TextOverflow.ellipsis, // Si le texte dépasse, il sera coupé
                  ),
                  // Nombre d'éléments avec une taille plus petite
                  Text(
                    '${album.itemCount} éléments',
                    style: TextStyle(
                      fontSize: 10, // Taille de police réduite
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center, // Centrer le texte
                    overflow: TextOverflow.ellipsis, // Gestion du débordement
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
      borderRadius: BorderRadius.circular(8.0), // Arrondir les coins de l'image
      child: album.thumbnailType == 'image'
          ? Image.network(
        album.thumbnailUrl,
        fit: BoxFit.cover,
        width: 120,
        height: 120,
        errorBuilder: (context, error, stackTrace) {
          print("Erreur de chargement de l'image: $error");
          return Container(
            width: 120,
            height: 120,
            color: Colors.grey,
            child: const Icon(Icons.error),
          );
        },
      )
          : album.thumbnailType == 'video'
          ? VideoThumbnail(album.thumbnailUrl)
          : Container(
        width: 120,
        height: 120,
        color: Colors.grey,
        child: const Icon(Icons.image),
      ),
    );
  }
}
