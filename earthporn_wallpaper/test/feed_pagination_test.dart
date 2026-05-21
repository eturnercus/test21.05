import 'package:flutter_test/flutter_test.dart';

import 'package:earthporn_wallpaper/src/services/feed_client.dart';

void main() {
  test('parseNextFeedUrl reads Atom rel=next', () {
    const xml = '''
<?xml version="1.0" encoding="UTF-8"?>
<feed xmlns="http://www.w3.org/2005/Atom">
  <link rel="next" href="https://www.reddit.com/r/EarthPorn/.rss?count=25&amp;after=t3_abc" />
</feed>
''';
    final feed = FeedClient();
    addTearDown(feed.close);
    expect(
      feed.parseNextFeedUrl(xml),
      'https://www.reddit.com/r/EarthPorn/.rss?count=25&after=t3_abc',
    );
  });

  test('rssUrlWithLimit adds limit query', () {
    expect(
      FeedClient.rssUrlWithLimit('https://www.reddit.com/r/EarthPorn/.rss'),
      contains('limit=100'),
    );
  });
}
