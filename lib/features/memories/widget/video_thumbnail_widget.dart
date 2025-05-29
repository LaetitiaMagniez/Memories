import 'dart:typed_data';
import 'package:flutter/foundation.dart'; // Pour kIsWeb
import 'package:flutter/material.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class VideoThumbnailWidget extends StatefulWidget {
  final String videoPath;

  const VideoThumbnailWidget(this.videoPath, {super.key});

  @override
  State<VideoThumbnailWidget> createState() => _VideoThumbnailWidgetState();
}

class _VideoThumbnailWidgetState extends State<VideoThumbnailWidget> {
  Uint8List? _thumbnail;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _generateThumbnail();
    } else {
      _isLoading = false;
    }
  }

  Future<void> _generateThumbnail() async {
    try {
      final thumbnail = await VideoThumbnail.thumbnailData(
        video: widget.videoPath,
        imageFormat: ImageFormat.PNG,
        maxWidth: 120,
        quality: 75,
      );

      if (mounted) {
        setState(() {
          _thumbnail = thumbnail;
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      print('Erreur lors de la génération de la miniature : $e');
      print('Trace d\'appel : $stackTrace');
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
                ? Image.memory(_thumbnail!, fit: BoxFit.cover)
                : Container(
              color: Colors.grey[300],
              child: Icon(Icons.videocam, color: Colors.grey[600]),
            ),
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
