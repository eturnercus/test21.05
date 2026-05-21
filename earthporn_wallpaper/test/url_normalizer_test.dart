import 'package:flutter_test/flutter_test.dart';

import 'package:earthporn_wallpaper/src/services/url_normalizer.dart';

void main() {
  group('normalizeRedditImageUrl', () {
    test('external-preview.redd.it maps to i.redd.it (not broken external-i)', () {
      const input =
          'https://external-preview.redd.it/abc123.jpeg?auto=webp&s=deadbeef';
      final out = normalizeRedditImageUrl(input);
      expect(out, 'https://i.redd.it/abc123.jpeg');
      expect(out, isNot(contains('external-i')));
    });

    test('external-i.redd.it maps to i.redd.it', () {
      const input = 'https://external-i.redd.it/abc123.jpeg';
      expect(normalizeRedditImageUrl(input), 'https://i.redd.it/abc123.jpeg');
    });

    test('preview.redd.it maps to i.redd.it', () {
      const input = 'https://preview.redd.it/foo.jpg?width=3200';
      expect(normalizeRedditImageUrl(input), 'https://i.redd.it/foo.jpg');
    });
  });
}
