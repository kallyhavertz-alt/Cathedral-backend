import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class FeedVideoPreview extends StatefulWidget {
  final String videoUrl;
  final bool showControls;
  final bool autoPlay;
  final bool muted;

  const FeedVideoPreview({
    Key? key, 
    required this.videoUrl,
    this.showControls = true,
    this.autoPlay = false,
    this.muted = false,
  }) : super(key: key);

  @override
  State<FeedVideoPreview> createState() => _FeedVideoPreviewState();
}


class _FeedVideoPreviewState extends State<FeedVideoPreview> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  late bool _showControls;
  bool _isManuallyPaused = false;

  @override
  void initState() {
    super.initState();
    _showControls = widget.showControls;
    
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() {
          _isInitialized = true;
        });
        
        // 🔊 Volume logic: muted if requested, otherwise full volume
        _controller.setVolume(widget.muted ? 0.0 : 1.0);
        _controller.setLooping(true);

        if (widget.autoPlay || !widget.showControls) {
           _controller.play();
           if (_showControls) _startAutoHideTimer();
        }
      });
  }

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
      onTap: () {
        setState(() {
          if (_controller.value.isPlaying) {
            _controller.pause();
            _isManuallyPaused = true;
          } else {
            _controller.play();
            _isManuallyPaused = false;
            if (widget.showControls) _startAutoHideTimer();
          }
          
          if (widget.showControls) {
            _showControls = !_showControls;
          }
        });
      }, 
      child: Stack(
        alignment: Alignment.center,
        children: [
          // The Native Moving Video Frame
          SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.contain,
              clipBehavior: Clip.antiAlias,
              child: SizedBox(
                width: _controller.value.size.width,
                height: _controller.value.size.height,
                child: VideoPlayer(_controller),
              ),
            ),
          ),

          // 🎬 PAUSE INDICATOR (For Reels style)
          if (!widget.showControls && _isManuallyPaused)
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(12),
              child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 40),
            ),

          // 🎬 CONTROLS OVERLAY (Standard Post style)
          if (widget.showControls)
            AnimatedOpacity(
              opacity: _showControls ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: IgnorePointer(
                ignoring: !_showControls,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(color: Colors.black.withValues(alpha: 0.25)),
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: Colors.blue.shade700.withValues(alpha: 0.9),
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
                              _isManuallyPaused = true;
                            } else {
                              _controller.play();
                              _isManuallyPaused = false;
                              _startAutoHideTimer();
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
