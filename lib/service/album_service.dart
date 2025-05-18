import 'package:flutter/material.dart';
import 'package:memories_project/classes/album.dart';
import 'package:memories_project/screens/album/album_details.dart';
import 'package:memories_project/screens/album/album_list.dart';
import 'package:memories_project/transition/loadingScreen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'contact_service.dart';

class AlbumService {

  bool isManaging = false;
  List<Album> selectedAlbums = [];
  final ContactService contactService = ContactService();


  void toggleAlbumSelection(Album album, VoidCallback refreshUI) {
    if (selectedAlbums.contains(album)) {
      selectedAlbums.remove(album);
    } else {
      selectedAlbums.add(album);
    }
    refreshUI(); // C'est le parent qui gère l'appel à setState()
  }

  void clearSelection(VoidCallback refreshUI) {
    selectedAlbums.clear();
    refreshUI();
  }

  void showAlbumOptions(BuildContext context, VoidCallback onManageAlbums) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(0, -5),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Wrap(
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.photo_album, color: Colors.deepPurple),
                    title: const Text('Créer un album'),
                    onTap: () {
                      Navigator.pop(context);
                      showCreateAlbumDialog(context);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.settings, color: Colors.grey),
                    title: const Text('Gérer les albums'),
                    onTap: () {
                      Navigator.pop(context);
                      onManageAlbums();
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.person_add, color: Colors.deepPurple),
                    title: const Text('Inviter des amis'),
                    onTap: () {
                      Navigator.pop(context);
                      contactService.sendInvite();
                    }
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void renameAlbum(BuildContext context, Album album) {
    final TextEditingController controller = TextEditingController(text: album.name);

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Renommer l\'album'),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(hintText: "Nouveau nom de l'album"),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Annuler'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              child: Text('Renommer'),
              onPressed: () async {
                if (controller.text.isNotEmpty) {
                  await FirebaseFirestore.instance.collection('albums').doc(album.id).update({
                    'name': controller.text,
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

  void confirmDeleteSelectedAlbums(BuildContext context, VoidCallback refreshUI) async {
    if (selectedAlbums.isEmpty) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Confirmer la suppression"),
          content: Text("Êtes-vous sûr de vouloir supprimer ${selectedAlbums.length > 1 ? 'ces albums' : 'cet album'} ?"),
          actions: [
            TextButton(
              child: const Text("Annuler"),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              child: const Text("Supprimer"),
              onPressed: () async {
                for (var album in selectedAlbums) {
                  await deleteAlbum(album.id);
                }

                Navigator.pop(context);
                isManaging = false;
                selectedAlbums.clear();
                refreshUI(); // Mise à jour de l'interface
              },
            ),
          ],
        );
      },
    );
  }

  void confirmDeleteAlbum(BuildContext context, Album album) {
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
                Navigator.of(context).pop();

                showDialog(
                  context: scaffoldContext,
                  barrierDismissible: false,
                  builder: (BuildContext context) {
                    return LoadingScreen(message: 'Suppression de l\'album en cours...');
                  },
                );

                try {
                  await deleteAlbum(album.id);
                } catch (e) {
                  print('Erreur pendant la suppression : $e');
                } finally {
                  Navigator.of(scaffoldContext).pop();

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
    QuerySnapshot mediaSnapshot = await FirebaseFirestore.instance
        .collection('albums')
        .doc(albumId)
        .collection('media')
        .get();

    for (var doc in mediaSnapshot.docs) {
      String mediaUrl = doc['url'];
      Reference storageRef = FirebaseStorage.instance.refFromURL(mediaUrl);
      await storageRef.delete();
    }

    WriteBatch batch = FirebaseFirestore.instance.batch();
    for (var doc in mediaSnapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();

    await FirebaseFirestore.instance.collection('albums').doc(albumId).delete();
  }

  void showCreateAlbumDialog(BuildContext context) {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController cityController = TextEditingController();
    DateTime? selectedDate;
    bool noCity = false;

    Future<DateTime?> selectDate(BuildContext context) async {
      final DateTime now = DateTime.now();

      return await showDatePicker(
        context: context,
        initialDate: selectedDate ?? now,
        firstDate: DateTime(2000),
        lastDate: now,
        helpText: 'Sélectionner une date',
        cancelText: 'Annuler',
        confirmText: 'OK',
      );
    }

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Créer un nouvel album'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(hintText: "Nom de l'album"),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Checkbox(
                          value: noCity,
                          onChanged: (bool? value) {
                            setState(() {
                              noCity = value ?? false;
                            });
                          },
                        ),
                        const Text('Ne pas spécifier de ville'),
                      ],
                    ),
                    if (!noCity)
                      TextField(
                        controller: cityController,
                        decoration: const InputDecoration(
                          hintText: "Ville",
                          prefixIcon: Icon(Icons.map),
                        ),
                      ),
                    const SizedBox(height: 10),
                    ListTile(
                      title: Text(
                        'Date : ${selectedDate != null ? selectedDate!.toLocal().toString().split(' ')[0] : 'Non définie'}',
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final DateTime? picked = await selectDate(context);
                        if (picked != null) {
                          setState(() => selectedDate = picked);
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Annuler'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                TextButton(
                  child: const Text('Créer'),
                  onPressed: () async {
                    if (nameController.text.isNotEmpty && selectedDate != null ) {
                      String city = noCity ? '' : cityController.text;
                      String albumId = await createAlbum(nameController.text, city, selectedDate);
                      Navigator.of(dialogContext).pop();
                      Navigator.push(
                        dialogContext,
                        MaterialPageRoute(
                          builder: (context) => AlbumDetailPage(albumId: albumId, albumName: nameController.text),
                        ),
                      );
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<String> createAlbum(String albumName, String city, DateTime? date) async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) throw Exception("Aucun utilisateur connecté");

    DocumentReference docRef = await FirebaseFirestore.instance.collection('albums').add({
      'name': albumName,
      'ville': city,
      'date': date != null ? Timestamp.fromDate(date) : null,
      'userId': currentUser.uid,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return docRef.id;
  }
}
