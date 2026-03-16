import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

class ExactFrontendWebViewScreen extends StatefulWidget {
  const ExactFrontendWebViewScreen({
    super.key,
    required this.frontendUrl,
  });

  final String frontendUrl;

  @override
  State<ExactFrontendWebViewScreen> createState() =>
      _ExactFrontendWebViewScreenState();
}

class _ExactFrontendWebViewScreenState extends State<ExactFrontendWebViewScreen> {
  WebViewController? _controller;
  HttpServer? _assetServer;
  String? _inAppAssetUrl;
  bool _loading = true;
  String? _error;
  String? _backendWarning;

  String _contentTypeForPath(String path) {
    final p = path.toLowerCase();
    if (p.endsWith('.html')) return 'text/html; charset=utf-8';
    if (p.endsWith('.js')) return 'application/javascript; charset=utf-8';
    if (p.endsWith('.css')) return 'text/css; charset=utf-8';
    if (p.endsWith('.json')) return 'application/json; charset=utf-8';
    if (p.endsWith('.svg')) return 'image/svg+xml';
    if (p.endsWith('.png')) return 'image/png';
    if (p.endsWith('.jpg') || p.endsWith('.jpeg')) return 'image/jpeg';
    if (p.endsWith('.webp')) return 'image/webp';
    if (p.endsWith('.ico')) return 'image/x-icon';
    if (p.endsWith('.woff2')) return 'font/woff2';
    if (p.endsWith('.woff')) return 'font/woff';
    if (p.endsWith('.ttf')) return 'font/ttf';
    if (p.endsWith('.txt')) return 'text/plain; charset=utf-8';
    return 'application/octet-stream';
  }

  Future<Uint8List?> _readAssetBytes(String path) async {
    final normalized = path.startsWith('/') ? path.substring(1) : path;
    final strippedAssetsPrefix = normalized.startsWith('assets/')
        ? normalized.substring('assets/'.length)
        : normalized;

    final candidates = <String>{
      'assets/exact_frontend/$normalized',
      'assets/exact_frontend/$strippedAssetsPrefix',
      normalized,
    };

    for (final assetKey in candidates) {
      try {
        final data = await rootBundle.load(assetKey);
        return data.buffer.asUint8List();
      } catch (_) {
        // Try the next candidate key.
      }
    }

    debugPrint('Exact frontend asset missing for path: $path');
    return null;
  }

  Future<String?> _startBundledAssetServer() async {
    try {
      final indexBytes = await _readAssetBytes('/index.html');
      if (indexBytes == null) {
        return null;
      }

      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      _assetServer = server;

      server.listen((HttpRequest request) async {
        try {
          var path = request.uri.path;
          if (path == '/' || path.isEmpty) {
            path = '/index.html';
          }

          var bytes = await _readAssetBytes(path);

          // SPA fallback only for route-like paths (no file extension).
          // Do not fallback for missing static assets like .js/.css files.
          final isLikelyRoute = !path.split('/').last.contains('.');
          if (bytes == null && isLikelyRoute) {
            bytes = await _readAssetBytes('index.html');
            path = '/index.html';
          }

          if (bytes == null) {
            request.response.statusCode = HttpStatus.notFound;
            await request.response.close();
            return;
          }

          request.response.headers.set('Access-Control-Allow-Origin', '*');
          request.response.headers.set('Content-Type', _contentTypeForPath(path));
          request.response.add(bytes);
          await request.response.close();
        } catch (_) {
          request.response.statusCode = HttpStatus.internalServerError;
          await request.response.close();
        }
      });

      return 'http://127.0.0.1:${server.port}/';
    } catch (_) {
      return null;
    }
  }

  void _checkBackendAvailability() {
    final supabaseUrl = dotenv.env['SUPABASE_URL'];
    final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];

    final isMissing =
        (supabaseUrl == null || supabaseUrl.isEmpty) ||
        (supabaseAnonKey == null || supabaseAnonKey.isEmpty);

    if (!mounted) return;
    setState(() {
      _backendWarning = isMissing
          ? 'Backend config is missing. Some options may not work until SUPABASE_URL and SUPABASE_ANON_KEY are set.'
          : null;
    });
  }

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _loading = false;
      return;
    }

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (!mounted) return;
            setState(() {
              _loading = true;
              _error = null;
            });
          },
          onPageFinished: (_) {
            if (!mounted) return;
            setState(() => _loading = false);
          },
          onWebResourceError: (err) {
            if (!mounted) return;
            setState(() {
              _loading = false;
              _error = err.description;
            });
          },
        ),
      );

    _startBundledAssetServer().then((assetUrl) {
      if (!mounted) return;
      _inAppAssetUrl = assetUrl;

      if (assetUrl == null) {
        setState(() {
          _loading = false;
          _error = 'In-app bundled frontend server failed to start.';
        });
        return;
      }

      _controller!.loadRequest(Uri.parse(assetUrl));
    });

    _checkBackendAvailability();
  }

  Future<void> _openExternal() async {
    final target = _inAppAssetUrl;
    if (target == null) return;
    final uri = Uri.parse(target);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  void dispose() {
    _assetServer?.close(force: true);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return Scaffold(
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.open_in_browser, size: 56),
                  const SizedBox(height: 12),
                  const Text(
                    'Exact frontend mode uses WebView on app platforms.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This exact mode is app-only. Open on Android/iOS/macOS to render the bundled frontend.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 8),
                  const SelectableText('Bundled in-app frontend (no online fallback).'),
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    onPressed: _inAppAssetUrl == null ? null : _openExternal,
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Open In-App Bundle URL'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 8,
              ),
              child: _controller == null
                  ? const SizedBox.shrink()
                  : WebViewWidget(controller: _controller!),
            ),
          ),
          if (_backendWarning != null)
            Positioned(
              left: 16,
              right: 16,
              top: MediaQuery.of(context).padding.top + 16,
              child: Card(
                color: const Color(0xFFFFF3E0),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Text(
                    _backendWarning!,
                    style: const TextStyle(color: Color(0xFF8A5300)),
                  ),
                ),
              ),
            ),
          if (_loading)
            const Positioned.fill(
              child: ColoredBox(
                color: Color(0xAAFFFFFF),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
          if (_error != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Card(
                color: const Color(0xFFFFEBEE),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    'Failed to load bundled in-app frontend\n$_error',
                    style: const TextStyle(color: Color(0xFFB71C1C)),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
