import 'package:flutter/material.dart';
import 'package:memories_project/class/souvenir.dart';
import 'package:memories_project/service/firestore_service.dart';
import 'package:memories_project/service/souvenir_service.dart';
import '../../souvenir_view/full_screen_image_view.dart';
import '../../souvenir_view/video_thumbnail_widget.dart';
import '../../souvenir_view/video_viewer.dart';

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
  final SouvenirService souvenirService = SouvenirService();

  bool isManaging = false;
  List<Souvenir> selectedSouvenirs = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: isManaging
          ? AppBar(
        title: const Text("Gérer les souvenirs"),
        actions: [
          if (selectedSouvenirs.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () async {
                 souvenirService.confirmDeleteSelectedSouvenirs(
                  context,
                  widget.albumId,
                      () {
                    setState(() {
                      selectedSouvenirs.clear();
                      isManaging = false;
                    });
                  },
                  selectedSouvenirs,
                );
              },
            ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              setState(() {
                isManaging = false;
                selectedSouvenirs.clear();
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
      body: StreamBuilder<List<Souvenir>>(
        stream: firestoreService.getSouvenirsForMyAlbums(widget.albumId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text("Une erreur est survenue"));
          }

          final souvenirs = snapshot.data ?? [];

          if (souvenirs.isEmpty) {
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
                    itemCount: souvenirs.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 4,
                      crossAxisSpacing: 4,
                    ),
                    itemBuilder: (context, index) {
                      Souvenir souvenir = souvenirs[index];
                      bool isSelected = selectedSouvenirs.contains(souvenir);

                      return GestureDetector(
                        onTap: () {
                          if (isManaging) {
                            setState(() {
                              if (isSelected) {
                                selectedSouvenirs.remove(souvenir);
                              } else {
                                selectedSouvenirs.add(souvenir);
                              }
                            });
                          } else {
                            if (souvenir.type == 'image') {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => FullScreenImageView(url: souvenir.url),
                                ),
                              );
                            } else if (souvenir.type == 'video') {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => VideoViewer(souvenir.url),
                                ),
                              );
                            }
                          }
                        },
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: souvenir.type == 'image'
                                  ? Image.network(
                                souvenir.url,
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child, progress) {
                                  if (progress == null) return child;
                                  return const Center(child: CircularProgressIndicator());
                                },
                              )
                                  : VideoThumbnailWidget(souvenir.url),
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
        onPressed: () => souvenirService.showSouvenirOptions(
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
