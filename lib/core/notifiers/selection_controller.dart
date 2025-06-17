import 'package:flutter/material.dart';
import 'package:memories_project/core/notifiers/selected_items_notifier.dart';

class SelectionController<T> extends ChangeNotifier {
  bool _isManaging = false;
  final SelectedItemsNotifier<T> selectedItemsNotifier = SelectedItemsNotifier<T>();

  bool get isManaging => _isManaging;
  List<T> get selectedItems => selectedItemsNotifier.selectedItems;

  void startManaging() {
    if (!_isManaging) {
      _isManaging = true;
      selectedItemsNotifier.clear();
      notifyListeners();
    }
  }

  void stopManaging() {
    if (_isManaging) {
      _isManaging = false;
      selectedItemsNotifier.clear();
      notifyListeners();
    }
  }

  void toggleSelection(T item) {
    if (_isManaging) {
      selectedItemsNotifier.toggleSelection(item);
    }
  }

  bool isSelected(T item) => selectedItemsNotifier.isSelected(item);

  void clearSelection() => selectedItemsNotifier.clear();

  @override
  void dispose() {
    selectedItemsNotifier.dispose();
    super.dispose();
  }
}
