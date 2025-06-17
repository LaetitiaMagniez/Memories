import 'package:flutter/material.dart';
import '../../../../core/notifiers/selected_items_notifier.dart'; // <-- utilise ça
import '../../models/album.dart';
import '../../services/album_dialogs.dart';

class AlbumManagementBar extends StatelessWidget implements PreferredSizeWidget {
  final AlbumDialogs albumDialog;
  final List<Album> selectedAlbums;
  final SelectedItemsNotifier<Album> albumSelectionNotifier;
  final VoidCallback onExitManaging;
  final VoidCallback onSelectionCleared;
  final VoidCallback onUpdate;

  const AlbumManagementBar({
    super.key,
    required this.albumDialog,
    required this.selectedAlbums,
    required this.albumSelectionNotifier, // <-- Correction ici
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
        if (selectedAlbums.length == 1)
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: "Renommer l'album",
            onPressed: () {
              albumDialog.renameAlbum(context, selectedAlbums.first);
            },
          ),
        if (selectedAlbums.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: "Supprimer",
            onPressed: () async {
              await albumDialog.confirmDeleteSelectedAlbums(
                context,
                albumSelectionNotifier, // <-- Correction ici
                onUpdate,
              );
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
