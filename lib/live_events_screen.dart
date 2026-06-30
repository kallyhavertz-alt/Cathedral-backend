import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'main.dart' show HomeScreen;
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:share_plus/share_plus.dart';

class LiveEventsScreen extends StatefulWidget {
  const LiveEventsScreen({Key? key}) : super(key: key);

  @override
  State<LiveEventsScreen> createState() => _LiveEventsScreenState();
}

class _LiveEventsScreenState extends State<LiveEventsScreen> {
  final TextEditingController _searchController = TextEditingController();

  // 📡 Unified Backend Pipeline Data States
  List<dynamic> _upcomingEvents = [];
  List<dynamic> _filteredEvents = []; //search-matched events
  List<dynamic> _videoPlaylist = [];

  bool _isEventsLoading = true;
  bool _isPlaylistLoading = true;
  String? _playlistErrorMessage;

  // 📡 Spring Boot Server endpoints
  final String _eventsApiUrl = "http://192.168.100.33:8080/api/events/all";
  final String _playlistApiUrl = "http://192.168.100.33:8080/api/live/current";

  @override
  void initState() {
    super.initState();
    _refreshAllScreenData();
  }

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
          _filteredEvents = _upcomingEvents; // filter cache
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

  // Processes real-time query inputs without slamming Spring Boot endpoints
  void _filterDisplayCatalog(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredEvents = _upcomingEvents;
      } else {
        _filteredEvents = _upcomingEvents.where((event) {
          final String title = (event['eventTitle'] ?? '').toString().toLowerCase();
          final String desc = (event['description'] ?? '').toString().toLowerCase();
          final String searchLower = query.toLowerCase();

          return title.contains(searchLower) || desc.contains(searchLower);
        }).toList();
      }
    });
  }
  bool _checkIfTrulyLive(dynamic video) {
    if (video == null || video['islive'] != true) {
      return false;
    }
    final String? timestampStr = video['updatedAt'] ?? video['updatedAt'] ?? video['eventDate'];

    if (timestampStr == null) {
      return true; // Fallback to raw flag if no timestamp is present
    }

    try {
      final DateTime uploadTime = DateTime.parse(timestampStr);
      final DateTime now = DateTime.now();
      final Duration difference = now.difference(uploadTime);

      // If the stream has been running for more than 3 hours,
      // let it be false
      if (difference.inHours >= 3) {
        print("⏰ Stream Auto-Expiry: Overriding '${video['title']}' to RECORDED (Active for ${difference.inHours} hours)");
        return false;
      }
    } catch (e) {
      print("⚠️ Error parsing stream timestamp window: $e");
    }

    return true; //  within the 3-hour
  }

  // fallback for back-button actions
  @override
  void dispose() {
    _resetDeviceOrientationToPortrait();
    _searchController.dispose();
    super.dispose();
  }

  void _resetDeviceOrientationToPortrait() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: SystemUiOverlay.values);
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color scaffoldBg = isDark ? const Color(0xFF121212) : Colors.white;
    final Color elementBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final Color primaryTextColor = isDark ? const Color(0xFFEEEEEE) : Colors.black87;
    final Color secondaryTextColor = isDark ? Colors.grey[400]! : Colors.black54;
    final Color structuralBorderColor = isDark ? Colors.grey[800]! : Colors.black87;

    // kills full-screen status codes, and pops back safely.
    return PopScope(
      canPop: false, // Stop automatic raw un-managed dismiss actions
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        // Force orientation correction
        _resetDeviceOrientationToPortrait();

        // Allow UI pipeline frames to reset before routing
        await Future.delayed(const Duration(milliseconds: 100));

        if (!mounted) return;
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        }
      },
      child: Scaffold(
        backgroundColor: scaffoldBg,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.redAccent),
            onPressed: () {
              _resetDeviceOrientationToPortrait();
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
          title: Text(
            'Live and ongoing events / sermons',
            style: TextStyle(color: primaryTextColor, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          backgroundColor: scaffoldBg,
          elevation: 0,
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              Container(
                height: 46,
                decoration: BoxDecoration(
                  color: elementBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: structuralBorderColor, width: 1.2),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Icon(Icons.search, color: primaryTextColor, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: _filterDisplayCatalog,
                        style: TextStyle(fontSize: 14, color: primaryTextColor),
                        decoration: InputDecoration(
                          hintText: 'Search for events / sermons...',
                          hintStyle: TextStyle(color: isDark ? Colors.grey[500] : Colors.blueGrey, fontSize: 13.5),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              //  PERSISTENT VIDEO MONITOR FRAMEWORK
              CathedralLivePlayer(
                playlist: _videoPlaylist,
                isLoading: _isPlaylistLoading,
                errorMessage: _playlistErrorMessage,
                onRefreshTriggered: _fetchLiveStreamPlaylist,
                isLiveOverride: _videoPlaylist.isNotEmpty &&
                    CathedralLivePlayer.globalPlayingIndex < _videoPlaylist.length
                    ? _checkIfTrulyLive(_videoPlaylist[CathedralLivePlayer.globalPlayingIndex])
                    : false,
              ),
              const SizedBox(height: 24),

              //  RECENT SERVICES AREA
              Text(
                'Recent Services',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: secondaryTextColor),
              ),
              const SizedBox(height: 10),
              _buildRecentServicesSection(isDark, elementBg, primaryTextColor),
              const SizedBox(height: 24),

              //  FEATURED UPCOMING EVENTS HEADER
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Featured events.',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryTextColor),
                  ),
                  InkWell(
                    onTap: () {},
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: elementBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.redAccent, width: 1),
                      ),
                      child: const Text(
                        'All',
                        style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Expanded(
                child: RefreshIndicator(
                  color: const Color(0xFF0D47A1),
                  onRefresh: _refreshAllScreenData,
                  child: _buildUpcomingEventsCatalog(isDark, elementBg, primaryTextColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentServicesSection(bool isDark, Color elementBg, Color primaryTextColor) {
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
              color: isDark ? const Color(0xFF242424) : Colors.grey[100],
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
            ),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: isDark ? Colors.grey[600] : Colors.grey),
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
                color: isDark ? const Color(0xFF242424) : Colors.grey[50],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _playlistErrorMessage == "Offline" ? 'Network connection lost' : 'No offline videos found',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.grey[500] : Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Text('Recent items remain offline', style: TextStyle(fontSize: 10, color: isDark ? Colors.grey[400] : Colors.blueGrey)),
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
            final bool isTrulyLive = _checkIfTrulyLive(video);

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
                  color: isSelected
                      ? const Color(0xFF0D47A1).withValues(alpha: isDark ? 0.25 : 0.08)
                      : (isDark ? const Color(0xFF242424) : Colors.grey[50]),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF0D47A1) : (isDark ? Colors.grey[800]! : Colors.grey[300]!),
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
                          color: isSelected ? (isDark ? const Color(0xFF42A5F5) : const Color(0xFF0D47A1)) : primaryTextColor
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                            isTrulyLive ? Icons.live_tv : Icons.lens,
                            size: 10,
                            color: isTrulyLive ? Colors.red : Colors.grey
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isTrulyLive ? "LIVE" : "RECORDED",
                          style: TextStyle(fontSize: 9, color: Colors.grey[500], fontWeight: FontWeight.bold),
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

  Widget _buildUpcomingEventsCatalog(bool isDark, Color elementBg, Color primaryTextColor) {
    if (_isEventsLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: CircularProgressIndicator(color: Color(0xFF0D47A1)),
        ),
      );
    }

    // 🚀 Configured to seamlessly read from the filtered items list
    if (_filteredEvents.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20.0),
        child: Text(
          'No matching cathedral events found.',
          style: TextStyle(color: Colors.grey, fontSize: 14),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 24),
      shrinkWrap: true,
      physics: const BouncingScrollPhysics(),
      itemCount: _filteredEvents.length,
      itemBuilder: (context, index) {
        final item = _filteredEvents[index];
        String eventDate = item['eventDate'] ?? "Upcoming";
        if (eventDate.length >= 10) {
          eventDate = eventDate.substring(0, 10);
        }

        final String eventTitle = item['eventTitle'] ?? 'Cathedral Fellowship';
        final String eventDesc = item['description'] ?? 'Join us in prayer and worship.';

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: elementBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[300]!, width: 1.2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eventTitle,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? const Color(0xFF42A5F5) : const Color(0xFF0D47A1)),
              ),
              const SizedBox(height: 4),
              Text(
                eventDesc,
                style: TextStyle(fontSize: 13, color: isDark ? Colors.grey[400] : Colors.grey[600]),
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
                      Text(
                        'Church Event',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: primaryTextColor),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: Icon(Icons.share, color: isDark ? Colors.grey[400] : Colors.grey[700], size: 20),
                            onPressed: () {
                              final String shareMessage =
                                  "ACK St. James Cathedral Event Update ⛪\n\n"
                                  "Event: $eventTitle\n"
                                  "Scheduled Date: $eventDate\n\n"
                                  "$eventDesc\n\n"
                                  "Join us as we receive blessings and be counted!";
                              Share.share(shareMessage);
                            },
                          ),
                          const SizedBox(width: 16),
                          Icon(Icons.person_outline, color: isDark ? Colors.grey[400] : Colors.grey[700], size: 20),
                        ],
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Scheduled at',
                        style: TextStyle(fontSize: 11, color: isDark ? Colors.grey[400] : Colors.grey[600], fontWeight: FontWeight.w500),
                      ),
                      Text(
                        eventDate,
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: primaryTextColor),
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

//  STABLE MONITOR ENGINE
class CathedralLivePlayer extends StatefulWidget {
  final List<dynamic> playlist;
  final bool isLoading;
  final bool isLiveOverride;
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
    required this.isLiveOverride,
  }) : super(key: key);

  @override
  State<CathedralLivePlayer> createState() => _CathedralLivePlayerState();
}

class _CathedralLivePlayerState extends State<CathedralLivePlayer> {
  YoutubePlayerController? _youtubeController;
  bool _isInternalLoading = false;
  String? _internalVideoError;
  late bool isLiveOverride;

  Key _playerWidgetKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    CathedralLivePlayer.globalPlayingIndex = 0;
    CathedralLivePlayer.playerStateTrigger = (targetIndex) {
      if (!mounted) return;
      _bootVideoEngine(widget.playlist[targetIndex]['streamUrl'], targetIndex);
    };

    if (widget.playlist.isNotEmpty) {
      _bootVideoEngine(widget.playlist[0]['streamUrl'], 0);
    }
  }

  @override
  void didUpdateWidget(covariant CathedralLivePlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.playlist.isEmpty && widget.playlist.isNotEmpty && _youtubeController == null) {
      _bootVideoEngine(widget.playlist[0]['streamUrl'], 0);
    }
  }

  String? _parseVideoId(String url) {
    if (url.length == 11) return url;
    final RegExp regExp = RegExp(
      r'^.*(?:(?:youtu\.be\/|v\/|vi\/|u\/\w\/|embed\/|shorts\/|live\/)|(?:(?:watch)?\?v(?:i)?=|\&v(?:i)?=))([^#\&\?]*).*',
      caseSensitive: false,
    );
    final Match? match = regExp.firstMatch(url);
    if (match != null && match.groupCount >= 1) {
      return match.group(1);
    }
    return null;
  }

  void _bootVideoEngine(String url, int targetIndex) {
    if (!mounted) return;

    setState(() {
      _isInternalLoading = true;
      _internalVideoError = null;
      CathedralLivePlayer.globalPlayingIndex = targetIndex;
      _playerWidgetKey = UniqueKey();
    });

    _youtubeController = null;

    final String? extractedId = _parseVideoId(url.trim());

    if (extractedId == null || extractedId.isEmpty) {
      setState(() {
        _isInternalLoading = false;
        _internalVideoError = "Invalid YouTube link structure.";
      });
      return;
    }

    try {
      _youtubeController = YoutubePlayerController.fromVideoId(
        videoId: extractedId,
        autoPlay: true,
        params: const YoutubePlayerParams(
          origin: 'https://www.youtube-nocookie.com',
          showControls: true,
          showFullscreenButton: true,
          mute: false,
          playsInline: true,
        ),
      );

      _youtubeController!.stream.listen((YoutubePlayerValue playerValue) {
        if (!mounted) return;
        if (playerValue.playerState == PlayerState.buffering) {
          _youtubeController!.playVideo();
        }
      });

      setState(() {
        _isInternalLoading = false;
      });

      WakelockPlus.enable();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _youtubeController = null;
        _isInternalLoading = false;
        _internalVideoError = "Video engine synchronization failed.";
      });
    }
  }

  @override
  void dispose() {
    try {
      WakelockPlus.disable();
    } catch(e) {
      print("error handled and bypassed $e");
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bool currentLoadingState = widget.isLoading || _isInternalLoading;
    final String? clearErrors = _internalVideoError ?? widget.errorMessage;

    final Map<String, dynamic> currentVideo = widget.playlist.isNotEmpty &&
        CathedralLivePlayer.globalPlayingIndex < widget.playlist.length
        ? widget.playlist[CathedralLivePlayer.globalPlayingIndex]
        : {};

    final String title = currentVideo['title'] ?? "Cathedral Services";
    final bool activeLiveTag = widget.isLiveOverride;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4), width: 1),
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
                else if (clearErrors != null && _youtubeController == null)
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
                else if (_youtubeController != null)
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
                        child: Container(
                          color: Colors.black,
                          child: YoutubePlayerControllerProvider(
                            key: _playerWidgetKey,
                            controller: _youtubeController!,
                            child: YoutubePlayer(
                              controller: _youtubeController!,
                            ),
                          ),
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
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? const Color(0xFFEEEEEE) : Colors.black87, height: 1.3),
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
                      activeLiveTag ? 'Live' : 'Recorded',
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