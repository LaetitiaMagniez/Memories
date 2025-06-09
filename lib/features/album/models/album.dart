import 'package:cloud_firestore/cloud_firestore.dart';

class Album {
  final String id;
  final String userId;
  final String name;
  final String thumbnailUrl;
  final String thumbnailType;
  final int itemCount;

  Album({
    required this.id,
    required this.userId,
    required this.name,
    required this.thumbnailUrl,
    required this.thumbnailType,
    required this.itemCount,
  });

  /// Crée un album vide (utile pour éviter nulls)
  factory Album.empty(String id) => Album(
    id: id,
    userId: '',
    name: '',
    thumbnailUrl: '',
    thumbnailType: '',
    itemCount: 0,
  );

  /// Version simple sans détails
  factory Album.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Album(
      id: doc.id,
      userId: data['userId'] ?? '',
      name: data['name'] ?? '',
      thumbnailUrl: '',
      thumbnailType: '',
      itemCount: 0,
    );
  }

  /// Version enrichie avec détails
  static Future<Album> fromSnapshotWithDetails(DocumentSnapshot doc) async {
    final data = doc.data() as Map<String, dynamic>;
    final albumId = doc.id;
    final userId = data['userId'] ?? '';
    final name = data['name'] ?? '';

    // Media principal
    final mediaQuery = await doc.reference
        .collection('media')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .get();

    final thumbnailUrl = mediaQuery.docs.isNotEmpty ? mediaQuery.docs.first['url'] : '';
    final thumbnailType = mediaQuery.docs.isNotEmpty ? mediaQuery.docs.first['type'] : '';

    // Compter les souvenirs
    final itemCount = await doc.reference.collection('media').count().get().then((snap) => snap.count ?? 0);

    return Album(
      id: albumId,
      userId: userId,
      name: name,
      thumbnailUrl: thumbnailUrl,
      thumbnailType: thumbnailType,
      itemCount: itemCount,
    );
  }

  @override
  bool operator ==(Object other) => identical(this, other) || (other is Album && id == other.id);

  @override
  int get hashCode => id.hashCode;
}
