import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memories_project/features/album/models/album.dart';

class FakeDocumentReference extends Fake implements DocumentReference<Map<String, dynamic>> {}
class FakeCollectionReference extends Fake implements CollectionReference<Map<String, dynamic>> {}
class FakeQuerySnapshot extends Fake implements QuerySnapshot<Map<String, dynamic>> {}
class FakeQueryDocumentSnapshot extends Fake implements QueryDocumentSnapshot<Map<String, dynamic>> {}
class FakeAggregateQuerySnapshot extends Fake implements AggregateQuerySnapshot {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeDocumentReference());
    registerFallbackValue(FakeCollectionReference());
  });

  test('Album.fromSnapshotWithDetails parses Firestore document correctly', () async {
    final doc = Mock() as DocumentSnapshot<Map<String, dynamic>>;
    final ref = Mock() as DocumentReference<Map<String, dynamic>>;
    final mediaRef = Mock() as CollectionReference<Map<String, dynamic>>;
    final query = Mock() as Query<Map<String, dynamic>>;
    final querySnapshot = Mock() as QuerySnapshot<Map<String, dynamic>>;
    final mediaDoc = Mock() as QueryDocumentSnapshot<Map<String, dynamic>>;
    final aggregateQuery = Mock() as AggregateQuery;
    final aggregateSnapshot = Mock() as AggregateQuerySnapshot;

    // Stub values
    when(() => doc.id).thenReturn('album-id');
    when(() => doc.data()).thenReturn({'userId': 'user-123', 'name': 'Vacances'});
    when(() => doc.reference).thenReturn(ref);

    when(() => ref.collection('media')).thenReturn(mediaRef);
    when(() => mediaRef.orderBy('timestamp', descending: true)).thenReturn(query);
    when(() => query.limit(1)).thenReturn(query);
    when(() => query.get()).thenAnswer((_) async => querySnapshot);

    when(() => querySnapshot.docs).thenReturn([mediaDoc]);
    when(() => mediaDoc['url']).thenReturn('https://example.com/thumb.jpg');
    when(() => mediaDoc['type']).thenReturn('image');

    when(() => mediaRef.count()).thenReturn(aggregateQuery);
    when(() => aggregateQuery.get()).thenAnswer((_) async => aggregateSnapshot);
    when(() => aggregateSnapshot.count).thenReturn(5);

    // Appel
    final album = await Album.fromSnapshotWithDetails(doc);

    expect(album.id, 'album-id');
    expect(album.userId, 'user-123');
    expect(album.name, 'Vacances');
    expect(album.thumbnailUrl, 'https://example.com/thumb.jpg');
    expect(album.thumbnailType, 'image');
    expect(album.itemCount, 5);
  });
}
