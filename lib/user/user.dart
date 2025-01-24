import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  String? uid;
  String? displayName;
  String? email;
  String? photoURL;

  User({this.uid, this.displayName, this.email, this.photoURL});

  // Create a User object from a Firestore document snapshot
  factory User.fromDocument(DocumentSnapshot doc) {
    return User(
      uid: doc.id,
      displayName: doc['displayName'],
      email: doc['email'],
      photoURL: doc['photoURL'],
    );
  }
}