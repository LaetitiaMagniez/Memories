import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';
import '../models/app_user.dart';

class ContactService {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;

  AppUser? _currentUser;
  List<AppUser> friends = [];
  int invitationsSent = 0;
  int totalInvitationsSent = 0;
  bool _isLoading = true;

  ContactService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : firestore = firestore ?? FirebaseFirestore.instance,
        auth = auth ?? FirebaseAuth.instance;

  Future<AppUser?> loadCurrentUser() async {
    try {
      final user = auth.currentUser;
      if (user == null) return null;

      final doc = await firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        _currentUser = AppUser.fromDocument(doc);
        return _currentUser;
      }
      return null;
    } catch (e) {
      debugPrint('Erreur loadCurrentUser: $e');
      return null;
    }
  }

  AppUser? get currentUser => _currentUser;

  Future<Map<String, dynamic>> loadFriendsData() async {
    await loadCurrentUser();
    await loadFriends();
    totalInvitationsSent = await getInvitationsSent();
    _isLoading = false;
    return {
      'friends': friends,
      'totalInvitationsSent': totalInvitationsSent,
      'isLoading': _isLoading,
    };
  }

  Future<void> sendInvite() async {
    final link = await _generateUniqueInviteLink();
    final message = "Rejoins-moi sur Memories ! Clique sur le lien suivant pour t'inscrire : $link";

    await SharePlus.instance.share(ShareParams(text: message));
    invitationsSent++;
  }

  Future<int> getInvitationsSent() async {
    final snapshot = await firestore
        .collection('invite_codes')
        .where('userId', isEqualTo: _currentUser?.uid)
        .get();
    return snapshot.docs.length;
  }

  Future<void> loadFriends() async {
    final currentUser = await loadCurrentUser();
    if (currentUser != null) {
      final snapshot = await firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('friends')
          .get();
      friends = snapshot.docs.map((doc) => AppUser.fromDocument(doc)).toList();
    }
  }

  Future<void> removeFriend(AppUser friend) async {
    final currentUser = await loadCurrentUser();
    if (currentUser != null) {
      await firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('friends')
          .doc(friend.uid)
          .delete();
      friends.removeWhere((f) => f.uid == friend.uid);
    }
  }

  Future<void> addFriend(String friendId, String inviterUserId) async {
    final batch = firestore.batch();

    batch.set(
      firestore.collection('users').doc(friendId).collection('friends').doc(inviterUserId),
      {
        'createdAt': FieldValue.serverTimestamp(),
        'role': 'Editeur',
      },
    );

    batch.set(
      firestore.collection('users').doc(inviterUserId).collection('friends').doc(friendId),
      {
        'createdAt': FieldValue.serverTimestamp(),
        'role': 'Editeur',
      },
    );

    await batch.commit();

    await shareAlbumsWithUser(inviterUserId, friendId);
  }

  Future<void> shareAlbumWithUser(String albumId, String inviterUserId, String friendId) async {
    final albumDoc = await firestore.collection('albums').doc(albumId).get();

    if (!albumDoc.exists) {
      debugPrint('Album $albumId non trouvé');
      return;
    }

    final albumData = albumDoc.data()!;

    // Vérifie que l'album appartient bien à inviterUserId (optionnel, sécurité)
    if (albumData['userId'] != inviterUserId) {
      debugPrint('L\'album ne appartient pas à l\'utilisateur invitant.');
      return;
    }

    final updatedSharedWith = List<String>.from(albumData['sharedWith'] ?? []);
    if (!updatedSharedWith.contains(friendId)) {
      updatedSharedWith.add(friendId);
    }

    final sharedAlbumRef = firestore.collection('albumsShared').doc(albumId);
    await sharedAlbumRef.set({...albumData, 'sharedWith': updatedSharedWith}, SetOptions(merge: true));

    final memoriesSnapshot = await firestore
        .collection('albums')
        .doc(albumId)
        .collection('media')
        .get();

    for (final memory in memoriesSnapshot.docs) {
      await sharedAlbumRef.collection('sharedMedia').doc(memory.id).set(memory.data());
    }
  }


  Future<void> shareAlbumsWithUser(String inviterUserId, String friendId) async {
    final albumsSnapshot = await firestore
        .collection('albums')
        .where('userId', isEqualTo: inviterUserId)
        .get();

    for (final album in albumsSnapshot.docs) {
      final albumData = album.data();

      final updatedSharedWith = List<String>.from(albumData['sharedWith'] ?? []);
      if (!updatedSharedWith.contains(friendId)) {
        updatedSharedWith.add(friendId);
      }

      final sharedAlbumRef = firestore.collection('albumsShared').doc(album.id);
      await sharedAlbumRef.set({...albumData, 'sharedWith': updatedSharedWith}, SetOptions(merge: true));

      final memoriesSnapshot = await firestore
          .collection('albums')
          .doc(album.id)
          .collection('media')
          .get();

      for (final memory in memoriesSnapshot.docs) {
        await sharedAlbumRef.collection('sharedMedia').doc(memory.id).set(memory.data());
      }
    }
  }

  String _generateRandomCode(int length) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rand = Random();
    return List.generate(length, (_) => chars[rand.nextInt(chars.length)]).join();
  }

  Future<String> _generateUniqueInviteLink() async {
    final user = auth.currentUser;
    if (user == null) throw Exception('Utilisateur non connecté');

    final code = _generateRandomCode(6);
    final url = "https://memories-7bdc6.firebaseapp.com/?code=$code";

    await firestore.collection('invite_codes').doc(code).set({
      'userId': user.uid,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return url;
  }

  Future<bool> acceptInvitationCode(String inviteCode) async {
    try {
      final currentUser = auth.currentUser;
      if (currentUser == null) return false;

      final codeDoc = await firestore.collection('invite_codes').doc(inviteCode).get();

      if (!codeDoc.exists) {
        debugPrint('Code d\'invitation invalide ou expiré.');
        return false;
      }

      final inviterUserId = codeDoc['userId'] as String?;

      if (inviterUserId == null || inviterUserId == currentUser.uid) {
        debugPrint('Code d\'invitation invalide.');
        return false;
      }

      await addFriend(currentUser.uid, inviterUserId);

      await firestore.collection('invite_codes').doc(inviteCode).delete();

      debugPrint('Invitation acceptée avec succès.');

      return true;
    } catch (e) {
      debugPrint('Erreur acceptInvitationCode: $e');
      return false;
    }
  }
}
