// File: main_ui/lib/screens/auth/splash_screen2.dart
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter/material.dart';
import 'dart:io' show Platform;

class Niwaran extends StatefulWidget {
  final double? width;
  final double? height;

  const Niwaran({
    super.key,
    this.width,
    this.height,
  });

  @override
  NiwaranState createState() => NiwaranState();
}

class NiwaranState extends State<Niwaran> {
  final _key = UniqueKey();
  late final WebViewController _svgatorController;

  @override
  void initState() {
    super.initState();
    // Initialize WebViewController
    _svgatorController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..loadRequest(Uri.parse('about:blank'));

    // Load HTML after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadHtmlFromAssets(_svgatorController);
    });
  }

  Future<void> _loadHtmlFromAssets(WebViewController controller) async {
    try {
      // SVG content (replace with full SVG if truncated)
      String svgContent = '''
<svg id="eI13lcKwgeY1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="0 0 300 300" shape-rendering="geometricPrecision" text-rendering="geometricPrecision" project-id="72b0ba56ca7d43f3b12d798b2f76873c" export-id="0bf18e892d9d478eb3ec06150c7b0d78" cached="false">
  <defs>
    <image id="eI13lcKwgeY2" width="91" height="91" xlink:href="data:image/png;base64,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"/>
    <image id="eI13lcKwgeY7" width="204" height="38" xlink:href="data:image/png;base64,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
      </svg>
      ''';

      // Placeholder for the SVGator player JavaScript (replace with actual player code)
      String playerJs = '''
      // Replace with actual SVGator player JavaScript from _PLAYERS["91c80d77"]
      // Example placeholder (simplified):
      (function() {
        window.__SVGATOR_PLAYER__ = window.__SVGATOR_PLAYER__ || {};
        window.__SVGATOR_PLAYER__["91c80d77"] = {
          play: function() { console.log("Playing SVG animation"); },
          // Add actual animation logic here
        };
      })();
      ''';

      // Combine SVG and JavaScript
      String bodyContent = '$svgContent<script type="text/javascript">${shortenCode(playerJs)}</script>';

      // Wrap in HTML
      String html = wrapPage(bodyContent);

      // Load the HTML string into WebView
      await controller.loadHtmlString(html);
    } catch (e) {
      debugPrint('Error loading SVG animation: $e');
      // Fallback to a static image or placeholder if animation fails
      if (mounted) {
        setState(() {
          // Optionally trigger a rebuild or show a fallback UI
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: WebViewWidget(
        key: _key,
        controller: _svgatorController,
      ),
    );
  }

  static String shortenCode(String str) {
    return str
        .replaceAll(RegExp(r'\s{2,}'), '')
        .replaceAllMapped(
          RegExp(r'[\n\r\t\s]*([,{}=;:()?|&])[\n\r\t\s]*'),
          (Match m) => m[1]!,
        )
        .replaceAll(RegExp(r';}'), '}');
  }

  static String wrapPage(String svg) {
    const String header = '''<!doctype html>
<html>
  <head>
    <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">
    <style>
      html, body {
        height: 100%;
        overflow: hidden;
        width: 100%;
      }
      body {
        margin: 0;
        padding: 0;
        background: transparent;
      }
      svg {
        height: 100%;
        left: 0;
        position: fixed;
        top: 0;
        width: 100%;
      }
    </style>
  </head>
  <body>
''';
    const String footer = '''
  </body>
</html>''';
    return shortenCode(header) + svg + shortenCode(footer);
  }
}