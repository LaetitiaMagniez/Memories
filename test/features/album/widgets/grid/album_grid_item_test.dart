import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memories_project/features/album/models/album.dart';
import 'package:memories_project/features/album/widget/grid/album_grid_item.dart';
import 'package:mockito/mockito.dart';
import '../../../../mocks/album_service_mock.mocks.dart';


void main() {
  testWidgets('AlbumGridItem displays album info and selection icon', (WidgetTester tester) async {
      final mockAlbumSelectionService = MockSelectionService<Album>();

      final album = Album(
        id: '1',
        name: 'Test Album',
        itemCount: 3,
        thumbnailUrl: '',
        thumbnailType: 'image',
        userId: 'dummy_user_id'
      );
      when(mockAlbumSelectionService.selectedItems).thenReturn([]);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AlbumGridItem(
              album: album,
              isManaging: true,
              albumSelectionService: mockAlbumSelectionService,
              onSelectionChanged: () {  },
            ),
          ),
        ),
      );

      // Vérifie que le nom de l'album s'affiche
      expect(find.text('Test Album'), findsOneWidget);
      expect(find.text('3 éléments'), findsOneWidget);

      // Vérifie que l'icône de sélection est là
      expect(find.byIcon(Icons.radio_button_unchecked), findsOneWidget);
    });
}
