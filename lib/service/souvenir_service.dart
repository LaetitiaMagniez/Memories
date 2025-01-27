import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';

class SouvenirService {
  final ImagePicker _picker = ImagePicker();

  Future<void> pickAndUploadMedia(BuildContext context, String albumId, String type) async {
    final XFile? pickedFile = type == 'image'
        ? await _picker.pickImage(source: ImageSource.gallery)
        : await _picker.pickVideo(source: ImageSource.gallery);

    if (pickedFile != null) {
      File file = File(pickedFile.path);
      try {
        await uploadMedia(albumId, file, type);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Souvenir ajouté avec succès !')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de l\'ajout du média : $e')),
        );
      }
    }
  }

  Future<void> uploadMedia(String albumId, File file, String type) async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      throw Exception("Aucun utilisateur connecté");
    }

    String fileName = DateTime.now().millisecondsSinceEpoch.toString();
    
    Reference storageRef = FirebaseStorage.instance.ref().child('media/${currentUser.uid}/$albumId/$fileName');
    UploadTask uploadTask = storageRef.putFile(file);
    TaskSnapshot snapshot = await uploadTask;
    String downloadUrl = await snapshot.ref.getDownloadURL();

    await FirebaseFirestore.instance
        .collection('albums')
        .doc(albumId)
        .collection('media')
        .add({
      'type': type,
      'url': downloadUrl,
      'timestamp': FieldValue.serverTimestamp(),
    });

    await FirebaseFirestore.instance.collection('albums').doc(albumId).update({
      'thumbnailUrl': downloadUrl,
    });
  }

  Future<void> deleteMedia(String albumId, String mediaId) async {
    await FirebaseFirestore.instance
        .collection('albums')
        .doc(albumId)
        .collection('media')
        .doc(mediaId)
        .delete();
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
                await deleteMedia(albumId, mediaId);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Média supprimé avec succès !')),
                );
              },
            ),
          ],
        );
      },
    );
  }
}
