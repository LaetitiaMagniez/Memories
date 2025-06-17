import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memories_project/features/album/models/album.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

// Génère le mock de DocumentSnapshot
@GenerateMocks([DocumentSnapshot])
import 'album_test.mocks.dart';

void main() {
  group('Album', () {
    test('Album.empty() should create an empty Album with the given id', () {
      final album = Album.empty('test_id');

      expect(album.id, 'test_id');
      expect(album.userId, '');
      expect(album.name, '');
      expect(album.thumbnailUrl, '');
      expect(album.thumbnailType, '');
      expect(album.itemCount, 0);
    });

    test('Album.fromFirestore() should create Album from Firestore document', () {
      final mockDoc = MockDocumentSnapshot();

      when(mockDoc.id).thenReturn('doc_id');
      when(mockDoc.data()).thenReturn({
        'userId': 'user_123',
        'name': 'My Album',
      });

      final album = Album.fromFirestore(mockDoc);

      expect(album.id, 'doc_id');
      expect(album.userId, 'user_123');
      expect(album.name, 'My Album');
      expect(album.thumbnailUrl, '');
      expect(album.thumbnailType, '');
      expect(album.itemCount, 0);
    });

    test('Albums with the same id should be equal', () {
      final album1 = Album.empty('same_id');
      final album2 = Album.empty('same_id');

      expect(album1, equals(album2));
      expect(album1.hashCode, equals(album2.hashCode));
    });

    test('Albums with different ids should not be equal', () {
      final album1 = Album.empty('id_1');
      final album2 = Album.empty('id_2');

      expect(album1, isNot(equals(album2)));
    });
  });
}
