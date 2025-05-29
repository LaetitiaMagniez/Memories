import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class VideoThumbnailWidget extends StatefulWidget {  // Renommé la classe ici
  final String videoPath;

  const VideoThumbnailWidget(this.videoPath, {super.key});  // Renommé ici

  @override
  State<VideoThumbnailWidget> createState() => _VideoThumbnailWidgetState();  // Renommé ici
}

class _VideoThumbnailWidgetState extends State<VideoThumbnailWidget> {  // Renommé ici
  Uint8List? _thumbnail;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _generateThumbnail();
  }

  Future<void> _generateThumbnail() async {
    final thumbnail = await VideoThumbnail.thumbnailData(
      video: widget.videoPath,
      imageFormat: ImageFormat.PNG,
      maxWidth: 120, // correspond à la taille de l'affichage
      quality: 75,
    );

    if (mounted) {
      setState(() {
        _thumbnail = thumbnail;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      height: 120,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8.0),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _isLoading
                ? Container(color: Colors.grey[300])
                : _thumbnail != null
                ? Image.memory(
              _thumbnail!,
              fit: BoxFit.cover,
            )
                : Container(color: Colors.grey[300]),
            Center(
              child: Icon(
                Icons.play_circle_fill,
                size: 40,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
