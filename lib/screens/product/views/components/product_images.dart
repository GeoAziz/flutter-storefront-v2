import 'package:flutter/material.dart';
import '/components/lazy_image_widget.dart';

import '../../../../constants.dart';

class ProductImages extends StatefulWidget {
  const ProductImages({
    super.key,
    required this.images,
  });

  final List<String> images;

  @override
  State<ProductImages> createState() => _ProductImagesState();
}

class _ProductImagesState extends State<ProductImages> {
  late PageController _controller;

  int _currentPage = 0;

  @override
  void initState() {
    _controller =
        PageController(viewportFraction: 0.9, initialPage: _currentPage);
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.images.where((s) => s.isNotEmpty).toList();

    return SliverToBoxAdapter(
      child: AspectRatio(
        aspectRatio: 1,
        child: Stack(
          children: [
            if (images.isEmpty)
              // Placeholder when no images available
              Container(
                color: Theme.of(context).canvasColor,
                child: const Center(child: Icon(Icons.image, size: 48)),
              )
            else
              PageView.builder(
                controller: _controller,
                onPageChanged: (pageNum) {
                  setState(() {
                    _currentPage = pageNum;
                  });
                },
                itemCount: images.length,
                itemBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.only(right: defaultPadding),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.all(
                      Radius.circular(defaultBorderRadious * 2),
                    ),
                    child: LazyImageWidget(images[index]),
                  ),
                ),
              ),

            if (images.length > 1)
              Positioned(
                height: 20,
                bottom: 24,
                right: MediaQuery.of(context).size.width * 0.15,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: defaultPadding * 0.75,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: const BorderRadius.all(Radius.circular(50)),
                  ),
                  child: Row(
                    children: List.generate(
                      images.length,
                      (index) => Padding(
                        padding: EdgeInsets.only(
                            right: index == (images.length - 1)
                                ? 0
                                : defaultPadding / 4),
                        child: CircleAvatar(
                          radius: 3,
                          backgroundColor: Theme.of(context)
                              .textTheme
                              .bodyLarge!
                              .color!
                              .withOpacity(index == _currentPage ? 1 : 0.2),
                        ),
                      ),
                    ),
                  ),
                ),
              )
          ],
        ),
      ),
    );
  }
}
