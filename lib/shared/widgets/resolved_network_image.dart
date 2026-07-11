import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';

/// Loads a network image from either a legacy https URL or an R2 object key
/// resolved through the upload Worker download signer.
class ResolvedNetworkImage extends ConsumerStatefulWidget {
  const ResolvedNetworkImage({
    required this.storageRef,
    this.circleId,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.semanticLabel,
    this.placeholder,
    this.errorWidget,
    super.key,
  });

  final String storageRef;
  final String? circleId;
  final BoxFit fit;
  final double? width;
  final double? height;
  final String? semanticLabel;
  final Widget Function(BuildContext context)? placeholder;
  final Widget Function(BuildContext context)? errorWidget;

  @override
  ConsumerState<ResolvedNetworkImage> createState() =>
      _ResolvedNetworkImageState();
}

class _ResolvedNetworkImageState extends ConsumerState<ResolvedNetworkImage> {
  late Future<String> _urlFuture;

  @override
  void initState() {
    super.initState();
    _urlFuture = _resolve();
  }

  @override
  void didUpdateWidget(covariant ResolvedNetworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.storageRef != widget.storageRef ||
        oldWidget.circleId != widget.circleId) {
      _urlFuture = _resolve();
    }
  }

  Future<String> _resolve() {
    return ref.read(storageServiceProvider).resolveDownloadUrl(
      objectKey: widget.storageRef,
      circleId: widget.circleId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _urlFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return widget.errorWidget?.call(context) ??
              const Center(child: Icon(Icons.broken_image_outlined));
        }
        final url = snapshot.data;
        if (url == null) {
          return widget.placeholder?.call(context) ??
              const Center(child: CircularProgressIndicator());
        }

        final image = CachedNetworkImage(
          imageUrl: url,
          fit: widget.fit,
          width: widget.width,
          height: widget.height,
          placeholder: (context, _) =>
              widget.placeholder?.call(context) ??
              const Center(child: CircularProgressIndicator()),
          errorWidget: (context, url, error) =>
              widget.errorWidget?.call(context) ??
              const Center(child: Icon(Icons.broken_image_outlined)),
        );

        final label = widget.semanticLabel;
        if (label == null) {
          return image;
        }
        return Semantics(image: true, label: label, child: image);
      },
    );
  }
}
