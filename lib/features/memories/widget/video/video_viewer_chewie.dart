import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

class VideoViewerChewie extends StatefulWidget {
  final String videoUrl;
  const VideoViewerChewie(this.videoUrl, {super.key});

  @override
  _VideoViewerChewieState createState() => _VideoViewerChewieState();
}

class _VideoViewerChewieState extends State<VideoViewerChewie> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    _videoPlayerController = VideoPlayerController.networkUrl(widget.videoUrl as Uri);
    await _videoPlayerController.initialize();
    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController,
      autoPlay: true,
      looping: false,
      showControlsOnInitialize: true,
      allowFullScreen: true,
    );
    setState(() {});
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vidéo')),
      body: _chewieController != null && _chewieController!.videoPlayerController.value.isInitialized
          ? Chewie(controller: _chewieController!)
          : const Center(child: CircularProgressIndicator()),
    );
  }
}
