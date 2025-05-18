import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memories_project/classes/album.dart';
import '../classes/appUser.dart';
import '../classes/souvenir.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'contact_service.dart';


class FirestoreService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final ContactService contactService = ContactService();
  AppUser? _currentUser;
  List<Album> myAlbums = [];
  List<Album> sharedAlbums = [];

  //Logique de récupération des albums

  Stream<List<Album>> getAlbumsWithDetails() {
    return FirebaseFirestore.instance.collection('albums').snapshots().asyncMap((snapshot) async {
      List<Album> albums = [];
      for (var doc in snapshot.docs) {
        // Récupérer l'élément le plus récent de l'album
        var mediaQuery = await doc.reference.collection('media')
            .orderBy('timestamp', descending: true)
            .limit(1)
            .get();

        // URL de la vignette (le média le plus récent)
        String thumbnailUrl = mediaQuery.docs.isNotEmpty ? mediaQuery.docs.first['url'] : '';
        String thumbnailType = mediaQuery.docs.isNotEmpty ? mediaQuery.docs.first['type'] : '';

        // Compter le nombre d'éléments dans l'album
        int itemCount = await doc.reference.collection('media').count().get().then((value) => value.count!);

        // Ajouter l'album à la liste
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
  Stream<List<Souvenir>> getSouvenirsForMyAlbums(String albumId) {
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
        return Souvenir(
          id: doc.id,
          ville: doc['ville'],
          url: doc['url'],
          type: doc['type'],
          date: (doc['date'] as Timestamp).toDate(),
        );
      }).toList();
    });
  }
  Stream<List<Album>> getSharedAlbumsForUser(String userId) {
    return FirebaseFirestore.instance.collection('albums').snapshots().asyncMap((snapshot) async {
      List<Album> sharedAlbums = [];
      for (var doc in snapshot.docs) {
        var mediaQuery = await doc.reference.collection('sharedMedia')
            .orderBy('timestamp', descending: true)
            .limit(1)
            .get();

        // URL de la vignette (le média le plus récent)
        String thumbnailUrl = mediaQuery.docs.isNotEmpty ? mediaQuery.docs
            .first['url'] : '';
        String thumbnailType = mediaQuery.docs.isNotEmpty ? mediaQuery.docs
            .first['type'] : '';

        // Compter le nombre d'éléments dans l'album
        int itemCount = await doc.reference
            .collection('media')
            .count()
            .get()
            .then((value) => value.count!);

        // Ajouter l'album à la liste
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

  // Fonction pour récupérer les souvenirs d'un album partagé avec l'utilsateur actif
  Stream<List<Souvenir>> getSouvenirsForMySharedAlbums(String albumId) {
    return FirebaseFirestore.instance
        .collection('albums')
        .doc(albumId)
        .collection('mediaShared')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) {
        print('Aucun souvenir trouvé pour cet album $albumId');
      }
      return snapshot.docs.map((doc) {
        return Souvenir(
          id: doc.id,
          ville: doc['ville'],
          url: doc['url'],
          type: doc['type'],
          date: (doc['date'] as Timestamp).toDate(),
        );
      }).toList();
    });
  }

  // Fonction pour déplacer un souvenir vers un autre album
  Future<void> moveSouvenirToAlbum(String souvenirId, String targetAlbumId) async {
    try {
      // Récupérer le souvenir actuel
      DocumentSnapshot souvenirSnapshot = await FirebaseFirestore.instance.collection('albums')
          .doc(targetAlbumId)
          .collection('media')
          .doc(souvenirId)
          .get();

      if (souvenirSnapshot.exists) {
        // Récupérer les données du souvenir sous forme de Map<String, dynamic>
        Map<String, dynamic> souvenirData = souvenirSnapshot.data() as Map<String, dynamic>;

        // Ajouter le souvenir à l'album cible
        await FirebaseFirestore.instance.collection('albums')
            .doc(targetAlbumId)
            .collection('media')
            .doc(souvenirId)
            .set(souvenirData);

        // Supprimer le souvenir de l'album d'origine
        await FirebaseFirestore.instance.collection('albums')
            .doc(souvenirSnapshot['albumId']) // Utiliser l'ID de l'album d'origine
            .collection('media')
            .doc(souvenirId)
            .delete();

        print('Souvenir déplacé avec succès.');
      } else {
        print('Le souvenir n\'existe pas dans cet album.');
      }
    } catch (e) {
      print("Erreur lors du déplacement du souvenir : $e");
    }
  }
}
