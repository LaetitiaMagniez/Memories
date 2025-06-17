import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memories_project/core/notifiers/selected_items_notifier.dart';
import 'package:memories_project/features/album/models/album.dart';
import 'package:memories_project/features/album/services/album_options_menu.dart';
import 'package:memories_project/features/album/views/album_details.dart';
import 'package:memories_project/features/album/widget/grid/album_grid_item.dart';
import 'package:mocktail/mocktail.dart';

class MockSelectedItemsNotifier extends Mock implements SelectedItemsNotifier<Album> {}

class MockAlbumOptionsMenu extends Mock implements AlbumOptionsMenu {}

void main() {
  late MockSelectedItemsNotifier mockSelectionNotifier;
  late MockAlbumOptionsMenu mockAlbumOptionsMenu;

  final testAlbum = Album(id: '1', name: 'Album 1', userId: 'ddzf', thumbnailUrl: 'dd', thumbnailType: 'dd', itemCount: 3);

  setUp(() {
    mockSelectionNotifier = MockSelectedItemsNotifier();
    mockAlbumOptionsMenu = MockAlbumOptionsMenu();

    // Setup des mocks : select/unselect ne font rien par défaut
    when(() => mockSelectionNotifier.select(any())).thenReturn(null);
    when(() => mockSelectionNotifier.unselect(any())).thenReturn(null);
  });

  Future<void> _buildWidget(
      WidgetTester tester, {
        required bool isManaging,
        required Set<Album> selectedAlbums,
      }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AlbumGridItem(
            album: testAlbum,
            isManaging: isManaging,
            albumSelectionNotifier: mockSelectionNotifier,
            onSelectionChanged: () {},
            albumOptionsMenu: mockAlbumOptionsMenu,
            selectedAlbums: selectedAlbums,
          ),
        ),
      ),
    );
  }

  testWidgets('Tap sélectionne l\'album si isManaging=true et pas sélectionné', (tester) async {
    await _buildWidget(tester, isManaging: true, selectedAlbums: {});

    await tester.tap(find.byType(AlbumGridItem));
    await tester.pump();

    verify(() => mockSelectionNotifier.select(testAlbum)).called(1);
    verifyNever(() => mockSelectionNotifier.unselect(any()));
  });

  testWidgets('Tap désélectionne l\'album si isManaging=true et déjà sélectionné', (tester) async {
    await _buildWidget(tester, isManaging: true, selectedAlbums: {testAlbum});

    await tester.tap(find.byType(AlbumGridItem));
    await tester.pump();

    verify(() => mockSelectionNotifier.unselect(testAlbum)).called(1);
    verifyNever(() => mockSelectionNotifier.select(any()));
  });

  testWidgets('Tap navigue vers AlbumDetailPage si isManaging=false', (tester) async {
    await _buildWidget(tester, isManaging: false, selectedAlbums: {});

    await tester.tap(find.byType(AlbumGridItem));
    await tester.pumpAndSettle();

    expect(find.byType(AlbumDetailPage), findsOneWidget);
    expect(find.text('Test Album'), findsOneWidget); // Si AlbumDetailPage affiche ce texte
  });

  testWidgets('Long press appelle albumOptionsMenu.showOptions', (tester) async {
    await _buildWidget(tester, isManaging: false, selectedAlbums: {});

    await tester.longPress(find.byType(AlbumGridItem));
    await tester.pump();

    verify(() => mockAlbumOptionsMenu.showOptions(
      any(),
      any(that: isA<List<Album>>()),
      any(that: isA<bool>()),
    )).called(1);
  });
}
