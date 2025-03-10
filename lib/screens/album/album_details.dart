import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memories_project/service/souvenir_service.dart';
import 'package:memories_project/souvenir_view/full_screen_image_view.dart';
import 'package:memories_project/souvenir_view/video_thumbnail.dart';
import 'package:memories_project/souvenir_view/video_viewer.dart';

class AlbumDetailPage extends StatefulWidget {
  final String albumId;
  final String albumName;

  AlbumDetailPage({required this.albumId, required this.albumName});

  @override
  _AlbumDetailPageState createState() => _AlbumDetailPageState();
}

class _AlbumDetailPageState extends State<AlbumDetailPage> {
  final SouvenirService souvenirService = SouvenirService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.albumName)),
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () => souvenirService.pickAndUploadMedia(context, widget.albumId, 'image'),
                child: Text('Ajouter une image'),
              ),
              ElevatedButton(
                onPressed: () => souvenirService.pickAndUploadMedia(context, widget.albumId, 'video'),
                child: Text('Ajouter une vidéo'),
              ),
            ],
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('albums')
                .doc(widget.albumId)
                .collection('media')
                .orderBy('timestamp', descending: true)
                .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return CircularProgressIndicator();

                return GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 1.0,
                  ),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var doc = snapshot.data!.docs[index];
                    return GestureDetector(
                      onLongPress: () => souvenirService.showDeleteConfirmationDialog(context, widget.albumId, doc.id),
                      onTap: () {
                        if (doc['type'] == 'image') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FullScreenImageView(url: doc['url']),
                            ),
                          );
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => VideoViewer(doc['url']),
                            ),
                          );
                        }
                      },
                      child: doc['type'] == 'image'
                      ? Image.network(
                          doc['url'], 
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            );
                          },
                        )
                      : VideoThumbnail(doc['url']),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}