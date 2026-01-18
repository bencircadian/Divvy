import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:web/web.dart' as web;

/// Web implementation that creates an HTML img element
/// positioned absolutely over the Flutter widget.
Widget buildWebImage({
  required String url,
  required double size,
  required Widget fallback,
  Key? key,
}) {
  return _WebImage(
    key: key,
    url: url,
    size: size,
    fallback: fallback,
  );
}

/// Web-specific image widget that overlays an HTML img element.
/// Creates an absolutely positioned img element in the DOM and
/// positions it over this widget using a Ticker for continuous updates.
class _WebImage extends StatefulWidget {
  final String url;
  final double size;
  final Widget fallback;

  const _WebImage({
    super.key,
    required this.url,
    required this.size,
    required this.fallback,
  });

  @override
  State<_WebImage> createState() => _WebImageState();
}

class _WebImageState extends State<_WebImage>
    with SingleTickerProviderStateMixin {
  final GlobalKey _containerKey = GlobalKey();
  web.HTMLImageElement? _imgElement;
  bool _imageLoaded = false;
  bool _imageError = false;
  Ticker? _ticker;
  Offset? _lastPosition;

  @override
  void initState() {
    super.initState();
    _createAndPositionImage();
  }

  @override
  void dispose() {
    _ticker?.dispose();
    _removeImage();
    super.dispose();
  }

  @override
  void didUpdateWidget(_WebImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url || oldWidget.size != widget.size) {
      _removeImage();
      setState(() {
        _imageLoaded = false;
        _imageError = false;
      });
      _createAndPositionImage();
    }
  }

  void _createAndPositionImage() {
    _imgElement = web.HTMLImageElement()
      ..src = widget.url
      ..style.position = 'fixed'
      ..style.width = '${widget.size}px'
      ..style.height = '${widget.size}px'
      ..style.objectFit = 'cover'
      ..style.borderRadius = '50%'
      ..style.pointerEvents = 'none'
      ..style.zIndex = '1000'
      ..style.opacity = '0'
      ..style.transition = 'none'; // No transitions for smooth tracking

    _imgElement!.onLoad.listen((_) {
      if (mounted) {
        setState(() => _imageLoaded = true);
        _updatePosition();
        _imgElement?.style.opacity = '1';
        _startTicker();
      }
    });

    _imgElement!.onError.listen((_) {
      if (mounted) {
        setState(() => _imageError = true);
        _removeImage();
      }
    });

    web.document.body?.append(_imgElement!);

    // Position after the frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updatePosition();
    });
  }

  void _startTicker() {
    _ticker?.dispose();
    _ticker = createTicker((_) => _updatePosition());
    _ticker!.start();
  }

  void _updatePosition() {
    if (_imgElement == null || !mounted) return;

    final renderBox =
        _containerKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.attached) {
      // Widget not visible, hide the image
      _imgElement?.style.opacity = '0';
      return;
    }

    final position = renderBox.localToGlobal(Offset.zero);

    // Only update DOM if position changed (optimization)
    if (_lastPosition != position) {
      _lastPosition = position;
      _imgElement!.style.left = '${position.dx}px';
      _imgElement!.style.top = '${position.dy}px';
      if (_imageLoaded) {
        _imgElement!.style.opacity = '1';
      }
    }
  }

  void _removeImage() {
    _ticker?.dispose();
    _ticker = null;
    _imgElement?.remove();
    _imgElement = null;
    _lastPosition = null;
  }

  @override
  Widget build(BuildContext context) {
    // Always render the fallback as a placeholder for sizing
    // The HTML img is positioned absolutely on top when loaded
    return SizedBox(
      key: _containerKey,
      width: widget.size,
      height: widget.size,
      child: _imageLoaded && !_imageError
          ? const SizedBox.shrink() // Empty when image is showing
          : widget.fallback,
    );
  }
}
