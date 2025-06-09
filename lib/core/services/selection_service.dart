import 'package:flutter/material.dart';

class SelectionService<T> extends ChangeNotifier {
  bool _isManaging = false;
  final List<T> _selectedItems = [];

  bool get isManaging => _isManaging;
  List<T> get selectedItems => List.unmodifiable(_selectedItems);

  void startManaging() {
    _isManaging = true;
    _selectedItems.clear();
    notifyListeners();
  }

  void stopManaging() {
    _isManaging = false;
    _selectedItems.clear();
    notifyListeners();
  }

  void toggleSelection(T item) {
    if (!_isManaging) return;

    if (_selectedItems.contains(item)) {
      _selectedItems.remove(item);
    } else {
      _selectedItems.add(item);
    }
    notifyListeners();
  }

  void clear() {
    _selectedItems.clear();
    notifyListeners();
  }

  bool isSelected(T item) => _selectedItems.contains(item);
}
