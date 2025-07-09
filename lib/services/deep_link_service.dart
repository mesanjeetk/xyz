import 'dart:async';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:app_links/app_links.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/route_constants.dart';

class DeepLinkService {
  static final DeepLinkService _instance = DeepLinkService._internal();
  static DeepLinkService get instance => _instance;

  DeepLinkService._internal();

  late AppLinks _appLinks;
  StreamSubscription? _linkSubscription;
  GoRouter? _router;
  Function(String)? _onLinkReceived;

  Future<void> initialize({GoRouter? router}) async {
    _router = router;
    _appLinks = AppLinks();
    
    // Listen for incoming links when app is already running
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (Uri uri) {
        _handleIncomingLink(uri.toString());
      },
      onError: (err) {
        print('Deep link error: $err');
      },
    );

    // Get the initial link if app was launched from a deep link
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _handleIncomingLink(initialUri.toString());
      }
    } on PlatformException catch (e) {
      print('Failed to get initial link: ${e.message}');
    }
  }

  void _handleIncomingLink(String link) {
    print('Received deep link: $link');
    
    // Parse the link and extract parameters
    final uri = Uri.parse(link);
    final scheme = uri.scheme;
    final host = uri.host;
    final path = uri.path;
    final queryParams = uri.queryParameters;

    print('Scheme: $scheme, Host: $host, Path: $path, Query: $queryParams');

    // Handle different link patterns
    if (scheme == 'flutterlearning' || (scheme == 'https' && host == 'flutterlearning.app')) {
      _processDeepLink(uri);
    }

    // Notify listeners
    if (_onLinkReceived != null) {
      _onLinkReceived!(link);
    }
  }

  void _processDeepLink(Uri uri) {
    if (_router == null) {
      print('Router not initialized');
      return;
    }

    // Handle different deep link patterns
    switch (uri.path) {
      case '/home':
        _router!.go(RouteConstants.main);
        break;
      case '/files':
        _router!.go('${RouteConstants.main}/files');
        break;
      case '/profile':
        _router!.go('${RouteConstants.main}/profile');
        break;
      case '/explore':
        _router!.go('${RouteConstants.main}/explore');
        break;
      case '/pdf':
        final filePath = uri.queryParameters['file'];
        if (filePath != null) {
          _router!.push('${RouteConstants.pdfViewer}?filePath=$filePath');
        }
        break;
      default:
        print('Unknown deep link path: ${uri.path}');
        _router!.go(RouteConstants.main);
    }
  }

  Future<void> openExternalLink(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      print('Could not launch $url');
    }
  }

  void setLinkHandler(Function(String) handler) {
    _onLinkReceived = handler;
  }

  void dispose() {
    _linkSubscription?.cancel();
  }
}