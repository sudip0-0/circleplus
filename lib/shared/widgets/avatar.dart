import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'resolved_network_image.dart';

class Avatar extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
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
        child: ResolvedNetworkImage(
          storageRef: imageUrl,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          semanticLabel: '$displayName avatar',
          placeholder: (_) => SizedBox(
            width: radius * 2,
            height: radius * 2,
            child: const Center(
              child: SizedBox.square(
                dimension: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
          errorWidget: (_) =>
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
