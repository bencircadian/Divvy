// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// Web implementation to reload the page.
void reloadPage() {
  html.window.location.reload();
}
