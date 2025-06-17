import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../memories/models/memory.dart';
import '../models/album.dart';
import '../models/album_summary.dart';

class AlbumRepository {

  List<Album> myAlbums = [];
  List<Album> sharedAlbums = [];

  final FirebaseAuth auth = FirebaseAuth.instance;
  final firestore = FirebaseFirestore.instance;


  Future<List<String>> getAllAlbumIds() async {
    User? currentUser = auth.currentUser;
    if (currentUser == null) return [];

    QuerySnapshot albumsSnapshot = await firestore
        .collection('albums')
        .where('userId', isEqualTo: currentUser.uid)
        .get();

    return albumsSnapshot.docs.map((doc) => doc.id).toList();
  }

  Future<List<AlbumSummary>> getAllAlbumSummariesForConnectedUser() async {
    final currentUser = auth.currentUser;
    if (currentUser == null) return [];

    try {
      final querySnapshot = await firestore
          .collection('albums')
          .where('userId', isEqualTo: currentUser.uid)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return AlbumSummary(
          id: doc.id,
          name: data['name'] ?? '',
        );
      }).toList();
    } catch (e) {
      print('Erreur lors de la récupération des albums: $e');
      return [];
    }
  }

  Stream<List<Album>> getAlbumsWithDetails(String userId) {
    return FirebaseFirestore.instance
        .collection('albums')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .asyncMap((snapshot) async {
      List<Album> albums = [];
      for (var doc in snapshot.docs) {
        var mediaQuery = await doc.reference.collection('media')
            .orderBy('timestamp', descending: true)
            .limit(1)
            .get();

        String thumbnailUrl = mediaQuery.docs.isNotEmpty ? mediaQuery.docs
            .first['url'] : '';
        String thumbnailType = mediaQuery.docs.isNotEmpty ? mediaQuery.docs
            .first['type'] : '';

        int itemCount = await doc.reference
            .collection('media')
            .count()
            .get()
            .then((value) => value.count!);

        albums.add(Album(
          id: doc.id,
          userId: doc['userId'],
          name: doc['name'],
          thumbnailUrl: thumbnailUrl,
          thumbnailType: thumbnailType,
          itemCount: itemCount,
        ));
      }
      return albums;
    });
  }

  // Fonction pour récupérer les souvenirs d'un album appartenant à l'utilsateur actif
  Stream<List<Memory>> getMemoriesForMyAlbums(String albumId) {
    return FirebaseFirestore.instance
        .collection('albums')
        .doc(albumId)
        .collection('media')
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

  Future<Album> buildSharedAlbumFromDoc(DocumentSnapshot doc) async {
    final data = doc.data() as Map<String, dynamic>;

    final sharedMediaQuery = await doc.reference
        .collection('sharedMedia')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .get();

    final thumbnailUrl = sharedMediaQuery.docs.isNotEmpty ? sharedMediaQuery
        .docs.first['url'] : '';
    final thumbnailType = sharedMediaQuery.docs.isNotEmpty ? sharedMediaQuery
        .docs.first['type'] : '';
    final itemCount = await doc.reference
        .collection('sharedMedia')
        .count()
        .get()
        .then((snap) => snap.count ?? 0);

    return Album(
      id: doc.id,
      userId: data['userId'] ?? '',
      name: data['name'] ?? '',
      thumbnailUrl: thumbnailUrl,
      thumbnailType: thumbnailType,
      itemCount: itemCount,
    );
  }

  Stream<List<Album>> getSharedAlbumsForUser(String userId) {
    return firestore
        .collection('albums')
        .snapshots()
        .asyncMap((snapshot) async {
      List<Album> sharedAlbums = [];
      for (var doc in snapshot.docs) {
        var mediaQuery = await doc.reference.collection('sharedMedia')
            .where('sharedWith', arrayContains: userId)
            .orderBy('timestamp', descending: true)
            .limit(1)
            .get();

        String thumbnailUrl = mediaQuery.docs.isNotEmpty ? mediaQuery.docs
            .first['url'] : '';
        String thumbnailType = mediaQuery.docs.isNotEmpty ? mediaQuery.docs
            .first['type'] : '';

        int itemCount = await doc.reference
            .collection('media')
            .count()
            .get()
            .then((value) => value.count!);

        sharedAlbums.add(Album(
          id: doc.id,
          userId: doc['userId'],
          name: doc['name'],
          thumbnailUrl: thumbnailUrl,
          thumbnailType: thumbnailType,
          itemCount: itemCount,
        ));
      }
      return sharedAlbums;
    });
  }

  Future<void> deleteAlbum(String albumId) async {
    final mediaSnapshot = await FirebaseFirestore.instance
        .collection('albums')
        .doc(albumId)
        .collection('media')
        .get();

    for (final doc in mediaSnapshot.docs) {
      final mediaUrl = doc['url'];
      try {
        final storageRef = FirebaseStorage.instance.refFromURL(mediaUrl);
        await storageRef.delete();
      } catch (e) {
        print('Erreur lors de la suppression du fichier Storage : $e');
      }
    }

    final batch = FirebaseFirestore.instance.batch();
    for (final doc in mediaSnapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();

    await FirebaseFirestore.instance.collection('albums').doc(albumId).delete();
  }

}