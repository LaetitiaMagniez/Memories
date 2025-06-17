import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memories_project/core/utils/cached_image.dart';
import 'package:memories_project/features/memories/models/memory.dart';
import 'package:memories_project/features/memories/widget/video/video_thumbnail_widget.dart';
import 'package:memories_project/features/memories/widget/video/video_viewer.dart';
import '../../../../core/providers/app_provider.dart';
import 'full_screen_image_view.dart';

class MemoryGridItem extends ConsumerWidget {
  final Memory memory;
  final bool isManaging;

  const MemoryGridItem({
    super.key,
    required this.memory,
    required this.isManaging,
  });

  void _onMemoryTap(BuildContext context) {
    if (memory.type == 'image') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => FullScreenImageView(url: memory.url),
        ),
      );
    } else if (memory.type == 'video') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VideoViewer(memory.url),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedItems = ref.watch(selectedMemoriesProvider);
    final selectedNotifier = ref.read(selectedMemoriesProvider.notifier);
    final isSelected = selectedItems.contains(memory);

    final memoriesCrudService = ref.read(memoriesCrudServiceProvider);
    final memoriesOptionsMenu = ref.read(memoriesOptionsMenuProvider);

    return GestureDetector(
      onTap: () {
        if (isManaging) {
          selectedNotifier.toggleSelection(memory);
        } else {
          _onMemoryTap(context);
        }
      },
      onLongPress: () {
        memoriesOptionsMenu.showOptionsForMemory(
          context: context,
          memory: memory,
          currentAlbumId: 'all_memories',
          deleteMemory: memoriesCrudService.deleteMemory,
          refreshUI: () {
            // À connecter proprement selon ton architecture de rafraîchissement global.
          },
        );
      },
      child: Stack(
        children: [
          Positioned.fill(
            child: memory.type == 'image'
                ? CachedImage(url: memory.url, fit: BoxFit.cover)
                : VideoThumbnailWidget(memory.url),
          ),
          if (isManaging)
            Container(
              decoration: BoxDecoration(
                color: isSelected ? Colors.deepPurple.withOpacity(0.3) : null,
                border: isSelected
                    ? Border.all(color: Colors.deepPurple, width: 2)
                    : null,
              ),
            ),
          if (isManaging)
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.8),
                ),
                child: Icon(
                  isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: isSelected ? Colors.deepPurple : Colors.grey,
                  size: 20,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
