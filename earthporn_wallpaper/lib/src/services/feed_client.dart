import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';

import '../models/wallpaper_candidate.dart';
import 'url_normalizer.dart';

/// Fetches r/EarthPorn RSS (AllOrigins first, then direct) and extracts images.
class FeedClient {
  FeedClient({http.Client? httpClient}) : _client = httpClient ?? http.Client();

  final http.Client _client;

  static String allOriginsRawUrl(String target) =>
      'https://api.allorigins.win/raw?url=${Uri.encodeComponent(target)}';

  Future<String?> fetchRssXml({
    required String rssUrl,
    required bool proxyFirst,
    required Duration timeout,
  }) async {
    final headers = <String, String>{
      'User-Agent':
          'Mozilla/5.0 (EarthPornWallpaper/1.0; by eturnercus) AppleWebKit/537.36',
    };
    Future<String?> tryGet(String u) async {
      try {
        final r = await _client.get(Uri.parse(u), headers: headers).timeout(timeout);
        if (r.statusCode >= 200 && r.statusCode < 300) {
          return r.body;
        }
      } catch (_) {}
      return null;
    }

    if (proxyFirst) {
      final proxied = await tryGet(allOriginsRawUrl(rssUrl));
      if (proxied != null && proxied.isNotEmpty) return proxied;
    }
    final direct = await tryGet(rssUrl);
    if (direct != null && direct.isNotEmpty) return direct;

    if (!proxyFirst) {
      final proxied = await tryGet(allOriginsRawUrl(rssUrl));
      if (proxied != null && proxied.isNotEmpty) return proxied;
    }
    return null;
  }

  List<WallpaperCandidate> parseCandidates(String xmlText) {
    final doc = XmlDocument.parse(xmlText);
    final root = doc.rootElement;
    final out = <WallpaperCandidate>[];

    Iterable<XmlElement> entries;
    if (root.name.local == 'feed') {
      entries = root.childElements.where((e) => e.name.local == 'entry');
    } else if (root.name.local == 'rss') {
      XmlElement? channel;
      for (final c in root.childElements) {
        if (c.name.local == 'channel') {
          channel = c;
          break;
        }
      }
      if (channel == null) return out;
      entries = channel.childElements.where((e) => e.name.local == 'item');
    } else {
      return out;
    }

    for (final entry in entries) {
      if (_isNsfw(entry)) continue;

      final title = _textOf(entry, 'title');
      final linkHref = _linkHref(entry);
      final linkText = _textOf(entry, 'link');
      final link = (linkHref != null && linkHref.isNotEmpty) ? linkHref : linkText;
      final desc = _blob(entry);

      final urls = <String>{};
      for (final raw in extractImageUrls('$title $desc $link')) {
        urls.add(normalizeRedditImageUrl(raw));
      }

      for (final u in urls) {
        if (!u.startsWith('http')) continue;
        var score = resolutionScoreFromText(title);
        if (score == 0) score = resolutionScoreFromText(u);
        out.add(WallpaperCandidate(
          url: u,
          title: title,
          resolutionScore: score,
          postUrl: link,
        ));
      }
    }

    out.sort((a, b) => b.resolutionScore.compareTo(a.resolutionScore));
    return out;
  }

  bool _isNsfw(XmlElement entry) {
    for (final c in entry.childElements) {
      if (c.name.local != 'category') continue;
      final term = c.getAttribute('term')?.toLowerCase() ??
          c.getAttribute('label')?.toLowerCase();
      if (term == 'nsfw') return true;
    }
    return false;
  }

  String _textOf(XmlElement entry, String local) {
    final el = entry.childElements.firstWhere(
      (e) => e.name.local == local,
      orElse: () => XmlElement(XmlName('x')),
    );
    if (el.name.local == 'x') return '';
    return el.innerText.trim();
  }

  String? _linkHref(XmlElement entry) {
    for (final e in entry.childElements) {
      if (e.name.local == 'link') {
        final href = e.getAttribute('href');
        if (href != null && href.isNotEmpty) return href;
      }
    }
    return null;
  }

  String _blob(XmlElement entry) {
    final parts = <String>[];
    for (final e in entry.childElements) {
      final n = e.name.local;
      if (n == 'content' || n == 'summary' || n == 'description') {
        parts.add(e.innerText);
        final type = e.getAttribute('type');
        if (type == 'html' || type == 'xhtml' || n == 'description') {
          parts.add(e.innerText);
        }
      }
    }
    return parts.join(' ');
  }

  void close() => _client.close();
}
