import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:math';

import '../classes/appUser.dart';

class ContactService {
  AppUser? _currentUser;
  List<AppUser> friends = [];
  int invitationsSent = 0;


  //Récupération de l'utilisateur actif
  Future<AppUser?> loadCurrentUser() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();
        if (userDoc.exists) {
          return AppUser.fromDocument(userDoc);
        } else {
          // L'utilisateur n'existe pas dans Firestore, gérez ce cas si nécessaire
          return null;
        }
      } else {
        // L'utilisateur n'est pas connecté, gérez ce cas si nécessaire
        return null;
      }
    } catch (e) {
      // Gérez les erreurs éventuelles
      print('Erreur lors de la récupération de l\'utilisateur actuel : $e');
      return null;
    }
  }


  // Logique d'invitation par sms et email

  Future<void> sendInvite() async {
    // Générer un lien unique
    String inviteLink = await _generateUniqueInviteLink();

    // Construire le message à partager
    String message = "Rejoins moi sur Memories ! Clique sur le lien suivant pour t'inscrire : $inviteLink";

    // Partager le message
    await Share.share(message);
    invitationsSent++;
  }

  String _generateRandomCode(int length) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return String.fromCharCodes(Iterable.generate(
        length, (_) => chars.codeUnitAt(Random().nextInt(chars.length))));
  }

  Future<String> _generateUniqueInviteLink() async {
    // Générer un code unique de 6 caractères
    String code = _generateRandomCode(6);

    // Construire l'URL du lien unique
    String url = "https://memories-7bdc6.firebaseapp.com/?code=$code";

    // Enregistrer le code unique associé à l'utilisateur actuel
    // Stocker le code unique associé à l'utilisateur actuel dans Firestore
    await _storeInviteCode(code, FirebaseAuth.instance.currentUser!.uid);

    return url;
  }

  Future<void> _storeInviteCode(String code, String userId) async {
    // Stocker le code unique dans une collection "invite_codes" dans Firestore
    await FirebaseFirestore.instance
        .collection('invite_codes')
        .doc(code)
        .set({'userId': userId, 'createdAt': FieldValue.serverTimestamp()});
  }

  getInvitationsSent() async {
    final invitationCodes = await FirebaseFirestore.instance
        .collection('invite_codes')
        .where('userId', isEqualTo: _currentUser?.uid)
        .get();

    int invitationsAlreadySent = invitationCodes.docs.length;
    return invitationsAlreadySent;
  }

  // Gestion des amis
  Future<void> loadFriends() async {
    final currentUser = await loadCurrentUser();
    if (currentUser != null) {
      final friendDocs = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('friends')
          .get();
      friends =
          friendDocs.docs.map((doc) => AppUser.fromDocument(doc)).toList();
    }
  }

  Future<void> removeFriend(AppUser friend) async {
    final currentUser = await loadCurrentUser();
    if (currentUser != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('friends')
          .doc(friend.uid)
          .delete();
      friends.remove(friend);
    }
  }

  Future<void> addFriend(String friendId, String inviterUserId) async {
    final currentUser = await FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      // Ajouter l'ami à la sous-collection "friends" de l'utilisateur courant
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('friends')
          .doc(friendId)
          .set({'createdAt': FieldValue.serverTimestamp(), 'role': 'Editeur'});

      // Ajouter l'utilisateur courant à la sous-collection "friends" de l'ami
      await FirebaseFirestore.instance
          .collection('users')
          .doc(friendId)
          .collection('friends')
          .doc(currentUser.uid)
          .set({'createdAt': FieldValue.serverTimestamp(), 'role': 'Editeur'});

      // Ajouter l'utilisateur qui a envoyé l'invitation à la sous-collection "friends" de l'ami
      await FirebaseFirestore.instance
          .collection('users')
          .doc(friendId)
          .collection('friends')
          .doc(inviterUserId)
          .set({'createdAt': FieldValue.serverTimestamp(), 'role': 'Editeur'});

      // Récupérer les albums de l'utilisateur qui a envoyé le lien
      final albumsSnapshot = await FirebaseFirestore.instance
          .collection('albums')
          .where('userId', isEqualTo: inviterUserId)
          .get();

      // Partager les albums avec l'ami invité
      for (final album in albumsSnapshot.docs) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(friendId)
            .collection('albums')
            .doc(album.id)
            .set(album.data());

        // Récupérer les souvenirs de l'album
        final memoriesSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(inviterUserId)
            .collection('albums')
            .doc(album.id)
            .collection('media')
            .get();

        // Partager les souvenirs avec l'ami invité
        for (final memory in memoriesSnapshot.docs) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(friendId)
              .collection('albums')
              .doc(album.id)
              .collection('sharedMedia')
              .doc(memory.id)
              .set(memory.data());
        }
      }
    }
  }

}