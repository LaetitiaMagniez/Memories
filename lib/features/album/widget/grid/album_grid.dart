import 'package:flutter/material.dart';
import '../../../logic/album/album_service.dart';
import '../../../../album/models/album.dart';
import 'album_grid_item.dart';

class AlbumGrid extends StatelessWidget {
  final List<Album> albums;
  final bool isManaging;
  final AlbumService albumService;
  final VoidCallback onSelectionChanged;

  const AlbumGrid({
    super.key,
    required this.albums,
    required this.isManaging,
    required this.albumService,
    required this.onSelectionChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (albums.isEmpty) {
      return const Center(
        child: Text(
          "Aucun album à afficher",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(8.0),
      physics: const AlwaysScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8.0,
        mainAxisSpacing: 8.0,
        childAspectRatio: 1.0,
      ),
      itemCount: albums.length,
      itemBuilder: (context, index) {
        final album = albums[index];

        return AlbumGridItem(
          album: album,
          isManaging: isManaging,
          albumService: albumService,
          onSelectionChanged: onSelectionChanged,
        );
      },
    );
  }
}
