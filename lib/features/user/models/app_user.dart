import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String username;
  final String email;
  final String profilePicture;
  final String role;

  AppUser({
    required this.uid,
    required this.username,
    required this.email,
    required this.profilePicture,
    required this.role,
  });

  factory AppUser.fromDocument(DocumentSnapshot doc) {
    return AppUser(
      uid: doc.id,
      username: doc['username'],
      email: doc['email'],
      profilePicture: doc['profilePicture'],
      role: doc['role'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'email': email,
      'profilePicture': profilePicture,
      'role': role,
    };
  }
}
