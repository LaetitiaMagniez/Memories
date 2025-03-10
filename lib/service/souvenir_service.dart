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
Future<void> pickAndUploadMedia(BuildContext context, String albumId, String type) async {
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
          SnackBar(content: Text('Média ajouté avec succès !')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de l\'ajout du média : $e')),
        );
      }
     } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ajout annulé : aucune ville spécifiée')),
      );
    }
}


Future<void> uploadMedia(String albumId, Uint8List fileData, String fileName, String type) async {
  User? currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser == null) {
    throw Exception("Aucun utilisateur connecté");
  }

  String uniqueFileName = '${DateTime.now().millisecondsSinceEpoch}_$fileName';
  
  Reference storageRef = FirebaseStorage.instance.ref().child('media/${currentUser.uid}/$albumId/$uniqueFileName');
   final metadata = SettableMetadata(
    contentType: type == 'image' ? 'image/jpeg' : 'video/mp4', // Ajustez selon vos besoins
  );
  UploadTask uploadTask= storageRef.putData(fileData, metadata);
    
  TaskSnapshot snapshot = await uploadTask;
  String downloadUrl = await snapshot.ref.getDownloadURL();

DocumentSnapshot albumSnapshot = await _firestore.collection('albums').doc(albumId).get();
    if (!albumSnapshot.exists) throw Exception("Album non trouvé");
 Map<String, dynamic> albumData = albumSnapshot.data() as Map<String, dynamic>;
  await FirebaseFirestore.instance
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

  await FirebaseFirestore.instance.collection('albums').doc(albumId).update({
    'thumbnailUrl': downloadUrl,
  });
  
}


  Future<void> deleteMedia(String albumId, String mediaId) async {
  // Récupérer les informations du média à partir de Firestore
  DocumentSnapshot mediaDoc = await FirebaseFirestore.instance
      .collection('albums')
      .doc(albumId)
      .collection('media')
      .doc(mediaId)
      .get();

  if (mediaDoc.exists) {
    Map<String, dynamic> mediaData = mediaDoc.data() as Map<String, dynamic>;
    String mediaUrl = mediaData['url'];

    // Supprimer le fichier de Firebase Storage
    try {
      Reference storageRef = FirebaseStorage.instance.refFromURL(mediaUrl);
      await storageRef.delete();
    } catch (e) {
      print("Erreur lors de la suppression du fichier dans Storage : $e");
    }

    // Supprimer le document de Firestore
    await FirebaseFirestore.instance
        .collection('albums')
        .doc(albumId)
        .collection('media')
        .doc(mediaId)
        .delete();
  }
}

void showDeleteConfirmationDialog(BuildContext context, String albumId, String mediaId) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Confirmer la suppression'),
        content: Text('Voulez-vous vraiment supprimer ce média ?'),
        actions: <Widget>[
          TextButton(
            child: Text('Annuler'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: Text('Supprimer'),
            onPressed: () async {
              try {
                await deleteMedia(albumId, mediaId);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Média supprimé avec succès !')),
                );
              } catch (e) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Erreur lors de la suppression du média : $e')),
                );
              }
            },
          ),
        ],
      );
    },
  );
  }
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
      if (!souvenirsByCity.containsKey(souvenir.ville)) {
        souvenirsByCity[souvenir.ville!] = [];
      }
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
