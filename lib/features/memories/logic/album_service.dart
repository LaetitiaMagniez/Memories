import 'package:flutter/material.dart';
import 'package:memories_project/features/memories/models/album.dart';
import 'package:memories_project/features/memories/screens/album_details.dart';
import 'package:memories_project/features/memories/screens/album_list.dart';
import 'package:memories_project/core/widgets/loading_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../user/logic/contact_service.dart';

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
        final theme = Theme.of(context);
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            decoration: BoxDecoration(
              color: theme.dialogBackgroundColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: const [
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
                        color: theme.dividerColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.photo_album, color: Colors.deepPurple),
                    title: Text('Créer un album', style: TextStyle(color: theme.textTheme.bodyLarge?.color)),
                    onTap: () {
                      Navigator.pop(context);
                      showCreateAlbumDialog(context);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.settings, color: Colors.grey),
                    title: Text('Gérer les albums', style: TextStyle(color: theme.textTheme.bodyLarge?.color)),
                    onTap: () {
                      Navigator.pop(context);
                      onManageAlbums();
                    },
                  ),
                  ListTile(
                      leading: const Icon(Icons.person_add, color: Colors.deepPurple),
                      title: Text('Inviter des amis', style: TextStyle(color: theme.textTheme.bodyLarge?.color)),
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
        final theme = Theme.of(dialogContext);
        return AlertDialog(
          backgroundColor: theme.dialogBackgroundColor,
          title: Text(
            'Renommer l\'album',
            style: TextStyle(color: theme.textTheme.titleLarge?.color),
          ),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: "Nouveau nom de l'album",
              hintStyle: TextStyle(color: theme.hintColor),
            ),
            style: TextStyle(color: theme.textTheme.bodyLarge?.color),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Annuler', style: TextStyle(color: theme.colorScheme.primary)),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              child: Text('Renommer', style: TextStyle(color: theme.colorScheme.primary)),
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
        final theme = Theme.of(context);
        return AlertDialog(
          backgroundColor: theme.dialogBackgroundColor,
          title: Text("Confirmer la suppression", style: TextStyle(color: theme.textTheme.titleLarge?.color)),
          content: Text(
            "Êtes-vous sûr de vouloir supprimer ${selectedAlbums.length > 1 ? 'ces albums' : 'cet album'} ?",
            style: TextStyle(color: theme.textTheme.bodyLarge?.color),
          ),
          actions: [
            TextButton(
              child: Text("Annuler", style: TextStyle(color: theme.colorScheme.primary)),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text("Supprimer"),
              onPressed: () async {
                for (var album in selectedAlbums) {
                  await deleteAlbum(album.id);
                }
                Navigator.pop(context);
                isManaging = false;
                selectedAlbums.clear();
                refreshUI();
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
        final theme = Theme.of(context);
        return AlertDialog(
          backgroundColor: theme.dialogBackgroundColor,
          title: Text('Confirmer la suppression', style: TextStyle(color: theme.textTheme.titleLarge?.color)),
          content: Text('Voulez-vous vraiment supprimer cet album ?', style: TextStyle(color: theme.textTheme.bodyLarge?.color)),
          actions: <Widget>[
            TextButton(
              child: Text('Annuler', style: TextStyle(color: theme.colorScheme.primary)),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('Supprimer', style: TextStyle(color: theme.colorScheme.primary)),
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
        final theme = Theme.of(dialogContext);
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: theme.dialogBackgroundColor,
              title: const Text('Créer un nouvel album'),
              titleTextStyle: TextStyle(color: theme.textTheme.titleLarge?.color, fontSize: 20, fontWeight: FontWeight.w600),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        hintText: "Nom de l'album",
                        hintStyle: TextStyle(color: theme.hintColor),
                      ),
                      style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 18),
                        const SizedBox(width: 8),
                        TextButton(
                          child: Text(
                            selectedDate == null
                                ? 'Choisir une date'
                                : '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}',
                            style: TextStyle(color: theme.colorScheme.primary),
                          ),
                          onPressed: () async {
                            DateTime? picked = await selectDate(context);
                            if (picked != null) {
                              setState(() {
                                selectedDate = picked;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (!noCity)
                      TextField(
                        controller: cityController,
                        decoration: InputDecoration(
                          hintText: "Ville (optionnelle)",
                          hintStyle: TextStyle(color: theme.hintColor),
                        ),
                        style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                      ),
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
                        const Text('Pas de ville'),
                      ],
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text('Annuler', style: TextStyle(color: theme.colorScheme.primary)),
                  onPressed: () => Navigator.of(dialogContext).pop(),
                ),
                ElevatedButton(
                  child: const Text('Créer'),
                  onPressed: () async {
                    if (nameController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Le nom de l\'album ne peut pas être vide.',
                            style: TextStyle(color: theme.colorScheme.onPrimary),
                          ),
                          backgroundColor: theme.colorScheme.primary,
                        ),
                      );
                      return;
                    }
                    if (selectedDate == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Veuillez sélectionner une date.',
                            style: TextStyle(color: theme.colorScheme.onPrimary),
                          ),
                          backgroundColor: theme.colorScheme.primary,
                        ),
                      );
                      return;
                    }

                    DateTime now = DateTime.now();
                    DateTime dateToUse = selectedDate!;
                    if (dateToUse.isAfter(now)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'La date ne peut pas être dans le futur.',
                            style: TextStyle(color: theme.colorScheme.onPrimary),
                          ),
                          backgroundColor: theme.colorScheme.primary,
                        ),
                      );
                      return;
                    }

                    // Enregistrer l'album dans Firestore
                    final albumData = {
                      'name': nameController.text,
                      'date': dateToUse.toIso8601String(),
                      'city': noCity ? null : cityController.text,
                      'createdBy': FirebaseAuth.instance.currentUser?.uid ?? '',
                    };

                    try {
                      await FirebaseFirestore.instance.collection('albums').add(albumData);
                      Navigator.of(dialogContext).pop();
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Erreur lors de la création de l\'album.',
                            style: TextStyle(color: theme.colorScheme.onPrimary),
                          ),
                          backgroundColor: theme.colorScheme.error,
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
}