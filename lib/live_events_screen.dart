import 'package:flutter/material.dart';
import 'main.dart' show HomeScreen;
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LiveEventsScreen extends StatefulWidget {
  const LiveEventsScreen({Key? key}) : super(key: key);

  @override
  State<LiveEventsScreen> createState() => _LiveEventsScreenState();
}

class _LiveEventsScreenState extends State<LiveEventsScreen> {
  final TextEditingController _searchController = TextEditingController();

  // 📡 Unified Backend Pipeline Data States
  List<dynamic> _upcomingEvents = [];
  List<dynamic> _videoPlaylist = [];

  bool _isEventsLoading = true;
  bool _isPlaylistLoading = true;
  String? _playlistErrorMessage;

  // 📡 Spring Boot Server endpoints
  final String _eventsApiUrl = "http://10.34.113.23:8080/api/events/all";
  final String _playlistApiUrl = "http://10.34.113.23:8080/api/live/current";

  @override
  void initState() {
    super.initState();
    _refreshAllScreenData();
  }

  // Synchronous engine invocation to load both data grids simultaneously
  Future<void> _refreshAllScreenData() async {
    await Future.wait([
      _fetchUpcomingEventsCatalog(),
      _fetchLiveStreamPlaylist(),
    ]);
  }

  Future<void> _fetchUpcomingEventsCatalog() async {
    try {
      final response = await http.get(Uri.parse(_eventsApiUrl));
      if (response.statusCode == 200) {
        if (!mounted) return;
        setState(() {
          _upcomingEvents = jsonDecode(response.body);
          _isEventsLoading = false;
        });
      } else {
        if (!mounted) return;
        setState(() => _isEventsLoading = false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isEventsLoading = false);
    }
  }

  Future<void> _fetchLiveStreamPlaylist() async {
    if (!mounted) return;
    setState(() {
      _isPlaylistLoading = true;
      _playlistErrorMessage = null;
    });

    try {
      final response = await http.get(Uri.parse(_playlistApiUrl));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (!mounted) return;
        setState(() {
          _videoPlaylist = data;
          _isPlaylistLoading = false;
        });
      } else {
        throw Exception();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isPlaylistLoading = false;
        _playlistErrorMessage = "Offline";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.redAccent),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const HomeScreen()),
              );
            }
          },
        ),
        title: const Text(
          'Live and ongoing events / sermons',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      // 🎯 Global SingleChildScrollView removed to freeze the top header dashboard
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔍 Search Bar Layout (Pinned)
            Container(
              height: 46,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.black87, width: 1.2),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  const Icon(Icons.search, color: Colors.black87, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(fontSize: 14),
                      decoration: const InputDecoration(
                        hintText: 'Search for events / sermons...',
                        hintStyle: TextStyle(color: Colors.blueGrey, fontSize: 13.5),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 📺 PERSISTENT VIDEO MONITOR FRAMEWORK (Pinned)
            CathedralLivePlayer(
              playlist: _videoPlaylist,
              isLoading: _isPlaylistLoading,
              errorMessage: _playlistErrorMessage,
              onRefreshTriggered: _fetchLiveStreamPlaylist,
            ),
            const SizedBox(height: 24),

            // 🎯 RECENT SERVICES AREA (Pinned)
            const Text(
              'Recent Services',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black54),
            ),
            const SizedBox(height: 10),
            _buildRecentServicesSection(),
            const SizedBox(height: 24),

            // 📅 FEATURED UPCOMING EVENTS HEADER (Pinned right above scroll view)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Featured upcoming events.',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                InkWell(
                  onTap: () {},
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.redAccent, width: 1),
                    ),
                    child: const Text(
                      'See All',
                      style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 📜 SCROLLABLE CONTAINER ZONE
            // Expanded isolates the scrolling engine specifically to the bottom catalog feed
            Expanded(
              child: RefreshIndicator(
                color: const Color(0xFF0D47A1),
                onRefresh: _refreshAllScreenData,
                child: _buildUpcomingEventsCatalog(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🛠️ Renders the horizontal panel matching your drawing notes exactly
  Widget _buildRecentServicesSection() {
    if (_isPlaylistLoading) {
      return SizedBox(
        height: 85,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 3,
          itemBuilder: (context, index) => Container(
            width: 150,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.grey),
              ),
            ),
          ),
        ),
      );
    }

    if (_playlistErrorMessage != null || _videoPlaylist.isEmpty) {
      return SizedBox(
        height: 85,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            Container(
              width: 180,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _playlistErrorMessage == "Offline" ? 'Network connection lost' : 'No archives found',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  const Text('Recent items remain offline', style: TextStyle(fontSize: 10, color: Colors.blueGrey)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (scrollNotification) => true,
      child: SizedBox(
        height: 85,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          itemCount: _videoPlaylist.length,
          itemBuilder: (context, index) {
            final video = _videoPlaylist[index];
            final bool isSelected = index == CathedralLivePlayer.globalPlayingIndex;

            return GestureDetector(
              onTap: () {
                if (isSelected) return;
                CathedralLivePlayer.playerStateTrigger?.call(index);
              },
              child: Container(
                width: 150,
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF0D47A1).withOpacity(0.08) : Colors.grey[50],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF0D47A1) : Colors.grey[300]!,
                    width: isSelected ? 1.8 : 1.0,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      video['title'] ?? 'Sermon service',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? const Color(0xFF0D47A1) : Colors.black87
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                            video['live'] == true ? Icons.live_tv : Icons.lens,
                            size: 10,
                            color: video['live'] == true ? Colors.red : Colors.grey
                        ),
                        const SizedBox(width: 4),
                        Text(
                          video['live'] == true ? "LIVE" : "RECORDED",
                          style: TextStyle(fontSize: 9, color: Colors.grey[600], fontWeight: FontWeight.bold),
                        )
                      ],
                    )
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildUpcomingEventsCatalog() {
    if (_isEventsLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: CircularProgressIndicator(color: Color(0xFF0D47A1)),
        ),
      );
    }

    if (_upcomingEvents.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20.0),
        child: Text(
          'No upcoming cathedral events found.',
          style: TextStyle(color: Colors.grey, fontSize: 14),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 24), // Extends clear scrolling padding at base of screen
      shrinkWrap: true,
      physics: const BouncingScrollPhysics(), // 🎯 Reactivated scroll gestures specifically inside this view bounds
      itemCount: _upcomingEvents.length,
      itemBuilder: (context, index) {
        final item = _upcomingEvents[index];
       // return _buildUpcomingEventsCatalog(events)
        String eventDate = item['eventDate'] ?? "Upcoming";
        if (eventDate.length >= 10) {
          eventDate = eventDate.substring(0, 10);
        }

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!, width: 1.2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item['eventTitle'] ?? 'Cathedral Fellowship',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0D47A1)),
              ),
              const SizedBox(height: 4),
              Text(
                item['description'] ?? 'Join us in prayer and worship.',
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Church Event',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.add, color: Colors.grey[700], size: 20),
                          const SizedBox(width: 12),
                          Icon(Icons.person_outline, color: Colors.grey[700], size: 20),
                        ],
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Scheduled at',
                        style: TextStyle(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.w500),
                      ),
                      Text(
                        eventDate,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// 🏛️ REFACTORED MONITOR ENGINE INTERFACED WITH GLOBAL ROW LISTENER
class CathedralLivePlayer extends StatefulWidget {
  final List<dynamic> playlist;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onRefreshTriggered;

  static int globalPlayingIndex = 0;
  static ValueChanged<int>? playerStateTrigger;

  const CathedralLivePlayer({
    Key? key,
    required this.playlist,
    required this.isLoading,
    required this.errorMessage,
    required this.onRefreshTriggered,
  }) : super(key: key);

  @override
  State<CathedralLivePlayer> createState() => _CathedralLivePlayerState();
}

class _CathedralLivePlayerState extends State<CathedralLivePlayer> {
  VideoPlayerController? _videoController;
  bool _isInternalLoading = false;
  String? _internalVideoError;

  @override
  void initState() {
    super.initState();
    CathedralLivePlayer.globalPlayingIndex = 0;
    CathedralLivePlayer.playerStateTrigger = (targetIndex) {
      if (!mounted) return;
      setState(() {
        CathedralLivePlayer.globalPlayingIndex = targetIndex;
      });
      _bootVideoEngine(widget.playlist[targetIndex]['streamUrl']);
    };

    if (widget.playlist.isNotEmpty) {
      _bootVideoEngine(widget.playlist[0]['streamUrl']);
    }
  }

  @override
  void didUpdateWidget(covariant CathedralLivePlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.playlist.isEmpty && widget.playlist.isNotEmpty && _videoController == null) {
      CathedralLivePlayer.globalPlayingIndex = 0;
      _bootVideoEngine(widget.playlist[0]['streamUrl']);
    }
  }

  Future<void> _bootVideoEngine(String url) async {
    if (!mounted) return;
    setState(() {
      _isInternalLoading = true;
      _internalVideoError = null;
    });

    if (_videoController != null) {
      try {
        await _videoController!.pause();
        await _videoController!.dispose();
      } catch (e) {
        print("Disposal caught: $e");
      }
      _videoController = null;
    }

    final VideoPlayerController newController = VideoPlayerController.networkUrl(Uri.parse(url));
    try {
      await newController.initialize();
      if (!mounted) {
        await newController.dispose();
        return;
      }
      setState(() {
        _videoController = newController;
        _isInternalLoading = false;
      });
      await _videoController!.play();
      await WakelockPlus.enable();
    } catch (e) {
      if (!mounted) return;
      await newController.dispose();
      setState(() {
        _videoController = null;
        _isInternalLoading = false;
        _internalVideoError = "Video link processing failed.";
      });
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool currentLoadingState = widget.isLoading || _isInternalLoading;
    final String? clearErrors = _internalVideoError ?? widget.errorMessage;

    final Map<String, dynamic> currentVideo = widget.playlist.isNotEmpty &&
        CathedralLivePlayer.globalPlayingIndex < widget.playlist.length
        ? widget.playlist[CathedralLivePlayer.globalPlayingIndex]
        : {};

    final String title = currentVideo['title'] ?? "Cathedral Sermon Service";
    final bool activeLiveTag = currentVideo['live'] == true;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.redAccent.withOpacity(0.4), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 170,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (currentLoadingState)
                  const CircularProgressIndicator(color: Colors.redAccent)
                else if (clearErrors != null && _videoController == null)
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(
                      clearErrors == "Offline"
                          ? "Media interface offline.\nPull down screen to refresh link network."
                          : clearErrors,
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  )
                else if (_videoController != null)
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
                      child: AspectRatio(
                        aspectRatio: _videoController!.value.aspectRatio,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _videoController!.value.isPlaying
                                  ? _videoController!.pause()
                                  : _videoController!.play();
                            });
                          },
                          child: VideoPlayer(_videoController!),
                        ),
                      ),
                    )
                  else
                    const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: Text(
                        "No ongoing live broadcast channels detected.",
                        style: TextStyle(color: Colors.white38, fontSize: 13),
                      ),
                    ),

                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: activeLiveTag ? Colors.redAccent : Colors.grey[700],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      activeLiveTag ? 'LIVE' : 'ARCHIVE',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),

                if (!currentLoadingState)
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: InkWell(
                      onTap: widget.onRefreshTriggered,
                      borderRadius: BorderRadius.circular(30),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1),
                        ),
                        child: const Icon(Icons.refresh, color: Colors.white, size: 18),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87, height: 1.3),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: activeLiveTag ? Colors.red : Colors.grey,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      activeLiveTag ? 'Live Stream Ongoing' : 'Recorded Sermon',
                      style: TextStyle(
                          color: activeLiveTag ? Colors.red : Colors.grey,
                          fontWeight: FontWeight.bold,
                          fontSize: 13
                      ),
                    ),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}