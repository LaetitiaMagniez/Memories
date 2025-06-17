import 'package:cloud_firestore/cloud_firestore.dart';

class Friend {
  final String uid;
  final String status;
  final Timestamp since;

  Friend({
    required this.uid,
    required this.status,
    required this.since,
  });

  factory Friend.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Friend(
      uid: doc.id,
      status: data['status'] ?? 'accepted',
      since: data['since'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'status': status,
      'since': since,
    };
  }
}
