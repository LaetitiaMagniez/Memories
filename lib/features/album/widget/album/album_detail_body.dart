import 'package:flutter/cupertino.dart';
import '../../../../core/notifiers/selected_items_notifier.dart';
import '../../../memories/models/memory.dart';
import '../../../memories/widget/memory/memory_grid_item.dart';

class AlbumDetailBody extends StatelessWidget {
  final List<Memory> memories;
  final bool isManaging;
  final SelectedItemsNotifier<Memory> selectionNotifier;
  final Set<Memory> selectedMemories;
  final void Function(Memory) onMemoryTap;

  const AlbumDetailBody({
    super.key,
    required this.memories,
    required this.isManaging,
    required this.selectionNotifier,
    required this.selectedMemories,
    required this.onMemoryTap,
  });

  @override
  Widget build(BuildContext context) {
    if (memories.isEmpty) {
      return const Center(child: Text("Pas de souvenirs dans cet album"));
    }

    return Column(
      children: [
        if (isManaging) const SizedBox(height: 8),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: GridView.builder(
              itemCount: memories.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
              ),
              itemBuilder: (context, index) {
                final memory = memories[index];
                return MemoryGridItem(
                  memory: memory,
                  isManaging: isManaging,
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
