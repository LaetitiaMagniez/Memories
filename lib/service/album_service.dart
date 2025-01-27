import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:memories_project/album/album_class.dart';
import 'package:memories_project/album/album_details.dart';
import 'package:memories_project/album/album_list.dart';
import 'package:memories_project/transition/loadingScreen.dart';

class AlbumService {
  
  void showAlbumOptions(BuildContext context, Album album) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.edit),
                title: Text('Renommer l\'album'),
                onTap: () {
                  Navigator.pop(context); // Ferme le menu
                  renameAlbum(context, album);
                },
              ),
              ListTile(
                leading: Icon(Icons.delete),
                title: Text('Supprimer l\'album'),
                onTap: () {
                  Navigator.pop(context); // Ferme le menu
                  _confirmDeleteAlbum(context, album);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void renameAlbum(BuildContext context, Album album) {
    final TextEditingController _controller = TextEditingController(text: album.name);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Renommer l\'album'),
          content: TextField(
            controller: _controller,
            decoration: InputDecoration(hintText: "Nouveau nom de l'album"),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Annuler'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('Renommer'),
              onPressed: () async {
                if (_controller.text.isNotEmpty) {
                  await FirebaseFirestore.instance.collection('albums').doc(album.id).update({
                    'name': _controller.text,
                  });
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

void _confirmDeleteAlbum(BuildContext context, Album album) {
  // Obtiens un contexte parent stable avant de commencer
  final scaffoldContext = Navigator.of(context).context;

  showDialog(
    context: scaffoldContext,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Confirmer la suppression'),
        content: Text('Voulez-vous vraiment supprimer cet album ?'),
        actions: <Widget>[
          TextButton(
            child: Text('Annuler'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: Text('Supprimer'),
            onPressed: () async {
              // Ferme la boîte de dialogue
              Navigator.of(context).pop();

              // Affiche un écran de chargement
              showDialog(
                context: scaffoldContext,
                barrierDismissible: false,
                builder: (BuildContext context) {
                  return LoadingScreen(message: 'Suppression de l\'album en cours...');
                },
              );

              try {
                // Supprime l'album
                await deleteAlbum(album.id);
              } catch (e) {
                print('Erreur pendant la suppression : $e');
              } finally {
                // Ferme l'écran de chargement
                Navigator.of(scaffoldContext).pop();

                // Navigue vers la liste des albums
                Navigator.pushReplacement(
                  scaffoldContext,
                  MaterialPageRoute(builder: (context) => AlbumListPage()),
                );
              }
            },
          ),
        ],
      );
    },
  );
}


  Future<void> deleteAlbum(String albumId) async {
  // Récupérer tous les médias de l'album
  QuerySnapshot mediaSnapshot = await FirebaseFirestore.instance
      .collection('albums')
      .doc(albumId)
      .collection('media')
      .get();

  // Supprimer chaque fichier média de Firebase Storage
  for (var doc in mediaSnapshot.docs) {
    String mediaUrl = doc['url'];
    Reference storageRef = FirebaseStorage.instance.refFromURL(mediaUrl);
    await storageRef.delete();
  }

  // Supprimer tous les documents média de la sous-collection
  WriteBatch batch = FirebaseFirestore.instance.batch();
  for (var doc in mediaSnapshot.docs) {
    batch.delete(doc.reference);
  }
  await batch.commit();

  // Supprimer le document de l'album
  await FirebaseFirestore.instance.collection('albums').doc(albumId).delete();
}


  void showCreateAlbumDialog(BuildContext context) {
    final TextEditingController _controller = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Créer un nouvel album'),
          content: TextField(
            controller: _controller,
            decoration: InputDecoration(hintText: "Nom de l'album"),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Annuler'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('Créer'),
              onPressed: () async {
                if (_controller.text.isNotEmpty) {
                  String albumId = await _createAlbum(_controller.text);
                  Navigator.of(context).pop();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AlbumDetailPage(
                        albumId: albumId,
                        albumName: _controller.text,
                      ),
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<String> _createAlbum(String albumName) async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      throw Exception("Aucun utilisateur connecté");
    }

    DocumentReference docRef = await FirebaseFirestore.instance.collection('albums').add({
      'name': albumName,
      'userId': currentUser.uid,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return docRef.id;
  }
}

