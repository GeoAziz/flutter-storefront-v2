import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../constants.dart';
import 'skleton/skelton.dart';
import '../utils/image_cache_manager.dart';

/// A lazy-loading image widget that only loads images when they become visible.
///
/// Uses VisibilityDetector to delay network requests for off-screen images,
/// reducing memory pressure during fast scrolling. Images fade in as they load.
/// 
/// Best used in scrollable lists (ListView, GridView) for optimal performance.
class LazyImageWidget extends StatefulWidget {
  final String imageUrl;
  final BoxFit fit;
  final double radius;
  final Duration fadeInDuration;

  const LazyImageWidget(
    this.imageUrl, {
    super.key,
    this.fit = BoxFit.cover,
    this.radius = defaultPadding,
    this.fadeInDuration = const Duration(milliseconds: 300),
  });

  @override
  State<LazyImageWidget> createState() => _LazyImageWidgetState();
}

class _LazyImageWidgetState extends State<LazyImageWidget> {
  bool _isVisible = false;
  late String _visibilityKey;

  @override
  void initState() {
    super.initState();
    // Create unique key for visibility detection
    _visibilityKey = 'lazy_image_${widget.imageUrl.hashCode}';
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: ValueKey(_visibilityKey),
      onVisibilityChanged: (info) {
        // Only set visible once; don't unload when scrolled off
        // to avoid flickering and re-downloading
        if (!_isVisible && info.visibleFraction > 0.1) {
          setState(() {
            _isVisible = true;
          });
        }
      },
      child: ClipRRect(
        borderRadius: BorderRadius.all(Radius.circular(widget.radius)),
        child: _isVisible
            ? CachedNetworkImage(
                cacheManager: appImageCacheManager,
                fit: widget.fit,
                imageUrl: widget.imageUrl,
                fadeInDuration: widget.fadeInDuration,
                placeholder: (context, url) => const Skeleton(),
                errorWidget: (context, url, error) => const Icon(Icons.error),
              )
            : const Skeleton(), // Show placeholder until visible
      ),
    );
  }
}
