import 'package:flutter/material.dart';
import 'package:memories_project/class/album.dart';
import 'package:memories_project/screens/album/album_details.dart';
import 'package:memories_project/service/album_service.dart';
import 'package:memories_project/service/firestore_service.dart';
import 'album_thumbnail.dart';

class AlbumListPage extends StatelessWidget {
  final FirestoreService firestoreService = FirestoreService();
  final AlbumService albumService = AlbumService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<List<Album>>(
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

          return GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.8,
            ),
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                Album album = snapshot.data![index];
                return GestureDetector(
                  onLongPress: () => albumService.showAlbumOptions(context, album),
                  child: AlbumThumbnail(
                    album: album, 
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AlbumDetailPage(
                            albumId: album.id,
                            albumName: album.name,
                                ),
                              ),
                            );
                    },
                  )
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
  onPressed: () => albumService.showCreateAlbumDialog(context),
  child: Icon(Icons.add),
),
    );
  }
}
