import 'package:cloud_firestore/cloud_firestore.dart';

class Album {
  final String id;
  final String name;
  final String thumbnailUrl;
  final String thumbnailType;
  final int itemCount;

  Album({
    required this.id,
    required this.name,
    required this.thumbnailUrl,
    required this.thumbnailType,
    required this.itemCount,
  });

  factory Album.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Album(
      id: doc.id,
      name: data['name'] ?? '',
      thumbnailUrl: '', // Ce champ sera mis à jour dynamiquement
      thumbnailType: '' ,
      itemCount: 0,     // Ce champ sera mis à jour dynamiquement
    );
  }
}
