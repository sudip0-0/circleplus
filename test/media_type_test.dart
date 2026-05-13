import 'package:circleplus/core/utils/media_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fileExtensionForName normalizes image file extensions', () {
    expect(fileExtensionForName('avatar.PNG'), 'png');
    expect(fileExtensionForName('pulse.final.webp'), 'webp');
    expect(fileExtensionForName('no-extension'), 'jpg');
    expect(fileExtensionForName(null), 'jpg');
  });

  test('imageContentTypeForName maps supported image types', () {
    expect(imageContentTypeForName('avatar.png'), 'image/png');
    expect(imageContentTypeForName('pulse.webp'), 'image/webp');
    expect(imageContentTypeForName('reaction.gif'), 'image/gif');
    expect(imageContentTypeForName('camera.jpeg'), 'image/jpeg');
  });
}
