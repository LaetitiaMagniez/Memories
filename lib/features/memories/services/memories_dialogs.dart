import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

import 'package:memories_project/core/services/media_service.dart';
import 'package:memories_project/core/widgets/dialogs/dialogs.dart';
import 'package:memories_project/features/album/services/album_repository.dart';
import 'package:memories_project/features/memories/models/memory.dart';
import 'package:memories_project/core/notifiers/selected_items_notifier.dart';

import '../../album/models/album_summary.dart';

class MemoriesDialogs {
  final AlbumRepository _albumRepository;
  final MediaService _mediaService;

  MemoriesDialogs({
    AlbumRepository? albumRepository,
    MediaService? mediaService,
  })
      : _albumRepository = albumRepository ?? AlbumRepository(),
        _mediaService = mediaService ??
            MediaService(
              auth: FirebaseAuth.instance,
              firestore: FirebaseFirestore.instance,
              storage: FirebaseStorage.instance,
            );


  //Gestion de plusieurs souvenirs
  Future<void> moveSelectedMemories(
      BuildContext context,
      String currentAlbumId,
      SelectedItemsNotifier<Memory> selectionNotifier,
      Future<void> Function(String albumId, String memoryId) deleteMemory,
      VoidCallback refreshUI,
      ) async {
    final newAlbumId = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choisir un nouvel album'),
        content: FutureBuilder<List<AlbumSummary>>(
          future: _albumRepository.getAllAlbumSummariesForConnectedUser(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final albums = snapshot.data!;

            if (albums.isEmpty) {
              return const Text("Aucun album disponible.");
            }

            return ListView(
              shrinkWrap: true,
              children: albums.map((album) {
                return ListTile(
                  title: Text(album.name),
                  onTap: () => Navigator.of(context).pop(album.id),
                );
              }).toList(),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );

    if (newAlbumId != null) {
      final selectedItems = selectionNotifier.selectedItems;

      for (var memory in selectedItems) {
        await deleteMemory(currentAlbumId, memory.id);
        await _mediaService.addMediaToAlbum(
          newAlbumId,
          memory.type,
          memory.url,
          memory.ville,
          memory.date,
        );
      }

      selectionNotifier.clear();
      refreshUI();
    }
  }

  Future<void> confirmDeleteSelectedMemories(BuildContext context,
      String albumId,
      SelectedItemsNotifier<Memory> selectionNotifier,
      Future<void> Function(String albumId, String memoryId) deleteMemory,
      VoidCallback refreshUI,) async {
    await CoreDialogs.confirmDeleteSelected<Memory>(
      context: context,
      selectedItems: selectionNotifier.selectedItems.toList(),
      itemNameSingular: 'ce souvenir',
      itemNamePlural: 'ces souvenirs',
      onDelete: (memory) async {
        await deleteMemory(albumId, memory.id);
      },
      onSuccess: () {
        selectionNotifier.clear();
        refreshUI();
      },
    );
  }


  //Gestion d'un seul souvenir
  Future<void> moveSingleMemory({
    required BuildContext context,
    required String currentAlbumId,
    required Memory memory,
    required Future<
        void> Function(String albumId, String memoryId) deleteMemory,
    required VoidCallback refreshUI,
  }) async {
    final newAlbumId = await showDialog<String>(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: const Text('Choisir un nouvel album'),
            content: FutureBuilder<List<AlbumSummary>>(
              future: _albumRepository.getAllAlbumSummariesForConnectedUser(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final albums = snapshot.data!;

                if (albums.isEmpty) {
                  return const Text("Aucun album disponible.");
                }

                return ListView(
                  shrinkWrap: true,
                  children: albums.map((album) {
                    return ListTile(
                      title: Text(album.name),
                      onTap: () => Navigator.of(context).pop(album.id),
                    );
                  }).toList(),
                );
              },
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler'),
              ),
            ],
          ),
    );

    if (newAlbumId != null) {
      await deleteMemory(currentAlbumId, memory.id);
      await _mediaService.addMediaToAlbum(
        newAlbumId,
        memory.type,
        memory.url,
        memory.ville,
        memory.date,
      );
      refreshUI();
    }
  }



  Future<void> confirmDeleteSingleMemory({
    required BuildContext context,
    required String albumId,
    required Memory memory,
    required Future<
        void> Function(String albumId, String memoryId) deleteMemory,
    required VoidCallback refreshUI,
  }) async {
    await CoreDialogs.confirmDeleteSingle(
      context: context,
      item: memory,
      itemName: 'ce souvenir',
      onDelete: (Memory memory) async {
        await deleteMemory(albumId, memory.id);
      },
      onSuccess: refreshUI,
    );
  }

}

