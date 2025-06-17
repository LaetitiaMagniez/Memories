import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract class PaginatedCrudService<T> {
  void resetPagination();
  Future<List<T>> fetchNextPage({int limit = 10});
}

class PaginatedDataNotifier<T> extends StateNotifier<AsyncValue<List<T>>> {
  PaginatedDataNotifier(this.crudService) : super(const AsyncLoading());

  final PaginatedCrudService<T> crudService;

  bool _hasMore = true;

  Future<void> loadInitial({int limit = 10}) async {
    state = const AsyncLoading();
    crudService.resetPagination();
    _hasMore = true;

    try {
      final items = await crudService.fetchNextPage(limit: limit);
      _hasMore = items.isNotEmpty;
      state = AsyncData(items);
    } catch (e, stackTrace) {
      state = AsyncError(e, stackTrace);
    }
  }

  Future<void> fetchNext({int limit = 10}) async {
    if (!_hasMore || state is! AsyncData<List<T>>) return;

    final currentItems = state.asData!.value;

    try {
      final newItems = await crudService.fetchNextPage(limit: limit);
      _hasMore = newItems.isNotEmpty;
      state = AsyncData([...currentItems, ...newItems]);
    } catch (_) {}
  }

  bool get hasMore => _hasMore;
}
