import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/album.dart';
import '../../services/album_options_menu.dart';
import '../../views/album_details.dart';
import '../album/album_card.dart';
import '../../../../core/providers/app_provider.dart';

class AlbumGridItem extends ConsumerWidget {
  final Album album;
  final AlbumOptionsMenu albumOptionsMenu = AlbumOptionsMenu();
  final bool isManaging;

  AlbumGridItem({
    super.key,
    required this.album,
    required this.isManaging,
  });

  void refreshUI() {
    print('refreshing UI');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedAlbums = ref.watch(selectedAlbumsProvider);
    final selectedNotifier = ref.read(selectedAlbumsProvider.notifier);
    final isSelected = selectedAlbums.contains(album);

    return GestureDetector(
      onTap: () {
        if (isManaging) {
          selectedNotifier.toggleSelection(album);
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AlbumDetailsPage(
                albumId: album.id,
                albumName: album.name,
              ),
            ),
          );
        }
      },
      onLongPress: () {
        albumOptionsMenu.showSingleAlbumOptions(
            context,
            ref,
            album,
            refreshUI,
            refreshUI: () {  },
            onManageAlbums: () {  },
            onAlbumsDeleted: () {  },
            onAlbumRenamed: () {  });
      },
      child: Stack(
        children: [
          AlbumCard(album: album),
          if (isManaging)
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.8),
                ),
                child: Icon(
                  isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: isSelected ? Colors.deepPurple : Colors.grey,
                  size: 20,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
