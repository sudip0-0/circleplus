String fileExtensionForName(String? fileName) {
  if (fileName == null || fileName.trim().isEmpty) {
    return 'jpg';
  }
  final pieces = fileName.split('.');
  if (pieces.length < 2 || pieces.last.isEmpty) {
    return 'jpg';
  }
  return pieces.last.toLowerCase();
}

String imageContentTypeForName(String? fileName) {
  return switch (fileExtensionForName(fileName)) {
    'png' => 'image/png',
    'webp' => 'image/webp',
    'gif' => 'image/gif',
    _ => 'image/jpeg',
  };
}
