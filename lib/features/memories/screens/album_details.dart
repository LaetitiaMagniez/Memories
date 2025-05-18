import 'package:flutter/material.dart';
import 'package:memories_project/features/memories/logic/memories_service.dart';
import '../../../core/services/firestore_service.dart';
import '../models/memory.dart';
import '../widget/full_screen_image_view.dart';
import '../widget/video_thumbnail_widget.dart';
import '../widget/video_viewer.dart';

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
  final FirestoreService firestoreService = FirestoreService();
  final MemoriesService memoriesService = MemoriesService();

  bool isManaging = false;
  List<Memory> selectedMemories = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: isManaging
          ? AppBar(
        title: const Text("Gérer les souvenirs"),
        actions: [
          if (selectedMemories.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () async {
                memoriesService.confirmDeleteSelectedMemories(
                  context,
                  widget.albumId,
                      () {
                    setState(() {
                      selectedMemories.clear();
                      isManaging = false;
                    });
                  },
                  selectedMemories,
                );
              },
            ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              setState(() {
                isManaging = false;
                selectedMemories.clear();
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
      body: StreamBuilder<List<Memory>>(
        stream: firestoreService.getMemoriesForMyAlbums(widget.albumId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text("Une erreur est survenue"));
          }

          final memories = snapshot.data ?? [];

          if (memories.isEmpty) {
            return const Center(child: Text("Pas de souvenirs dans cet album"));
          }

          return Column(
            children: [
              if (isManaging)
                Container(
                  padding: const EdgeInsets.all(12),
                  width: double.infinity,
                  color: Colors.white,
                  child: const Text(
                    "Touchez un ou plusieurs souvenirs pour les gérer (déplacer ou supprimer).",
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              const SizedBox(height: 12),
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
                      Memory memory = memories[index];
                      bool isSelected = selectedMemories.contains(memory);

                      return GestureDetector(
                        onTap: () {
                          if (isManaging) {
                            setState(() {
                              if (isSelected) {
                                selectedMemories.remove(memory);
                              } else {
                                selectedMemories.add(memory);
                              }
                            });
                          } else {
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
                        },
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: memory.type == 'image'
                                  ? Image.network(
                                memory.url,
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child, progress) {
                                  if (progress == null) return child;
                                  return const Center(child: CircularProgressIndicator());
                                },
                              )
                                  : VideoThumbnailWidget(memory.url),
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
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: isManaging
          ? null
          : FloatingActionButton(
        onPressed: () => memoriesService.showMemoriesOptions(
          context,
          widget.albumId,
              () {
            setState(() {
              isManaging = true;
            });
          },
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}
