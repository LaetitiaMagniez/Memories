import 'package:flutter/material.dart';
import 'package:memories_project/features/memories/models/album.dart';
import 'package:memories_project/features/memories/screens/album_details.dart';
import '../../../core/services/firestore_service.dart';
import '../../user/logic/contact_service.dart';
import '../../user/models/app_user.dart';
import '../logic/album_service.dart';
import '../widget/album_thumbnail.dart';

class AlbumListPage extends StatefulWidget {
  const AlbumListPage({super.key});

  @override
  _AlbumListPageState createState() => _AlbumListPageState();
}

class _AlbumListPageState extends State<AlbumListPage> {
  final FirestoreService firestoreService = FirestoreService();
  final AlbumService albumService = AlbumService();
  final ContactService contactService = ContactService();

  AppUser? _currentUser;
  bool isManaging = false;
  bool isLoading = false;

  @override
  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    _currentUser = await contactService.loadCurrentUser();
    setState(() {});
  }


  Widget _buildAlbumGrid(List<Album> albums) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 1.0,
            mainAxisSpacing: 0.5,
            crossAxisSpacing: 0.5,
          ),
          itemCount: albums.length,
          itemBuilder: (context, index) {
            Album album = albums[index];
            bool isSelected = albumService.selectedAlbums.contains(album);

            return GestureDetector(
              onTap: () {
                if (isManaging) {
                  albumService.toggleAlbumSelection(album, () {
                    setState(() {});
                  });
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          AlbumDetailPage(
                            albumId: album.id,
                            albumName: album.name,
                          ),
                    ),
                  );
                }
              },
              child: Stack(
                children: [
                  AlbumThumbnail(
                    album: album,
                    onTap: () {
                      if (isManaging) {
                        albumService.toggleAlbumSelection(album, () {
                          setState(() {});
                        });
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                AlbumDetailPage(
                                  albumId: album.id,
                                  albumName: album.name,
                                ),
                          ),
                        );
                      }
                    },
                    showInfo: true, // Ne pas afficher les informations de l'album
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
                          isSelected ? Icons.check_circle : Icons
                              .radio_button_unchecked,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: isManaging
        ? AppBar(
            title: const Text("Gérer les albums"),
            actions: [
              if (albumService.selectedAlbums.length == 1)
              IconButton(
                icon: const Icon(Icons.edit),
                tooltip: "Renommer l'album",
                onPressed: () {
                  albumService.renameAlbum(context, albumService.selectedAlbums.first);
                },
               ),
              if (albumService.selectedAlbums.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.delete),
                  tooltip: "Supprimer",
                  onPressed: () {
                    albumService.confirmDeleteSelectedAlbums(context, () {
                      setState(() {});
                    });
                  },
                ),
            IconButton(
              icon: const Icon(Icons.arrow_back),
              tooltip: "Retour",
                onPressed: () {
                  setState(() {
                    isManaging = false;
                  });
                },
            ),
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: "Annuler",
                onPressed: () {
                  setState(() {
                  albumService.clearSelection(() {
                    setState(() {});
                    });
                  });
                },
              ),
            ],
          )
          : null,
          body: DefaultTabController(
            length: 2,
            child: Column(
              children: [
                TabBar(
                  tabs: [
                    Tab(text: 'Mes albums'),
                    Tab(text: 'Albums partagés'),
                    ],
                  ),
              Expanded(
                child: TabBarView(
                  children: [
                  StreamBuilder<List<Album>>(
                  stream: firestoreService.getAlbumsWithDetails(),
                  builder: (context, snapshot) {

                    if (snapshot.connectionState == ConnectionState.waiting) {
                     return Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(child: Text('Une erreur est survenue'));
                    }

                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(
                        child: Text(
                          "Pas encore d'albums souvenirs, rajoutez en !",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                          ),
                        );
                        }
                    return _buildAlbumGrid(snapshot.data!);
                    },
                  ),
                  if (_currentUser != null)
                    StreamBuilder<List<Album>>(
                      stream: firestoreService.getSharedAlbumsForUser(_currentUser!.uid),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                        }

                        if (snapshot.hasError) {
                        return Center(child: Text('Une erreur est survenue'));
                        }

                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Center(
                        child: Text(
                        "Pas encore d'albums partagés avec vous",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                        ),
                        );
                        }
                    return _buildAlbumGrid(snapshot.data!);
                      },
                    ),
                  if(_currentUser == null)
                    Center(child: CircularProgressIndicator()),
                  ],
                ),
              ),
            ],
          ),
        ),
      floatingActionButton: isManaging
          ? null
          : FloatingActionButton(
        onPressed: () => albumService.showAlbumOptions(
          context,
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