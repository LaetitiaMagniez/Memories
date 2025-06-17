import 'package:flutter_riverpod/flutter_riverpod.dart';

class SelectedItemsNotifier<T> extends StateNotifier<Set<T>> {
  SelectedItemsNotifier() : super(<T>{});

  List<T> get selectedItems => state.toList();

  int get count => state.length;

  bool isSelected(T item) => state.contains(item);

  void toggleSelection(T item) {
    if (state.contains(item)) {
      unselect(item);
    } else {
      select(item);
    }
  }

  void select(T item) => state = {...state, item};

  void unselect(T item) {
    final updated = Set<T>.from(state);
    updated.remove(item);
    state = updated;
  }

  void selectMany(Iterable<T> items) => state = {...state, ...items};

  void unselectMany(Iterable<T> items) {
    final updated = Set<T>.from(state);
    updated.removeAll(items);
    state = updated;
  }

  void clear() => state = {};

  void toggleAll(Iterable<T> items) {
    final updated = Set<T>.from(state);
    for (final item in items) {
      if (updated.contains(item)) {
        updated.remove(item);
      } else {
        updated.add(item);
      }
    }
    state = updated;
  }
}
