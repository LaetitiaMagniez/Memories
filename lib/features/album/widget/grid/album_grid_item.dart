import 'package:flutter/material.dart';
import '../../../logic/album/album_service.dart';
import '../../../../album/models/album.dart';
import '../../../../album/views/album_details.dart';
import '../album_card.dart';

class AlbumGridItem extends StatelessWidget {
  final Album album;
  final bool isManaging;
  final AlbumService albumService;
  final VoidCallback onSelectionChanged;

  const AlbumGridItem({
    super.key,
    required this.album,
    required this.isManaging,
    required this.albumService,
    required this.onSelectionChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = albumService.selectedAlbums.contains(album);

    void onTap() {
      if (isManaging) {
        albumService.toggleAlbumSelection(album, onSelectionChanged);
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AlbumDetailPage(
              albumId: album.id,
              albumName: album.name,
            ),
          ),
        );
      }
    }

    return Stack(
      children: [
        AlbumCard(
          album: album,
          onTap: onTap,
        ),
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
    );
  }
}
