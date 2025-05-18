import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:memories_project/class/souvenir.dart';
import 'package:intl/intl.dart';

class SouvenirService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Ancienne gestion supprimée :
  // bool isManaging = false;
  // List<Souvenir> selectedSouvenirs = [];

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

    if (fileBytes != null && fileName != null) {
      try {
        await uploadMedia(albumId, fileBytes, fileName, type);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Média ajouté avec succès !')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de l\'ajout du média : $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ajout annulé : aucun fichier sélectionné')),
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

  Future<void> deleteSouvenir(String albumId, String mediaId) async {
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

  /// ✅ Nouvelle version : suppression des souvenirs sélectionnés
  void confirmDeleteSelectedSouvenirs(
      BuildContext context,
      String albumId,
      VoidCallback refreshUI,
      List<Souvenir> selectedSouvenirs,
      ) {
    if (selectedSouvenirs.isEmpty) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Confirmer la suppression"),
          content: Text(
            "Êtes-vous sûr de vouloir supprimer ${selectedSouvenirs.length > 1 ? 'ces souvenirs' : 'ce souvenir'} ?",
          ),
          actions: [
            TextButton(
              child: const Text("Annuler"),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text("Supprimer"),
              onPressed: () async {
                for (var souvenir in selectedSouvenirs) {
                  await deleteSouvenir(albumId, souvenir.id);
                }

                Navigator.pop(context);
                refreshUI(); // Mise à jour de l'interface
              },
            ),
          ],
        );
      },
    );
  }

  Stream<List<Souvenir>> getAllSouvenirsForUser() {
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
        List<Souvenir> allSouvenirs = [];
        for (var albumDoc in albumsSnapshot.docs) {
          var mediaSnapshot = await albumDoc.reference.collection('media').get();
          allSouvenirs.addAll(mediaSnapshot.docs.map((doc) {
            try {
              return Souvenir(
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
          }).whereType<Souvenir>());
        }
        return allSouvenirs;
      } catch (e) {
        print("Erreur dans getAllSouvenirsForUser: $e");
        return <Souvenir>[];
      }
    });
  }

  Map<String, List<Souvenir>> groupSouvenirsByCity(List<Souvenir> souvenirs) {
    Map<String, List<Souvenir>> souvenirsByCity = {};

    for (var souvenir in souvenirs) {
      if (souvenir.ville != null && souvenir.ville!.isNotEmpty) {
        souvenirsByCity.putIfAbsent(souvenir.ville!, () => []);
        souvenirsByCity[souvenir.ville!]!.add(souvenir);
      }
    }

    return souvenirsByCity;
  }

  Map<String, List<Souvenir>> souvenirs = {};

  List<Souvenir> _getEventsForDay(DateTime day) {
    String formattedDate = DateFormat('d MMMM yyyy', 'fr_FR').format(day);
    return souvenirs.entries
        .where((entry) => entry.key == formattedDate)
        .expand((entry) => entry.value)
        .toList();
  }

  void showSouvenirOptions(
      BuildContext context, String albumId, VoidCallback onManageSouvenir) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom),
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
                    leading: const Icon(Icons.photo, color: Colors.deepPurple),
                    title: const Text('Ajouter une photo'),
                    onTap: () {
                      Navigator.pop(context);
                      pickAndUploadMedia(context, albumId, 'image');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.video_library, color: Colors.deepPurple),
                    title: const Text('Ajouter une vidéo'),
                    onTap: () {
                      Navigator.pop(context);
                      pickAndUploadMedia(context, albumId, 'video');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.settings, color: Colors.grey),
                    title: const Text('Gérer les souvenirs'),
                    onTap: () {
                      Navigator.pop(context);
                      onManageSouvenir();
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
