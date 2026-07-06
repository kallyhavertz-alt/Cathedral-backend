import 'dart:async';
import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart';
import 'package:untitled/event_details_screen.dart';
import 'package:untitled/posts_tab.dart';
import 'package:share_plus/share_plus.dart';

class DeepLinkService {
  static final DeepLinkService _instance = DeepLinkService._internal();
  factory DeepLinkService() => _instance;
  DeepLinkService._internal();

  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;

  // 🌍 BASE REDIRECT URL
  static const String _baseShareUrl = "https://ackstjamescathedral.org";
  static const String _playStoreUrl = "https://play.google.com/store/apps/details?id=com.ack.stjames.cathedral";

  void initDeepLinks(BuildContext context) async {
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _handleIncomingUri(initialUri, context);
      }
    } catch (e) {
      debugPrint("🚨 Error handling initial deep link: $e");
    }

    _linkSubscription = _appLinks.uriLinkStream.listen(
          (uri) {
        _handleIncomingUri(uri, context);
      },
      onError: (err) {
        debugPrint("🚨 Deep link stream error: $err");
      },
    );
  }

  void _handleIncomingUri(Uri uri, BuildContext context) {
    debugPrint("Intercepted incoming Deep Link: $uri");

     if (uri.pathSegments.contains('posts')) {
      final int postsIndex = uri.pathSegments.indexOf('posts');
      if (postsIndex != -1 && postsIndex + 1 < uri.pathSegments.length) {
        final String postIdStr = uri.pathSegments[postsIndex + 1];
        final int? postId = int.tryParse(postIdStr);
        if (postId != null) {
          _navigateToTargetPost(context, postId);
        }
      }
    } else if (uri.pathSegments.contains('services')) {
      final int servicesIndex = uri.pathSegments.indexOf('services');
      if (servicesIndex != -1 && servicesIndex + 1 < uri.pathSegments.length) {
        final String serviceIdStr = uri.pathSegments[servicesIndex + 1];
        final int? serviceId = int.tryParse(serviceIdStr);
        if (serviceId != null) {
           _navigateToTargetService(context, serviceId);
        }
      }
    }
  }

  void _navigateToTargetPost(BuildContext context, int postId) {
    debugPrint("Routing user directly to Post ID: $postId");
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PostsTab(
           initialFeed: [], onLikeToggle: (int postId) {  }, onAddComment: (int postId, String commentContent) {  }, onRefresh: () async {  },
        ),
      ),
    );
  }

  void _navigateToTargetService(BuildContext context, int serviceId) {
    debugPrint("Routing user directly to Service ID: $serviceId");
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EventDetailsScreen(
          eventData: {'id': serviceId, 'postType': 'SUNDAY_SERVICE'},
        ),
      ),
    );
  }

  /// 🚀 GENERATE AND SHARE A DIRECT DEEP LINK
  /// Used if you decide to use domain-based links again.
  static Future<void> shareContent({
    required String type,
    required String id,
    required String title,
    String? description,
  }) async {
    final String deepLink = "$_baseShareUrl/$type/$id";
    
    final String shareMessage = """
🕊️ ACK St. James Cathedral
*${title.toUpperCase()}*
${description ?? ''}

Open in App:
$deepLink

Don't have the app? Download it from Play Store:
$_playStoreUrl
""";

    await Share.share(shareMessage, subject: title);
  }

  void dispose() {
    _linkSubscription?.cancel();
  }
}
