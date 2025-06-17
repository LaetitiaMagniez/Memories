import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memories_project/core/services/media_service.dart';
import 'dart:io';
import '../../../core/widgets/auth_gate.dart';
import '../models/app_user.dart';

class UserService {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final MediaService mediaService = MediaService(
    auth: FirebaseAuth.instance,
    firestore: FirebaseFirestore.instance,
    storage: FirebaseStorage.instance
  );

  AppUser? _currentUser;

  User? get firebaseUser => auth.currentUser;

  Future<AppUser?> loadCurrentUser() async {
    if (_currentUser != null) return _currentUser;
    final currentUser = auth.currentUser;
    if (currentUser != null) {
      final userDoc = await firestore.collection('users').doc(currentUser.uid).get();
      if (userDoc.exists) {
        _currentUser = AppUser.fromDocument(userDoc);
        return _currentUser;
      }
    }
    return null;
  }

  Future<Map<String, dynamic>> loadUserData() async {
    try {
      final user = auth.currentUser;
      if (user != null) {
        final userData = await firestore.collection('users').doc(user.uid).get();
        if (userData.exists) {
          return userData.data()!;
        }
      }
      return {};
    } catch (e) {
      print("Erreur lors du chargement des données de l'utilisateur : $e");
      rethrow;
    }
  }

  Future<Map<String, int>> loadCounts() async {
    int albumCount = 0;
    int memoriesCount = 0;
    int sharedAlbumCount = 0;
    int sharedMemoriesCount = 0;

    try {
      final user = auth.currentUser;
      if (user != null) {
        final albumsSnapshot = await firestore
            .collection('albums')
            .where('userId', isEqualTo: user.uid)
            .get();
        albumCount = albumsSnapshot.docs.length;

        for (var album in albumsSnapshot.docs) {
          final countSnapshot = await album.reference.collection('media').count().get();
          memoriesCount += countSnapshot.count ?? 0;
        }

        final sharedAlbumsSnapshot = await firestore
            .collection('albums')
            .where('sharedWith', arrayContains: user.uid)
            .get();
        sharedAlbumCount = sharedAlbumsSnapshot.docs.length;

        for (var sharedAlbum in sharedAlbumsSnapshot.docs) {
          final countSnapshot = await sharedAlbum.reference.collection('media').count().get();
          sharedMemoriesCount += countSnapshot.count ?? 0;
        }
      }
    } catch (e) {
      print("Erreur lors du chargement des comptes : $e");
    }

    return {
      'albumCount': albumCount,
      'memoriesCount': memoriesCount,
      'sharedAlbumCount': sharedAlbumCount,
      'sharedMemoriesCount': sharedMemoriesCount
    };
  }

  Future<void> signOut(BuildContext context) async {
    try {
      await auth.signOut();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const AuthGate()),
            (route) => false,
      );
    } catch (_) {}
  }

  Future<bool> updateProfile(String username, File? imageFile, {String? imageUrl}) async {
    final user = auth.currentUser;
    if (user == null) return false;

    String? finalImageUrl = imageUrl;
    if (imageFile != null) {
      finalImageUrl = await mediaService.uploadUserImage(imageFile, oldImageUrl: imageUrl);
    }

    await firestore.collection('users').doc(user.uid).set({
      'username': username,
      if (finalImageUrl != null) 'profilePicture': finalImageUrl,
    }, SetOptions(merge: true));

    await user.updateDisplayName(username);
    if (finalImageUrl != null) {
      await user.updatePhotoURL(finalImageUrl);
    }
    return true;
  }

}
