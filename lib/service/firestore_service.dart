import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memories_project/album/album_class.dart';

class FirestoreService {
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
        
        // Compter le nombre d'éléments dans l'album
        int itemCount = await doc.reference.collection('media').count().get().then((value) => value.count!);
        
        // Ajouter l'album à la liste
        albums.add(Album(
          id: doc.id,
          name: doc['name'],
          thumbnailUrl: thumbnailUrl,
          itemCount: itemCount,
        ));
      }
      return albums;
    });
  }
}
