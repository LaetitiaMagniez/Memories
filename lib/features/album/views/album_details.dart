import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memories_project/features/memories/services/memories_crud_service.dart';
import 'package:memories_project/features/memories/services/memories_dialogs.dart';
import '../../../core/providers/app_provider.dart';
import '../../../core/widgets/loading/upload_progress_bubble.dart';
import '../../memories/models/memory.dart';
import '../../memories/services/memories_options_menu.dart';
import '../../memories/widget/memory/full_screen_image_view.dart';
import '../../memories/widget/video/video_viewer.dart';
import '../services/album_repository.dart';
import '../widget/album/album_detail_body.dart';

class AlbumDetailsPage extends ConsumerStatefulWidget {
  final String albumId;
  final String albumName;

  const AlbumDetailsPage({
    super.key,
    required this.albumId,
    required this.albumName,
  });

  @override
  _AlbumDetailsPageState createState() => _AlbumDetailsPageState();
}

class _AlbumDetailsPageState extends ConsumerState<AlbumDetailsPage> {
  final albumRepository = AlbumRepository();
  final memoriesDialogs = MemoriesDialogs();
  final memoriesOptionsMenu = MemoriesOptionsMenu();

  bool isManaging = false;
  double uploadProgress = 0.0;
  bool isUploading = false;
  bool waitingForUploadDisplay = false;
  String? lastUploadedUrl;

  List<Memory> currentMemories = [];
  late final StreamSubscription<List<Memory>> _memoriesSubscription;

  late MemoriesCrudService memoriesCrudService;

  @override
  void initState() {
    super.initState();
    memoriesCrudService = MemoriesCrudService(
      memoriesSelectionNotifier: ref.read(selectedMemoriesProvider.notifier),
    );

    _memoriesSubscription = albumRepository.getMemoriesForMyAlbums(widget.albumId).listen((memories) {
      setState(() {
        currentMemories = memories;
      });
    });
  }


  @override
  void dispose() {
    _memoriesSubscription.cancel();
    super.dispose();
  }


  void _toggleMemorySelection(Memory memory) {
    ref.read(selectedMemoriesProvider.notifier).toggleSelection(memory);
    setState(() {});
  }

  Future<void> moveSelectedMemories() async {
    final selectionNotifier = ref.read(selectedMemoriesProvider.notifier);
    await memoriesDialogs.moveSelectedMemories(
      context,
      widget.albumId,
      selectionNotifier,
      memoriesCrudService.deleteMemory,
          () {
        setState(() {
          isManaging = false;
        });
      },
    );
    selectionNotifier.clear();
    setState(() {
      isManaging = false;
    });
  }

  void _onMemoryTap(Memory memory) {
    if (isManaging) {
      _toggleMemorySelection(memory);
    } else {
      if (memory.type == 'image') {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => FullScreenImageView(url: memory.url)),
        );
      } else if (memory.type == 'video') {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => VideoViewer(memory.url)),
        );
      }
    }
  }

  void onManageMemory() {
    setState(() {
      isManaging = true;
    });
  }

  void _exitManaging() {
    setState(() {
      isManaging = false;
    });
    ref.read(selectedMemoriesProvider.notifier).clear();
  }

  @override
  Widget build(BuildContext context) {
    final selectedMemories = ref.watch(selectedMemoriesProvider);

    return Scaffold(
      appBar: isManaging
          ? AppBar(
        title: const Text("Gérer les souvenirs"),
        actions: [
          if (selectedMemories.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.move_to_inbox),
              onPressed: moveSelectedMemories,
            ),
          if (selectedMemories.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () async {
                await memoriesDialogs.confirmDeleteSelectedMemories(
                  context,
                  widget.albumId,
                  ref.read(selectedMemoriesProvider.notifier),
                  memoriesCrudService.deleteMemory,
                  _exitManaging,
                );
              },
            ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: _exitManaging,
          ),
        ],
      )
          : AppBar(
        title: Text(
          widget.albumName,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
      ),
      body: Stack(
        children: [
          if (currentMemories.isEmpty && !isUploading)
            const Center(child: CircularProgressIndicator())
          else
            AlbumDetailBody(
              memories: currentMemories,
              isManaging: isManaging,
              // Plus besoin de passer un service, on peut passer la sélection et toggle
              selectionNotifier: ref.read(selectedMemoriesProvider.notifier),
              selectedMemories: selectedMemories,
              onMemoryTap: _onMemoryTap,
            ),
          if (isUploading)
            Container(
              color: Colors.black.withOpacity(0.4),
              child: Center(
                child: UploadProgressBubble(progress: uploadProgress),
              ),
            ),
        ],
      ),
      floatingActionButton: isManaging
          ? null
          : FloatingActionButton(
        onPressed: () => memoriesOptionsMenu.showMemoriesOptions(
          context,
          widget.albumId,
          onManageMemory,
          onUploadStart: () => setState(() => isUploading = true),
          onUploadProgress: (progress) => setState(() => uploadProgress = progress),
          onUploadFinish: (String uploadedUrl) {
            setState(() {
              uploadProgress = 1.0;
              waitingForUploadDisplay = true;
              lastUploadedUrl = uploadedUrl;
            });
          },
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}
