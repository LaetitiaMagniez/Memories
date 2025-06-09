import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';
import '../../album/models/album.dart';
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

  /// Récupère l'utilisateur connecté actuel
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

  /// Charge tout : utilisateur, amis, invitations, et retourne un map avec les résultats
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

  /// Envoie une invitation via système de partage
  Future<void> sendInvite() async {
    final link = await _generateUniqueInviteLink();
    final message = "Rejoins-moi sur Memories ! Clique sur le lien suivant pour t'inscrire : $link";

    await SharePlus.instance.share(ShareParams(text: message));
    invitationsSent++;
  }

  /// Retourne le nombre d'invitations déjà envoyées par l'utilisateur courant
  Future<int> getInvitationsSent() async {
    final snapshot = await firestore
        .collection('invite_codes')
        .where('userId', isEqualTo: _currentUser?.uid)
        .get();
    return snapshot.docs.length;
  }

  /// Charge la liste des amis de l'utilisateur courant
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

  /// Supprime un ami
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

  /// Ajoute un ami et partage les albums de l'invitant
  Future<void> addFriend(String friendId, String inviterUserId) async {
    final currentUser = auth.currentUser;
    if (currentUser == null) return;

    final userDoc = firestore.collection('users').doc(currentUser.uid);
    final friendDoc = firestore.collection('users').doc(friendId);

    // Ajout bidirectionnel des amis dans un batch
    final batch = firestore.batch();
    batch.set(userDoc.collection('friends').doc(friendId), {
      'createdAt': FieldValue.serverTimestamp(),
      'role': 'Editeur',
    });
    batch.set(friendDoc.collection('friends').doc(currentUser.uid), {
      'createdAt': FieldValue.serverTimestamp(),
      'role': 'Editeur',
    });
    batch.set(friendDoc.collection('friends').doc(inviterUserId), {
      'createdAt': FieldValue.serverTimestamp(),
      'role': 'Editeur',
    });
    await batch.commit();

    // Partage des albums
    await _shareAlbumsWithUser(inviterUserId, friendId);
  }

  /// Partage un album spécifique avec un utilisateur
  Future<void> shareAlbumWithUser(Album album, String friendUid) async {
    final albumRef = firestore.collection('albumsShared').doc(album.id);
    final albumDoc = await albumRef.get();

    if (!albumDoc.exists) {
      await albumRef.set({
        'id': album.id,
        'userId': album.userId,
        'name': album.name,
        'thumbnailUrl': album.thumbnailUrl,
        'thumbnailType': album.thumbnailType,
        'itemCount': album.itemCount,
        'sharedWith': [friendUid],
      });

      final memoriesSnapshot = await firestore
          .collection('albums')
          .doc(album.id)
          .collection('media')
          .get();

      for (final memory in memoriesSnapshot.docs) {
        await albumRef.collection('sharedMedia').doc(memory.id).set(memory.data());
      }
    } else {
      final data = albumDoc.data()!;
      final sharedWith = List<String>.from(data['sharedWith'] ?? []);
      if (!sharedWith.contains(friendUid)) {
        sharedWith.add(friendUid);
        await albumRef.update({'sharedWith': sharedWith});
      }
    }
  }

  /// Génère un code unique pour l'invitation
  String _generateRandomCode(int length) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rand = Random();
    return List.generate(length, (_) => chars[rand.nextInt(chars.length)]).join();
  }

  /// Génère et stocke un lien d'invitation unique
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

  /// Partage tous les albums de inviterUserId avec friendId
  Future<void> _shareAlbumsWithUser(String inviterUserId, String friendId) async {
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
}
