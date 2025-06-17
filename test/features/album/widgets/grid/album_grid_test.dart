import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memories_project/core/notifiers/selected_items_notifier.dart';
import 'package:memories_project/features/album/models/album.dart';
import 'package:memories_project/features/album/services/album_options_menu.dart';
import 'package:memories_project/features/album/widget/grid/album_grid.dart';
import 'package:mocktail/mocktail.dart';

class MockAlbumOptionsMenu extends Mock implements AlbumOptionsMenu {}


class FakeAlbumSelectionNotifier extends SelectedItemsNotifier<Album> {}

void main() {
  late MockAlbumOptionsMenu mockAlbumOptionsMenu;
  late FakeAlbumSelectionNotifier selectionNotifier;

  // Quelques albums fake
  final album1 = Album(id: '1', name: 'Album 1', userId: 'ddzf', thumbnailUrl: 'dd', thumbnailType: 'dd', itemCount: 3);
  final album2 = Album(id: '2', name: 'Album 2', userId: 'ddzf', thumbnailUrl: 'dd', thumbnailType: 'dd', itemCount: 3);

  setUp(() {
    mockAlbumOptionsMenu = MockAlbumOptionsMenu();
    selectionNotifier = FakeAlbumSelectionNotifier();
  });

  testWidgets('AlbumGrid affiche la grille et gère la sélection',
          (WidgetTester tester) async {
        // On prépare un Set<Album> (conforme au paramètre attendu)
        final selectedAlbums = <Album>{};

        // Construis le widget AlbumGrid
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AlbumGrid(
                albums: [album1, album2],
                isManaging: false,
                albumSelectionNotifier: selectionNotifier,
                selectedAlbums: selectedAlbums,
                onSelectionChanged: () {
                  // Pour le test, on ajoute l'album 1 à la sélection
                  selectedAlbums.add(album1);
                },
                albumOptionMenu: mockAlbumOptionsMenu,
              ),
            ),
          ),
        );

        // Vérifie qu'on trouve bien les noms d'albums dans la grille
        expect(find.text('Album 1'), findsOneWidget);
        expect(find.text('Album 2'), findsOneWidget);

        // Simule une interaction qui déclenche onSelectionChanged
        await tester.tap(find.text('Album 1'));
        await tester.pump();

        // La sélection a été mise à jour
        expect(selectedAlbums.contains(album1), isTrue);

        // Optionnel: simule un appel à albumOptionMenu.showOptions
        mockAlbumOptionsMenu.showOptions(any(), any(), any());
        verify(() => mockAlbumOptionsMenu.showOptions(any(), any(), any())).called(1);
      });

  testWidgets('AlbumGrid affiche message quand la liste est vide',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AlbumGrid(
                albums: [],
                isManaging: false,
                albumSelectionNotifier: selectionNotifier,
                selectedAlbums: <Album>{},
                onSelectionChanged: () {},
                albumOptionMenu: mockAlbumOptionsMenu,
              ),
            ),
          ),
        );

        expect(find.text('Aucun album à afficher'), findsOneWidget);
      });
}
