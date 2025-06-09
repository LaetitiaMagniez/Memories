import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/chosen_file.dart';
import '../models/uploaded_image_result.dart';
import '../widgets/loading/dialog/upload_progress_dialog.dart';

class MediaService {
  final FirebaseAuth auth;
  final FirebaseFirestore firestore;
  final FirebaseStorage storage;

  MediaService({
    required this.auth,
    required this.firestore,
    required this.storage,
  });

  Future<bool> _requestPermission(String type) async {
    PermissionStatus status;
    if (type == 'image') {
      status = await Permission.photos.request();
    } else if (type == 'video') {
      status = await Permission.videos.request();
    } else {
      return false;
    }

    if (!status.isGranted && !kIsWeb) {
      status = await Permission.storage.request();
    }

    return status.isGranted;
  }

  // ---------- Sélection de fichier ----------
  Future<ChosenFile?> chosenFile(String type) async {
    if (kIsWeb) {
      final picker = ImagePicker();
      if (type == 'image') {
        final picked = await picker.pickImage(source: ImageSource.gallery);
        if (picked == null) return null;
        final bytes = await picked.readAsBytes();
        return ChosenFile(bytes: bytes, name: picked.name);
      } else {
        // Pour vidéo sur web, tu peux ajouter si besoin
        return null;
      }
    } else {
      if (type == 'image') {
        final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
        if (picked == null) return null;
        final bytes = await picked.readAsBytes();
        return ChosenFile(bytes: bytes, name: picked.name);
      } else if (type == 'video') {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.video,
          withData: true,
        );
        if (result == null || result.files.single.bytes == null) return null;
        return ChosenFile(bytes: result.files.single.bytes!, name: result.files.single.name);
      }
      return null;
    }
  }

  // ---------- Upload dans Firebase Storage ----------
  Future<String?> uploadFile(Uint8List fileBytes, String storagePath, String contentType) async {
    final ref = storage.ref(storagePath);
    final metadata = SettableMetadata(contentType: contentType);

    final uploadTask = ref.putData(fileBytes, metadata);
    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  // ---------- Méthode principale ----------
  Future<String?> pickAndUploadMedia({
    required BuildContext context,
    required String albumId,
    required String type,
    void Function(double progress)? onUploadProgress,
  }) async {
    try {
      final hasPermission = await _requestPermission(type);
      if (!hasPermission) {
        return null;
      }

      final picked = await chosenFile(type);
      if (picked == null) return null;

      final user = auth.currentUser;
      if (user == null) return null;

      final uniqueFileName = '${DateTime.now().millisecondsSinceEpoch}_${picked.name}';
      final storagePath = 'media/${user.uid}/$albumId/$uniqueFileName';

      final ref = storage.ref(storagePath);
      final metadata = SettableMetadata(
        contentType: type == 'image' ? 'image/jpeg' : 'video/mp4',
      );

      final uploadTask = ref.putData(picked.bytes, metadata);

      if (context.mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => UploadProgressDialog(uploadTask: uploadTask),
        );
      }

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      final albumSnapshot = await firestore.collection('albums').doc(albumId).get();
      if (!albumSnapshot.exists) throw Exception("Album non trouvé");

      final albumData = albumSnapshot.data()!;
      await firestore.collection('albums').doc(albumId).collection('media').add({
        'type': type,
        'url': downloadUrl,
        'timestamp': FieldValue.serverTimestamp(),
        'ville': albumData['ville'],
        'date': albumData['date'],
      });

      await firestore.collection('albums').doc(albumId).update({'thumbnailUrl': downloadUrl});

      return downloadUrl;
    } catch (e) {
      debugPrint('Erreur dans pickAndUploadMedia: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'upload : $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
      return null;
    }
  }


  Future<UploadedImageResult> pickAndUploadProfileImage(String? currentImageUrl) async {
    File? selectedImage;
    String? imageUrl;

    try {
      final user = auth.currentUser;
      if (user == null) return UploadedImageResult();

      if (kIsWeb) {
        final picker = ImagePicker();
        final XFile? pickedFile = await picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 100,
        );
        if (pickedFile != null) {
          final fileName = '${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
          final ref = storage.ref().child('user_images/$fileName');

          final uploadTask = ref.putData(await pickedFile.readAsBytes());
          final downloadUrl = await (await uploadTask).ref.getDownloadURL();
          imageUrl = downloadUrl;

          await firestore.collection('users').doc(user.uid).update({
            'profilePicture': downloadUrl,
          });
        }
      } else {
        final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
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
            final imageFile = File(croppedFile.path);
            imageUrl = await uploadUserImage(imageFile, oldImageUrl: currentImageUrl);
            selectedImage = imageFile;

            if (imageUrl != null) {
              await firestore.collection('users').doc(user.uid).update({
                'profilePicture': imageUrl,
              });
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Erreur lors du téléchargement de l\'image : $e');
    }

    return UploadedImageResult(selectedImage: selectedImage, imageUrl: imageUrl);
  }

  Future<String?> uploadUserImage(File imageFile, {String? oldImageUrl}) async {
    try {
      final user = auth.currentUser;
      if (user == null) return null;

      if (oldImageUrl != null) {
        try {
          final ref = storage.refFromURL(oldImageUrl);
          await ref.delete();
        } catch (_) {
          debugPrint('Ancienne image non supprimée (peut-être déjà supprimée)');
        }
      }

      final fileName = '${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = storage.ref().child('user_images/$fileName');
      await ref.putFile(imageFile);
      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint('Erreur lors du téléversement de l’image : $e');
      return null;
    }
  }

  Future<void> addMediaToAlbum(
      String albumId,
      String type,
      String url,
      String? ville,
      DateTime date,
      ) async {
    final albumRef = firestore.collection('albums').doc(albumId);
    final mediaRef = albumRef.collection('media');

    await mediaRef.add({
      'type': type,
      'url': url,
      'timestamp': FieldValue.serverTimestamp(),
      'ville': ville,
      'date': date,
    });

    await albumRef.update({
      'thumbnailUrl': url,
      'thumbnailType': type,
      'itemCount': FieldValue.increment(1),
    });
  }
}

