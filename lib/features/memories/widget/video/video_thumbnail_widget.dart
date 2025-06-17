import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/utils/file_cache.dart';

class VideoThumbnailWidget extends StatefulWidget {
  final String videoPath;

  const VideoThumbnailWidget(this.videoPath, {super.key});

  @override
  State<VideoThumbnailWidget> createState() => _VideoThumbnailWidgetState();
}

class _VideoThumbnailWidgetState extends State<VideoThumbnailWidget> {
  String? _thumbnailPath;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _loadOrGenerateThumbnail();
    } else {
      _isLoading = false;
    }
  }

  Future<void> _loadOrGenerateThumbnail() async {
    try {
      final path = await getCachedThumbnailPath(widget.videoPath);
      if (mounted) {
        setState(() {
          _thumbnailPath = path;
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      print('Erreur thumbnail: $e\n$stackTrace');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8.0),
      child: Stack(
        fit: StackFit.expand,
        children: [
          _isLoading
              ? Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(color: Colors.white),
          )
              : _thumbnailPath != null
              ? Image.file(
            File(_thumbnailPath!),
            fit: BoxFit.cover,
          )
              : Container(
            color: Colors.grey[300],
            child: Icon(Icons.videocam, color: Colors.grey[600]),
          ),
          Center(
            child: Icon(
              Icons.play_circle_fill,
              size: 40,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
}
