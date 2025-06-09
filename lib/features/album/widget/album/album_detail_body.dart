import 'package:flutter/cupertino.dart';
import '../../../memories/logic/memories/memories_service.dart';
import '../../../memories/models/memory.dart';
import '../../../memories/widget/memory/memory_grid_item.dart';

class AlbumDetailBody extends StatelessWidget {
  final List<Memory> memories; // au lieu du Stream
  final bool isManaging;
  final MemoriesService memoriesService;
  final void Function(Memory memory) onMemoryTap;

  const AlbumDetailBody({
    super.key,
    required this.memories,
    required this.isManaging,
    required this.memoriesService,
    required this.onMemoryTap,
  });

  @override
  Widget build(BuildContext context) {
    if (memories.isEmpty) {
      return const Center(child: Text("Pas de souvenirs dans cet album"));
    }

    return Column(
      children: [
        if (isManaging)
          const SizedBox(height: 8),
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
                final isSelected = memoriesService.selectedMemories.contains(memory);
                return MemoryGridItem(
                  memory: memory,
                  isManaging: isManaging,
                  isSelected: isSelected,
                  onTap: () => onMemoryTap(memory),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
