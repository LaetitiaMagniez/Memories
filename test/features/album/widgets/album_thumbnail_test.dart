import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memories_project/features/album/models/album.dart';
import 'package:memories_project/features/album/widget/album/album_thumbnail.dart';

void main() {
  group('AlbumThumbnail Widget', () {
    testWidgets('displays album name and item count', (WidgetTester tester) async {
      final album = Album(
        id: '1',
        name: 'Vacances',
        itemCount: 3,
        thumbnailType: 'image',
        thumbnailUrl: 'https://dummyimage.com/300x300',
        userId: 'dummy_user_id',
      );

      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: AlbumThumbnail(
            album: album,
            onTap: () {
              tapped = true;
            },
          ),
        ),
      );

      expect(find.text('Vacances'), findsOneWidget);
      expect(find.text('3 éléments'), findsOneWidget);

      await tester.tap(find.byType(AlbumThumbnail));
      expect(tapped, true);
    });

    testWidgets('shows shimmer for unknown thumbnailType', (WidgetTester tester) async {
      final album = Album(
        id: '2',
        name: 'Inconnu',
        itemCount: 1,
        thumbnailType: 'unknown',
        thumbnailUrl: '',
        userId: 'dummy_user_id',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: AlbumThumbnail(
            album: album,
            onTap: () {},
          ),
        ),
      );

      // Le shimmer est un container blanc, difficile à cibler,
      // mais on peut chercher qu'aucune image/vidéo n'est présente :
      expect(find.byType(Image), findsNothing);
    });
  });
}
