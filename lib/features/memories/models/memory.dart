import 'package:cloud_firestore/cloud_firestore.dart';

class Memory {

  final String id;
  final String? ville;
  final String url;
  final String type;
  final DateTime date;
  final DocumentSnapshot documentSnapshot;


  Memory({
    required this.id,
    this.ville,
    required this.url,
    required this.type,
    required this.date,
    required this.documentSnapshot
  });

  factory Memory.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Memory(
      id: doc.id,
      ville: data['ville'] as String? ,
      url: data['url'] as String ,
      type: data['type'] as String,
      date: (data['date'] as Timestamp).toDate(),
      documentSnapshot: doc,
    );
  }


}