import 'package:memories_project/features/memories/models/memory.dart';
import 'package:memories_project/core/notifiers/selected_items_notifier.dart';

import 'memories_crud_service.dart';
import 'memories_grouping_service.dart';

class MemoriesService {
  static final MemoriesService _instance = MemoriesService._internal();
  static MemoriesService get instance => _instance;
  MemoriesService._internal();

  final SelectedItemsNotifier<Memory> selectionNotifier = SelectedItemsNotifier<Memory>();
  final MemoriesCrudService crudService = MemoriesCrudService(
    memoriesSelectionNotifier: SelectedItemsNotifier<Memory>()
  );

  final MemoriesGroupingService groupingService = MemoriesGroupingService();

  Map<String, List<Memory>> memories = {};

  void toggleMemorySelection(Memory memory) => selectionNotifier.toggleSelection(memory);
  void clearMemorySelection() => selectionNotifier.clear();
  List<Memory> get selectedMemories => selectionNotifier.selectedItems.toList();

/// La logique de gestion du "mode gestion" (isManaging) est à déplacer ailleurs.
/// Ici je le retire car `SelectedItemsNotifier` est uniquement pour les éléments sélectionnés.
}
