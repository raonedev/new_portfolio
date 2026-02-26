import 'dart:ui_web' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:web/web.dart' as web; // The new package

class SearchEngineScreen extends StatelessWidget {
  const SearchEngineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Only register the factory if we are actually on Web
    if (kIsWeb) {
      // ignore: undefined_prefixed_name
      ui.platformViewRegistry.registerViewFactory('iframe-search', (
        int viewId,
      ) {
        // Use package:web to create the element
        final web.HTMLIFrameElement iframe =
            web.document.createElement('iframe') as web.HTMLIFrameElement;

        iframe.src = 'https://www.wikipedia.org';
        iframe.style.border = 'none';
        iframe.style.width = '100%';
        iframe.style.height = '100%';

        return iframe;
      });
    }

    return Scaffold(
      body: kIsWeb
          ? const HtmlElementView(viewType: 'iframe-search')
          : const Center(child: Text("IFrame is only supported on Web")),
    );
  }
}
