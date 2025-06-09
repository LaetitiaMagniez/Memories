import 'package:flutter/material.dart';
import '../../../memories/logic/album/album_service.dart';

class AlbumManagementBar extends StatelessWidget implements PreferredSizeWidget {
  final AlbumService albumService;
  final VoidCallback onExitManaging;
  final VoidCallback onSelectionCleared;
  final VoidCallback onUpdate;

  const AlbumManagementBar({
    super.key,
    required this.albumService,
    required this.onExitManaging,
    required this.onSelectionCleared,
    required this.onUpdate,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text("Gérer les albums"),
      actions: [
        if (albumService.selectedAlbums.length == 1)
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: "Renommer l'album",
            onPressed: () {
              albumService.renameAlbum(context, albumService.selectedAlbums.first);
            },
          ),
        if (albumService.selectedAlbums.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: "Supprimer",
            onPressed: () {
              albumService.confirmDeleteSelectedAlbums(context, () {
                onUpdate();
              });
            },
          ),
        IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: "Retour",
          onPressed: onExitManaging,
        ),
        IconButton(
          icon: const Icon(Icons.close),
          tooltip: "Annuler",
          onPressed: onSelectionCleared,
        ),
      ],
    );
  }
}
