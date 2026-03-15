import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  late String _resolvedFrontendUrl;

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
    final assetKey = 'assets/exact_frontend/$normalized';
    try {
      final data = await rootBundle.load(assetKey);
      return data.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }

  Future<String?> _startBundledAssetServer() async {
    try {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      _assetServer = server;

      server.listen((HttpRequest request) async {
        try {
          var path = request.uri.path;
          if (path == '/' || path.isEmpty) {
            path = '/index.html';
          }

          var bytes = await _readAssetBytes(path);

          // SPA fallback: unknown routes serve index.html.
          bytes ??= await _readAssetBytes('index.html');

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

      return 'http://127.0.0.1:${server.port}/index.html';
    } catch (_) {
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    _resolvedFrontendUrl = widget.frontendUrl;

    if (kIsWeb) {
      _loading = false;
      return;
    }

    final raw = widget.frontendUrl;
    final uri = Uri.tryParse(raw);
    final isLocalhost = uri != null && (uri.host == 'localhost' || uri.host == '127.0.0.1');
    final platform = defaultTargetPlatform;
    if (isLocalhost && platform == TargetPlatform.android) {
      _resolvedFrontendUrl = uri.replace(host: '10.0.2.2').toString();
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
      _inAppAssetUrl = assetUrl;
      final target = assetUrl ?? _resolvedFrontendUrl;
      _controller!.loadRequest(Uri.parse(target));
    });
  }

  Future<void> _openExternal() async {
    final uri = Uri.parse(_inAppAssetUrl ?? _resolvedFrontendUrl);
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
        appBar: AppBar(title: const Text('Dravik Exact Frontend')),
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
                    'Open the same frontend URL directly in this browser target:',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 8),
                  SelectableText(widget.frontendUrl),
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    onPressed: _openExternal,
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Open Frontend URL'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dravik Exact Frontend'),
        actions: [
          IconButton(
            tooltip: 'Reload',
            onPressed: () => _controller?.reload(),
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Open in browser',
            onPressed: _openExternal,
            icon: const Icon(Icons.open_in_new),
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: _controller == null
                ? const SizedBox.shrink()
                : WebViewWidget(controller: _controller!),
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
                    'Failed to load in-app bundled frontend and fallback URL ${widget.frontendUrl}\n$_error',
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
