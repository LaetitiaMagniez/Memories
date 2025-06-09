import 'dart:async';

import 'package:flutter/material.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/widgets/loading/upload_progress_bubble.dart';
import '../logic/memories/memories_service.dart';
import '../models/memory.dart';
import '../widget/album/album_detail_body.dart';
import '../widget/full_screen_image_view.dart';
import '../widget/video/video_viewer.dart';

class AlbumDetailPage extends StatefulWidget {
  final String albumId;
  final String albumName;

  const AlbumDetailPage({
    super.key,
    required this.albumId,
    required this.albumName,
  });

  @override
  _AlbumDetailPageState createState() => _AlbumDetailPageState();
}

class _AlbumDetailPageState extends State<AlbumDetailPage> {
  final firestoreService = FirestoreService();
  final memoriesService = MemoriesService();

  bool isManaging = false;
  double uploadProgress = 0.0;
  bool isUploading = false;
  bool waitingForUploadDisplay = false;
  String? lastUploadedUrl;

  List<Memory> currentMemories = [];
  late final Stream<List<Memory>> memoriesStream;
  late final StreamSubscription<List<Memory>> _memoriesSubscription;

  @override
  void initState() {
    super.initState();
    memoriesStream = firestoreService.getMemoriesForMyAlbums(widget.albumId);
    _memoriesSubscription = memoriesStream.listen((memories) {
      setState(() {
        currentMemories = memories;
      });

      // On vérifie si la dernière mémoire uploadée est visible
      if (waitingForUploadDisplay && lastUploadedUrl != null) {
        final isDisplayed = memories.any((m) => m.url == lastUploadedUrl);
        if (isDisplayed) {
          // On attend 500 ms puis on reset
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              setState(() {
                isUploading = false;
                uploadProgress = 0.0;
                waitingForUploadDisplay = false;
                lastUploadedUrl = null;
              });
            }
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _memoriesSubscription.cancel();
    super.dispose();
  }

  void _toggleMemorySelection(Memory memory) {
    memoriesService.toggleMemorySelection(memory);
    setState(() {});
  }

  Future<void> moveSelectedMemories() async {
    await memoriesService.moveSelectedMemories(context, widget.albumId);
    setState(() {});
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: isManaging
          ? AppBar(
        title: const Text("Gérer les souvenirs"),
        actions: [
          if (memoriesService.selectedMemories.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.move_to_inbox),
              onPressed: moveSelectedMemories,
            ),
          if (memoriesService.selectedMemories.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () async {
                memoriesService.confirmDeleteSelectedMemories(
                  context,
                  widget.albumId,
                      () {
                    setState(() {
                      memoriesService.selectedMemories.clear();
                      isManaging = false;
                    });
                  },
                );
              },
            ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              setState(() {
                isManaging = false;
                memoriesService.selectedMemories.clear();
              });
            },
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
              memoriesService: memoriesService,
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
        onPressed: () => memoriesService.showMemoriesOptions(
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
