import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:image_cropper/image_cropper.dart';
import 'package:memories_project/authentification/auth_gate.dart';
import 'package:memories_project/service/contact_service.dart';
import 'package:memories_project/transition/loadingScreen.dart';

import '../class/appUser.dart';

class ProfileService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ContactService contactService = ContactService();
  List<AppUser> friends = [];

  void signOut(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const AuthGate()),
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      print("Erreur lors de la déconnexion : $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors de la déconnexion')),
      );
    }
  }

  Future<Map<String, dynamic>> loadUserData() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final userData =
            await _firestore.collection('users').doc(user.uid).get();
        if (userData.exists) {
          return userData.data() as Map<String, dynamic>;
        }
      }
      return {};
    } catch (e) {
      print("Erreur lors du chargement des données : $e");
      return {};
    }
  }

  Future<Map<String, int>> loadCounts() async {
    int albumCount = 0;
    int memoriesCount = 0;
    int sharedAlbumCount = 0;
    int sharedMemoriesCount = 0;
    friends = contactService.loadFriends() as List<AppUser> ;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final albums = await FirebaseFirestore.instance
            .collection('albums')
            .where('userId', isEqualTo: user.uid)
            .get();
        albumCount = albums.docs.length;

        int totalMemories = 0;
        for (var album in albums.docs) {
          int itemCount = await album.reference.collection('media').count().get().then((value) => value.count!);
          totalMemories += itemCount;
        }
        memoriesCount = totalMemories;

        for (var friend in friends) {
          final sharedAlbums = await FirebaseFirestore.instance
              .collection('albums')
              .where('userId', isEqualTo: friend.uid)
              .get();
          sharedAlbumCount = sharedAlbums.docs.length;
          int totalsharedMemories = 0;
          for (var sharedAlbum in sharedAlbums.docs) {
            int itemCount = await sharedAlbum.reference.collection('media').count().get().then((value) => value.count!);
            totalsharedMemories += itemCount;
          }
          sharedMemoriesCount = totalsharedMemories;
        }
      }

    } catch (e) {
      print("Erreur lors du chargement des comptes : $e");
    }
    return {'albumCount': albumCount, 'memoriesCount': memoriesCount, 'sharedAlbumCount': sharedAlbumCount, 'sharedMemoriesCount': sharedMemoriesCount};
  }

  Future<Map<String, dynamic>> pickAndUploadProfileImage(String? currentImageUrl) async {
    File? selectedImage;
    String? imageUrl;
    try {
      // Vérifier si nous sommes sur le web
      if (kIsWeb) {
        // Utiliser la méthode de sélection d'image pour le web
        final pickedFile = await ImagePicker.platform.pickImage(source: ImageSource.gallery);
        if (pickedFile != null) {
          selectedImage = File(pickedFile.path);
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            if (currentImageUrl != null) {
              final oldImageRef = FirebaseStorage.instance.refFromURL(currentImageUrl);
              await oldImageRef.delete();
            }

            final fileName = '${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
            final storageRef = FirebaseStorage.instance.ref().child('user_images/$fileName');
            final uploadTask = storageRef.putData(await selectedImage!.readAsBytes());
            final taskSnapshot = await uploadTask;
            imageUrl = await taskSnapshot.ref.getDownloadURL();

            await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
              'profilePicture': imageUrl,
            });
          }
        }
      } else {
        // Utiliser la méthode de sélection d'image pour les autres plateformes
        final picker = ImagePicker();
        final pickedFile = await picker.pickImage(source: ImageSource.gallery);

        if (pickedFile != null) {
          final croppedFile = await ImageCropper().cropImage(
            sourcePath: pickedFile.path,
            aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
            compressQuality: 100,
            maxWidth: 700,
            maxHeight: 700,
            uiSettings: [
              AndroidUiSettings(
                toolbarTitle: 'Recadrer l\'image',
                toolbarColor: Colors.blue,
                toolbarWidgetColor: Colors.white,
                lockAspectRatio: true,
                cropStyle: CropStyle.circle,
              )
            ],
          );

          if (croppedFile != null) {
            final user = FirebaseAuth.instance.currentUser;
            if (user != null) {
              if (currentImageUrl != null) {
                final oldImageRef = FirebaseStorage.instance.refFromURL(currentImageUrl);
                await oldImageRef.delete();
              }

              final File imageFile = File(croppedFile.path);
              final String fileName = '${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
              final Reference storageRef = FirebaseStorage.instance.ref().child('user_images/$fileName');

              final UploadTask uploadTask = storageRef.putFile(imageFile);
              final TaskSnapshot taskSnapshot = await uploadTask;
              final String downloadUrl = await taskSnapshot.ref.getDownloadURL();
              selectedImage = imageFile;
              imageUrl = downloadUrl;

              await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
                'profilePicture': downloadUrl,
              });
            }
          }
        }
      }
    } catch (e) {
      print('Erreur lors du téléchargement de l\'image : $e');
    }
    return {'selectedImage': selectedImage, 'imageUrl': imageUrl};
  }


  Future<bool> updateProfile(String username, String? imageUrl) async {
    try {
      final user = _auth.currentUser;

      if (user != null) {
        await _firestore.collection('users').doc(user.uid).set({
          'username': username,
          'profilePicture': imageUrl,
        }, SetOptions(merge: true));

        await user.updateDisplayName(username);
        if (imageUrl != null) {
          await user.updatePhotoURL(imageUrl);
        }
        return true;
      }
      return false;
    } catch (e) {
      print('Error updating profile: $e');
      return false;
    }
  }

  void showDeleteConfirmation(BuildContext context,
      Future<void> Function() deleteAccountCallback) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text("Confirmer la suppression"),
          content: const Text(
            "Êtes-vous sûr de vouloir supprimer votre compte ? Cette action est irréversible.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("Annuler"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                deleteAccountCallback();
              },
              child: const Text(
                "Supprimer",
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> deleteAccount(
      BuildContext context, String? currentImageUrl) async {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) =>
          LoadingScreen(message: 'Suppression du compte en cours'),
    ));

    try {
      final user = FirebaseAuth.instance.currentUser!;
      final uid = user.uid;

      if (currentImageUrl != null) {
        final ref = FirebaseStorage.instance.refFromURL(currentImageUrl);
        await ref.delete();
      }

      await FirebaseFirestore.instance.collection('users').doc(uid).delete();

      await user.delete();

      await FirebaseAuth.instance.signOut();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const AuthGate()),
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      print("Erreur lors de la suppression du compte : $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors de la suppression du compte')),
      );
    }
  }
}
