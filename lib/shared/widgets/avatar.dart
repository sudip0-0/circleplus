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
    return CircleAvatar(
      radius: radius,
      backgroundImage: imageUrl == null || imageUrl.isEmpty
          ? null
          : NetworkImage(imageUrl),
      child: imageUrl == null || imageUrl.isEmpty
          ? Text(_initial(displayName))
          : null,
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
