import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memories_project/core/providers/app_providers.dart';
import 'package:memories_project/features/album/models/album.dart';
import 'package:memories_project/features/memories/models/memory.dart';
import 'package:memories_project/core/services/selection_service.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
  });

  tearDown(() {
    container.dispose();
  });

  test('All providers should be properly instantiated', () {
    expect(container.read(albumRepositoryProvider), isNotNull);
    expect(container.read(contactServiceProvider), isNotNull);
    expect(container.read(friendsNotifierProvider), isNotNull);
    expect(container.read(AlbumSelectionService), isNotNull);
    expect(container.read(MemorySelectionService), isNotNull);
    expect(container.read(albumListViewModelProvider), isNotNull);
  });

  test('SelectionService<Album> should manage selections properly', () {
    final selectionService = container.read(AlbumSelectionService);

    Album album1 = Album(id: '1', name: 'Album 1', userId: 'ff', thumbnailUrl: 'd.com', thumbnailType: 'image', itemCount: 2);
    Album album2 = Album(id: '2', name: 'Album 2', userId: 'ff', thumbnailUrl: 'ddd.com', thumbnailType: 'image', itemCount: 4);

    selectionService.startManaging();
    selectionService.toggleSelection(album1);
    selectionService.toggleSelection(album2);

    expect(selectionService.selectedItems, containsAll([album1, album2]));

    selectionService.toggleSelection(album1);
    expect(selectionService.selectedItems, isNot(contains(album1)));

    selectionService.stopManaging();
    expect(selectionService.selectedItems, isEmpty);
  });

  test('SelectionService<Memory> should manage selections properly', () {
    final selectionService = container.read(MemorySelectionService);

    final memory1 = Memory(id: '1', url: 'url1', type: 'image', ville: 'Paris', date: DateTime.now());
    final memory2 = Memory(id: '2', url: 'url2', type: 'video', ville: 'Lyon', date: DateTime.now());

    selectionService.startManaging();
    selectionService.toggleSelection(memory1);
    selectionService.toggleSelection(memory2);

    expect(selectionService.selectedItems, containsAll([memory1, memory2]));

    selectionService.clear();
    expect(selectionService.selectedItems, isEmpty);
  });
}
