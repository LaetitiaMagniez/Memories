import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memories_project/features/album/widget/album/album_management_bar.dart';
import 'package:memories_project/features/album/models/album.dart';
import 'package:mockito/mockito.dart';

import '../../../mocks/album_service_mock.mocks.dart';

void main() {
  late MockSelectionService<Album> mockAlbumSelectionService;
  late MockAlbumDialogs mockAlbumDialogs;

  bool onUpdateCalled = false;
  bool onExitManagingCalled = false;
  bool onSelectionClearedCalled = false;

  final testAlbum = Album(
    id: 'album1',
    name: 'Test Album',
    itemCount: 5,
    thumbnailUrl: '',
    thumbnailType: 'image',
    userId: 'test',
  );

  Widget buildTestWidget() {
    return MaterialApp(
      home: Scaffold(
        appBar: AlbumManagementBar(
          albumDialog: mockAlbumDialogs,
          albumSelectionService: mockAlbumSelectionService,
          onExitManaging: () => onExitManagingCalled = true,
          onSelectionCleared: () => onSelectionClearedCalled = true,
          onUpdate: () => onUpdateCalled = true,
        ),
      ),
    );
  }

  setUp(() {
    mockAlbumSelectionService = MockSelectionService<Album>();
    mockAlbumDialogs = MockAlbumDialogs();
    onUpdateCalled = false;
    onExitManagingCalled = false;
    onSelectionClearedCalled = false;
  });

  testWidgets('simulate rename and confirm delete', (tester) async {
    when(mockAlbumSelectionService.selectedItems).thenReturn([testAlbum]);

    when(mockAlbumDialogs.renameAlbum(any, any)).thenAnswer((_) async {});
    when(mockAlbumDialogs.confirmDeleteSelectedAlbums(any, any, any)).thenAnswer((invocation) {
      final callback = invocation.positionalArguments[2] as VoidCallback;
      callback();
      return Future.value();
    });

    await tester.pumpWidget(buildTestWidget());

    await tester.tap(find.byIcon(Icons.edit));
    await tester.pumpAndSettle();
    verify(mockAlbumDialogs.renameAlbum(any, testAlbum)).called(1);

    await tester.tap(find.byIcon(Icons.delete));
    await tester.pumpAndSettle();
    verify(mockAlbumDialogs.confirmDeleteSelectedAlbums(any, mockAlbumSelectionService, any)).called(1);
    expect(onUpdateCalled, isTrue);
  });

  testWidgets('tap on back arrow calls onExitManaging', (tester) async {
    when(mockAlbumSelectionService.selectedItems).thenReturn([]);

    await tester.pumpWidget(buildTestWidget());

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    expect(onExitManagingCalled, isTrue);
  });

  testWidgets('tap on close icon calls onSelectionCleared', (tester) async {
    when(mockAlbumSelectionService.selectedItems).thenReturn([]);

    await tester.pumpWidget(buildTestWidget());

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(onSelectionClearedCalled, isTrue);
  });

  testWidgets('edit and delete buttons hidden when no selection', (tester) async {
    when(mockAlbumSelectionService.selectedItems).thenReturn([]);

    await tester.pumpWidget(buildTestWidget());

    expect(find.byIcon(Icons.edit), findsNothing);
    expect(find.byIcon(Icons.delete), findsNothing);
  });

  testWidgets('edit button is not shown when multiple albums selected', (tester) async {
    when(mockAlbumSelectionService.selectedItems).thenReturn([
      Album(id: 'album1', name: 'Album 1', itemCount: 5, thumbnailUrl: '', thumbnailType: 'image', userId: 'test'),
      Album(id: 'album2', name: 'Album 2', itemCount: 3, thumbnailUrl: '', thumbnailType: 'image', userId: 'test'),
    ]);

    await tester.pumpWidget(buildTestWidget());

    expect(find.byIcon(Icons.edit), findsNothing);
    expect(find.byIcon(Icons.delete), findsOneWidget);
  });
}
