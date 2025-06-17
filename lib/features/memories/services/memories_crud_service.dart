import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:memories_project/core/notifiers/paginated_data_notifier.dart';
import 'package:memories_project/features/album/services/album_repository.dart';
import 'package:memories_project/features/memories/models/memory.dart';
import 'memories_dialogs.dart';
import '../../../core/notifiers/selected_items_notifier.dart';

class MemoriesCrudService implements PaginatedCrudService<Memory> {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final AlbumRepository _albumRepository;
  final MemoriesDialogs _memoriesDialogs;

  final SelectedItemsNotifier<Memory> memoriesSelectionNotifier;

  bool _hasMore = true;
  DocumentSnapshot? _lastAlbumDocument;

  late final VoidCallback onExitManaging;
  late final VoidCallback onUpdate;

  MemoriesCrudService({
    required this.memoriesSelectionNotifier,
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
    AlbumRepository? albumRepository,
    MemoriesDialogs? memoriesDialogs,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance,
        _albumRepository = albumRepository ?? AlbumRepository(),
        _memoriesDialogs = memoriesDialogs ?? MemoriesDialogs();

  @override
  void resetPagination() {
    _hasMore = true;
    _lastAlbumDocument = null;
  }

  @override
  Future<List<Memory>> fetchNextPage({int limit = 10}) async {
    if (!_hasMore) return [];

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return [];

    Query query = _firestore
        .collection('albums')
        .where('userId', isEqualTo: currentUser.uid)
        .orderBy('date', descending: true)
        .limit(limit);

    if (_lastAlbumDocument != null) {
      query = query.startAfterDocument(_lastAlbumDocument!);
    }

    final albumsSnapshot = await query.get();

    if (albumsSnapshot.docs.isEmpty) {
      _hasMore = false;
      return [];
    }

    _lastAlbumDocument = albumsSnapshot.docs.last;

    final allMemories = <Memory>[];

    for (var albumDoc in albumsSnapshot.docs) {
      final mediaSnapshot = await albumDoc.reference.collection('media').get();

      for (var doc in mediaSnapshot.docs) {
        try {
          final data = doc.data();
          allMemories.add(
            Memory(
              id: doc.id,
              ville: data['ville'] ?? '',
              url: data['url'] ?? '',
              type: data['type'] ?? '',
              date: (data['date'] as Timestamp).toDate(),
              documentSnapshot: doc,
            ),
          );
        } catch (e) {
          debugPrint('Erreur parsing memory doc ${doc.id} : $e');
        }
      }
    }

    return allMemories;
  }

  Future<List<Memory>> fetchNextMemoriesPage({
    int albumLimit = 2,
  }) => fetchNextPage(limit: albumLimit);

  Stream<List<Memory>> getAllMemoriesForUser() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return Stream.value([]);

    return _firestore
        .collection('albums')
        .where('userId', isEqualTo: currentUser.uid)
        .snapshots()
        .asyncMap((albumsSnapshot) async {
      final allMemories = <Memory>[];
      for (var album in albumsSnapshot.docs) {
        final mediaSnapshot = await album.reference.collection('media').get();
        final memories = mediaSnapshot.docs.map((doc) {
          try {
            final data = doc.data();
            return Memory(
              id: doc.id,
              ville: data['ville'] ?? '',
              url: data['url'] ?? '',
              type: data['type'] ?? '',
              date: (data['date'] as Timestamp).toDate(),
              documentSnapshot: doc,
            );
          } catch (e) {
            debugPrint('Erreur parsing memory doc ${doc.id} : $e');
            return null;
          }
        }).whereType<Memory>();
        allMemories.addAll(memories);
      }
      return allMemories;
    });
  }

  Future<String?> findAlbumIdForMemory(String memoryId) async {
    final albumsCollection = _firestore.collection('albums');
    final albumsSnapshot = await albumsCollection.get();

    for (final albumDoc in albumsSnapshot.docs) {
      final memoryDoc = await albumDoc.reference.collection('media').doc(memoryId).get();
      if (memoryDoc.exists) return albumDoc.id;
    }
    return null;
  }

  Future<String?> _getSelectedMemoryAlbumId() async {
    final selectedMemories = memoriesSelectionNotifier.state;
    if (selectedMemories.isEmpty) return null;
    return await findAlbumIdForMemory(selectedMemories.first.id);
  }

  // Souvenirs partagés

  // Fonction pour récupérer les souvenirs d'un album partagé avec l'utilsateur actif
  Stream<List<Memory>> getMemoriesForMySharedAlbums(String albumId) {
    return FirebaseFirestore.instance
        .collection('albumsShared')
        .doc(albumId)
        .collection('sharedMedia')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) {
        print('Aucun souvenir trouvé pour cet album $albumId');
      }
      return snapshot.docs.map((doc) {
        return Memory(
          id: doc.id,
          ville: doc['ville'],
          url: doc['url'],
          type: doc['type'],
          date: (doc['date'] as Timestamp).toDate(),
          documentSnapshot: doc,
        );
      }).toList();
    });
  }

  // Fonction pour récupérer tous les souvenirs partagés avec l'utilisateur actuel
  Stream<List<Memory>> getAllSharedMemoriesForCurrentUser() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return Stream.value([]);

    return FirebaseFirestore.instance
        .collection('sharedAlbums')
        .where('sharedWith', arrayContains: currentUser.uid)
        .snapshots()
        .asyncMap((albumsSnapshot) async {
      final allSharedMemories = <Memory>[];

      for (final albumDoc in albumsSnapshot.docs) {
        final sharedMediaSnapshot = await albumDoc.reference
            .collection('sharedMedia')
            .orderBy('date', descending: true)
            .get();

        final memories = sharedMediaSnapshot.docs.map((doc) {
          final data = doc.data();
          return Memory(
            id: doc.id,
            ville: data['ville'] ?? '',
            url: data['url'] ?? '',
            type: data['type'] ?? '',
            date: (data['date'] as Timestamp).toDate(),
            documentSnapshot: doc,
          );
        });

        allSharedMemories.addAll(memories);
      }

      return allSharedMemories;
    });
  }


  Future<void> onMove(BuildContext context) async {
    final albumId = await _getSelectedMemoryAlbumId();
    if (albumId == null) {
      _showError(context, "Impossible de trouver l'album d'origine.");
      return;
    }

    await _memoriesDialogs.moveSelectedMemories(
      context,
      albumId,
      memoriesSelectionNotifier,
      deleteMemory,
          () {
        onExitManaging();
        onUpdate();
      },
    );
  }

  void onCancel() {
    memoriesSelectionNotifier.clear();
    onExitManaging();
  }

  Future<void> onDelete(BuildContext context) async {
    final albumId = await _getSelectedMemoryAlbumId();
    if (albumId == null) {
      _showError(context, "Impossible de trouver l'album d'origine.");
      return;
    }

    await _memoriesDialogs.confirmDeleteSelectedMemories(
      context,
      albumId,
      memoriesSelectionNotifier,
      deleteMemory,
          () {
        onExitManaging();
        onUpdate();
      },
    );
  }

  Future<bool> moveMemoryToAlbum(
      String memoryId,
      String sourceAlbumId,
      String targetAlbumId,
      ) async {
    if (memoryId.isEmpty || sourceAlbumId.isEmpty || targetAlbumId.isEmpty) {
      throw ArgumentError("Les identifiants ne doivent pas être vides");
    }
    if (sourceAlbumId == targetAlbumId) {
      throw ArgumentError("L'album source et l'album cible doivent être différents");
    }

    try {
      final albumsCollection = _firestore.collection('albums');
      final sourceRef = albumsCollection.doc(sourceAlbumId).collection('media').doc(memoryId);
      final targetAlbumRef = albumsCollection.doc(targetAlbumId);
      final targetMediaRef = targetAlbumRef.collection('media').doc();

      final memorySnapshot = await sourceRef.get();
      if (!memorySnapshot.exists) throw Exception("Le souvenir n'existe pas dans l'album source.");

      final memoryData = memorySnapshot.data()!;
      final batch = _firestore.batch();

      batch.set(targetMediaRef, {
        'type': memoryData['type'],
        'url': memoryData['url'],
        'ville': memoryData['ville'],
        'date': memoryData['date'],
        'timestamp': FieldValue.serverTimestamp(),
      });

      batch.delete(sourceRef);

      batch.update(albumsCollection.doc(sourceAlbumId), {'itemCount': FieldValue.increment(-1)});
      batch.update(targetAlbumRef, {
        'itemCount': FieldValue.increment(1),
        'thumbnailUrl': memoryData['url'],
        'thumbnailType': memoryData['type'],
      });

      await batch.commit();
      return true;
    } catch (e) {
      debugPrint("Erreur lors du déplacement du souvenir : $e");
      return false;
    }
  }

  Future<void> deleteMemory(String albumId, String memoryId) async {
    final albumRef = _firestore.collection('albums').doc(albumId);
    final mediaDoc = await albumRef.collection('media').doc(memoryId).get();

    if (!mediaDoc.exists) return;

    final mediaData = mediaDoc.data()!;
    final mediaUrl = mediaData['url'] as String;

    try {
      final storageRef = _storage.refFromURL(mediaUrl);
      await storageRef.delete();
      await albumRef.update({'itemCount': FieldValue.increment(-1)});
    } catch (e) {
      debugPrint("Erreur lors de la suppression du fichier : $e");
    }

    await albumRef.collection('media').doc(memoryId).delete();
  }

  void _showError(BuildContext context, String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }
}
