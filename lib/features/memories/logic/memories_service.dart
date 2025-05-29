import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:memories_project/features/memories/models/memory.dart';
import 'package:intl/intl.dart';

class MemoriesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> pickAndUploadMedia(
      BuildContext context, String albumId, String type) async {
    Uint8List? fileBytes;
    String? fileName;

    if (type == 'image' && !kIsWeb) {
      final ImagePicker picker = ImagePicker();
      XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        fileBytes = await pickedFile.readAsBytes();
        fileName = pickedFile.name;
      }
    } else {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: type == 'image' ? FileType.image : FileType.video,
        allowMultiple: false,
        withData: true,
        allowCompression: false,
      );

      if (result != null) {
        fileBytes = result.files.first.bytes;
        fileName = result.files.first.name;
      }
    }

    final theme = Theme.of(context);

    if (fileBytes != null && fileName != null) {
      try {
        await uploadMedia(albumId, fileBytes, fileName, type);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Média ajouté avec succès !'),
            backgroundColor: theme.snackBarTheme.backgroundColor ?? theme.colorScheme.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'ajout du média : $e'),
            backgroundColor: theme.colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Ajout annulé : aucun fichier sélectionné'),
          backgroundColor: theme.snackBarTheme.backgroundColor ?? theme.colorScheme.surface,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> uploadMedia(
      String albumId, Uint8List fileData, String fileName, String type) async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      throw Exception("Aucun utilisateur connecté");
    }

    String uniqueFileName = '${DateTime.now().millisecondsSinceEpoch}_$fileName';

    Reference storageRef = FirebaseStorage.instance
        .ref()
        .child('media/${currentUser.uid}/$albumId/$uniqueFileName');

    final metadata = SettableMetadata(
      contentType: type == 'image' ? 'image/jpeg' : 'video/mp4',
    );

    UploadTask uploadTask = storageRef.putData(fileData, metadata);

    TaskSnapshot snapshot = await uploadTask;
    String downloadUrl = await snapshot.ref.getDownloadURL();

    DocumentSnapshot albumSnapshot =
    await _firestore.collection('albums').doc(albumId).get();

    if (!albumSnapshot.exists) throw Exception("Album non trouvé");

    Map<String, dynamic> albumData =
    albumSnapshot.data() as Map<String, dynamic>;

    await _firestore
        .collection('albums')
        .doc(albumId)
        .collection('media')
        .add({
      'type': type,
      'url': downloadUrl,
      'timestamp': FieldValue.serverTimestamp(),
      'ville': albumData['ville'],
      'date': albumData['date']
    });

    await _firestore.collection('albums').doc(albumId).update({
      'thumbnailUrl': downloadUrl,
    });
  }

  Future<void> deleteMemory(String albumId, String mediaId) async {
    DocumentSnapshot mediaDoc = await FirebaseFirestore.instance
        .collection('albums')
        .doc(albumId)
        .collection('media')
        .doc(mediaId)
        .get();

    if (mediaDoc.exists) {
      Map<String, dynamic> mediaData = mediaDoc.data() as Map<String, dynamic>;
      String mediaUrl = mediaData['url'];

      try {
        Reference storageRef = FirebaseStorage.instance.refFromURL(mediaUrl);
        await storageRef.delete();
      } catch (e) {
        print("Erreur lors de la suppression du fichier dans Storage : $e");
      }

      await FirebaseFirestore.instance
          .collection('albums')
          .doc(albumId)
          .collection('media')
          .doc(mediaId)
          .delete();
    }
  }

  void confirmDeleteSelectedMemories(
      BuildContext context,
      String albumId,
      VoidCallback refreshUI,
      List<Memory> selectedMemories,
      ) {
    if (selectedMemories.isEmpty) return;

    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        final themeDialog = Theme.of(context);
        return AlertDialog(
          backgroundColor: themeDialog.dialogBackgroundColor,
          title: Text(
            "Confirmer la suppression",
            style: TextStyle(color: themeDialog.textTheme.titleLarge?.color),
          ),
          content: Text(
            "Êtes-vous sûr de vouloir supprimer ${selectedMemories.length > 1 ? 'ces souvenirs' : 'ce souvenir'} ?",
            style: TextStyle(color: themeDialog.textTheme.bodyLarge?.color),
          ),
          actions: [
            TextButton(
              child: Text("Annuler", style: TextStyle(color: themeDialog.colorScheme.primary)),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text("Supprimer"),
              onPressed: () async {
                for (var memory in selectedMemories) {
                  await deleteMemory(albumId, memory.id);
                }

                Navigator.pop(context);
                refreshUI();
              },
            ),
          ],
        );
      },
    );
  }

  Stream<List<Memory>> getAllMemoriesForUser() {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return Stream.value([]);
    }

    return FirebaseFirestore.instance
        .collection('albums')
        .where('userId', isEqualTo: currentUser.uid)
        .snapshots()
        .asyncMap((albumsSnapshot) async {
      try {
        List<Memory> allMemories = [];
        for (var albumDoc in albumsSnapshot.docs) {
          var mediaSnapshot = await albumDoc.reference.collection('media').get();
          allMemories.addAll(mediaSnapshot.docs.map((doc) {
            try {
              return Memory(
                id: doc.id,
                ville: doc['ville'] as String?,
                url: doc['url'] as String,
                type: doc['type'] as String,
                date: (doc['date'] as Timestamp).toDate(),
              );
            } catch (e) {
              print("Erreur lors de la création d'un Souvenir: $e");
              return null;
            }
          }).whereType<Memory>());
        }
        return allMemories;
      } catch (e) {
        print("Erreur dans getAllMemoriesForUser: $e");
        return <Memory>[];
      }
    });
  }

  Map<String, List<Memory>> groupMemoriesByCity(List<Memory> memories) {
    Map<String, List<Memory>> memoriesByCity = {};

    for (var memory in memories) {
      if (memory.ville != null && memory.ville!.isNotEmpty) {
        memoriesByCity.putIfAbsent(memory.ville!, () => []);
        memoriesByCity[memory.ville!]!.add(memory);
      }
    }

    return memoriesByCity;
  }

  Map<String, List<Memory>> memories = {};

  List<Memory> _getEventsForDay(DateTime day) {
    String formattedDate = DateFormat('d MMMM yyyy', 'fr_FR').format(day);
    return memories.entries
        .where((entry) => entry.key == formattedDate)
        .expand((entry) => entry.value)
        .toList();
  }

  void showMemoriesOptions(
      BuildContext context, String albumId, VoidCallback onManageMemory) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        final themeSheet = Theme.of(context);
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            decoration: BoxDecoration(
              color: themeSheet.dialogBackgroundColor,
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
                        color: themeSheet.dividerColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.photo, color: Colors.deepPurple),
                    title: Text('Ajouter une photo', style: TextStyle(color: themeSheet.textTheme.bodyLarge?.color)),
                    onTap: () {
                      Navigator.pop(context);
                      pickAndUploadMedia(context, albumId, 'image');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.video_library, color: Colors.deepPurple),
                    title: Text('Ajouter une vidéo', style: TextStyle(color: themeSheet.textTheme.bodyLarge?.color)),
                    onTap: () {
                      Navigator.pop(context);
                      pickAndUploadMedia(context, albumId, 'video');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.settings, color: Colors.grey),
                    title: Text('Gérer les souvenirs', style: TextStyle(color: themeSheet.textTheme.bodyLarge?.color)),
                    onTap: () {
                      Navigator.pop(context);
                      onManageMemory();
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}