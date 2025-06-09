import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memories_project/features/album/models/album.dart';
import 'package:memories_project/features/album/widget/grid/album_grid.dart';
import 'package:mockito/mockito.dart';
import '../../../../mocks/album_service_mock.mocks.dart';

void main() {
  testWidgets('AlbumGrid displays albums correctly', (WidgetTester tester) async {
    final mockAlbumSelectionService = MockSelectionService<Album>();

    final albums = [
      Album(id: '1', name: 'Vacances', itemCount: 10, thumbnailUrl: '', thumbnailType: 'image', userId: 'dummy_user_id'),
      Album(id: '2', name: 'Famille', itemCount: 5, thumbnailUrl: '', thumbnailType: 'image', userId: 'dummy_user_id'),
    ];

    when(mockAlbumSelectionService.selectedItems).thenReturn([]);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AlbumGrid(
            albums: albums,
            isManaging: true,
            albumSelectionService: mockAlbumSelectionService,
            onSelectionChanged: () {},
          ),
        ),
      ),
    );

    expect(find.text('Vacances'), findsOneWidget);
    expect(find.text('Famille'), findsOneWidget);
  });
}
