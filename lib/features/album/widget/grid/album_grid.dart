import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/album.dart';
import 'album_grid_item.dart';

class AlbumGrid extends ConsumerWidget {
  final List<Album> albums;
  final bool isManaging;

  const AlbumGrid({
    super.key,
    required this.albums,
    required this.isManaging,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {

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
        childAspectRatio: 0.8,
      ),
      itemCount: albums.length,
      itemBuilder: (context, index) {
        final album = albums[index];

        return AlbumGridItem(
          album: album,
          isManaging: isManaging,

        );
      },
    );
  }
}
