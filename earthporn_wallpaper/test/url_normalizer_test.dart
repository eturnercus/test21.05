import 'package:flutter_test/flutter_test.dart';

import 'package:earthporn_wallpaper/src/models/wallpaper_orientation.dart';
import 'package:earthporn_wallpaper/src/services/feed_client.dart';
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

  group('redditImageDownloadCandidates', () {
    test('includes normalized and original URL when they differ', () {
      const raw =
          'https://preview.redd.it/z.jpg?auto=webp&s=x';
      final c = redditImageDownloadCandidates(raw);
      expect(c.length, 2);
      expect(c[0], 'https://i.redd.it/z.jpg');
      expect(c[1], raw);
    });
  });

  group('titleOrientationMatches', () {
    test('respects [WxH] in title', () {
      expect(
        titleOrientationMatches('Lake [8000x4000]', WallpaperOrientation.landscape),
        isTrue,
      );
      expect(
        titleOrientationMatches('Tall [4000x8000]', WallpaperOrientation.landscape),
        isFalse,
      );
      expect(
        titleOrientationMatches('Tall [4000x8000]', WallpaperOrientation.portrait),
        isTrue,
      );
      expect(
        titleOrientationMatches('No dims', WallpaperOrientation.landscape),
        isTrue,
      );
    });
  });

  group('redditPixelAreaEstimate', () {
    test('reads width/height from preview URL query', () {
      expect(
        redditPixelAreaEstimate(
          'https://preview.redd.it/x.jpg?width=3200&height=1800',
        ),
        3200 * 1800,
      );
    });
  });

  group('FeedClient.browseUriFromRss', () {
    test('strips .rss path suffix', () {
      final u = FeedClient.browseUriFromRss(
        'https://www.reddit.com/r/EarthPorn/.rss',
      );
      expect(u.toString(), 'https://www.reddit.com/r/EarthPorn/');
    });
  });
}
