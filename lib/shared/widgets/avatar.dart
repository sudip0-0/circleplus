import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class Avatar extends StatelessWidget {
  const Avatar({
    required this.displayName,
    this.photoUrl,
    this.radius = 20,
    super.key,
  });

  final String displayName;
  final String? photoUrl;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final imageUrl = photoUrl;
    if (imageUrl == null || imageUrl.isEmpty) {
      return CircleAvatar(
        radius: radius,
        child: Text(_initial(displayName)),
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.transparent,
      child: ClipOval(
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          placeholder: (context, url) => SizedBox(
            width: radius * 2,
            height: radius * 2,
            child: const Center(
              child: SizedBox.square(
                dimension: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
          errorWidget: (context, url, error) =>
              CircleAvatar(radius: radius, child: Text(_initial(displayName))),
        ),
      ),
    );
  }

  String _initial(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return '?';
    }
    return trimmed.characters.first.toUpperCase();
  }
}
