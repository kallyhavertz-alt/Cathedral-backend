import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class FeedVideoPreview extends StatefulWidget {
  final String videoUrl;
  const FeedVideoPreview({Key? key, required this.videoUrl}) : super(key: key);

  @override
  State<FeedVideoPreview> createState() => _FeedVideoPreviewState();
}


class _FeedVideoPreviewState extends State<FeedVideoPreview> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _showControls = true; // Tracks whether the play button should be visible

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        setState(() {
          _isInitialized = true;
        });
        // 🟩 FIX 1: Turn sound up to max volume (1.0) instead of being muted (0.0)
        _controller.setVolume(1.0);

        // Loop videos automatically for a smooth shorts experience
        _controller.setLooping(true);
      });
  }

  // Helper method to auto-hide the button after 2 seconds
  void _startAutoHideTimer() {
    if (_controller.value.isPlaying) {
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted && _controller.value.isPlaying) {
          setState(() {
            _showControls = false;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    return GestureDetector(
      // 🟩 Tapping anywhere on the video card toggles controls or pauses
      onTap: () {
        setState(() {
          _showControls = !_showControls;
          if (_showControls) {
            _startAutoHideTimer();
          }
        });
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          // The Native Moving Video Frame
          SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.cover,
              clipBehavior: Clip.antiAlias,
              child: SizedBox(
                width: _controller.value.size.width,
                height: _controller.value.size.height,
                child: VideoPlayer(_controller),
              ),
            ),
          ),

          // 🟩 FIX 2: Dynamic Animated Controller Overlay
          AnimatedOpacity(
            opacity: _showControls ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: IgnorePointer(
              ignoring: !_showControls, // Prevents taps on hidden buttons
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Subtle dark shade behind button for readability
                  Container(color: Colors.black.withOpacity(0.25)),

                  // Clean Blue Action Button
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: Colors.blue.shade700.withOpacity(0.9),
                    child: IconButton(
                      icon: Icon(
                        _controller.value.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 30,
                      ),
                      onPressed: () {
                        setState(() {
                          if (_controller.value.isPlaying) {
                            _controller.pause();
                          } else {
                            _controller.play();
                            _startAutoHideTimer(); // Start countdown to disappear
                          }
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}