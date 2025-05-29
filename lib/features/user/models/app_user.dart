import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String displayName;
  final String email;
  final String photoURL;
  final String role;
  final List<String> friends; // Liste des ID des amis

  AppUser({
    required this.uid,
    required this.displayName,
    required this.email,
    required this.photoURL,
    required this.role,
    required this.friends,
  });

  factory AppUser.fromDocument(DocumentSnapshot doc) {
    return AppUser(
      uid: doc.id,
      displayName: doc['displayName'],
      email: doc['email'],
      photoURL: doc['photoURL'],
      role: doc['role'],
      friends: List<String>.from(doc['friends'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'displayName': displayName,
      'email': email,
      'photoURL': photoURL,
      'role': role,
      'friends': friends,
    };
  }
}
