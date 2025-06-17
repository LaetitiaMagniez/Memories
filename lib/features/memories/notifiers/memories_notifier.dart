import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/memory.dart';
import '../services/memories_crud_service.dart';

class MemoriesNotifier extends StateNotifier<AsyncValue<List<Memory>>> {
  MemoriesNotifier(this.crudService) : super(const AsyncLoading());

  final MemoriesCrudService crudService;

  bool _hasMore = true;

  Future<void> loadInitialMemories() async {
    state = const AsyncLoading();
    crudService.resetPagination();
    _hasMore = true;

    try {
      final memories = await crudService.fetchNextMemoriesPage(albumLimit: 10);
      _hasMore = memories.isNotEmpty;
      state = AsyncData(memories);
    } catch (e, stackTrace) {
      state = AsyncError(e, stackTrace);
    }
  }

  Future<void> fetchNextPage() async {
    if (!_hasMore || state is! AsyncData<List<Memory>>) return;

    final currentMemories = state.asData!.value;

    try {
      final newMemories = await crudService.fetchNextMemoriesPage(albumLimit: 10);
      _hasMore = newMemories.isNotEmpty;
      state = AsyncData([...currentMemories, ...newMemories]);
    } catch (e) {

    }
  }


  bool get hasMore => _hasMore;
}
