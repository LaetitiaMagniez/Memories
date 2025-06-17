import 'package:memories_project/features/memories/models/memory.dart';

class MemoriesSelectionService {
  final List<Memory> _selectedMemories = [];
  bool _isManagingMemories = false;

  List<Memory> get selectedMemories => _selectedMemories;
  bool get isManagingMemories => _isManagingMemories;

  void toggleMemorySelection(Memory memory) {
    if (_isManagingMemories) {
      if (_selectedMemories.contains(memory)) {
        _selectedMemories.remove(memory);
      } else {
        _selectedMemories.add(memory);
      }
    }
  }

  void startManagingMemories() {
    _isManagingMemories = true;
    _selectedMemories.clear();
  }

  void stopManagingMemories() {
    _isManagingMemories = false;
    _selectedMemories.clear();
  }

  void clearSelection() {
    _selectedMemories.clear();
  }
}
