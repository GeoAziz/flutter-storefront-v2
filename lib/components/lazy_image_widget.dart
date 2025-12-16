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
/// The visibility threshold (5% by default) determines when an image starts loading:
/// - 5% (aggressive): Image loads as soon as it enters viewport
/// - 10% (balanced): Better memory efficiency with slight delay
/// - 25% (conservative): Maximum memory savings, images load deeper into viewport
///
/// Best used in scrollable lists (ListView, GridView) for optimal performance.
class LazyImageWidget extends StatefulWidget {
  final String imageUrl;
  final BoxFit fit;
  final double radius;
  final Duration fadeInDuration;
  final double visibilityThreshold;

  const LazyImageWidget(
    this.imageUrl, {
    super.key,
    this.fit = BoxFit.cover,
    this.radius = defaultPadding,
    this.fadeInDuration = const Duration(milliseconds: 300),
    this.visibilityThreshold = 0.05, // 5% visible threshold (aggressive loading)
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
        // Use the configured visibility threshold (default 5% for aggressive loading)
        if (!_isVisible && info.visibleFraction > widget.visibilityThreshold) {
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
