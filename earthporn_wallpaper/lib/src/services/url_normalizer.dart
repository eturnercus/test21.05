import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

import '../models/wallpaper_orientation.dart';

/// Normalizes Reddit image URLs for reliable downloads.
String normalizeRedditImageUrl(String url) {
  var u = url.replaceAll('&amp;', '&').trim();
  final uri = Uri.tryParse(u);
  if (uri == null) return u;
  var host = uri.host.toLowerCase();
  // Never use replaceAll('preview.redd.it', …): it breaks
  // `external-preview.redd.it` → invalid `external-i.redd.it` (DNS fails).
  if (host == 'preview.redd.it' ||
      host == 'external-preview.redd.it' ||
      host == 'external-i.redd.it') {
    host = 'i.redd.it';
  }
  final rebuilt = Uri(
    scheme: uri.scheme,
    host: host,
    port: uri.hasPort ? uri.port : null,
    path: uri.path,
  );
  var out = rebuilt.toString();
  if (out.contains('://')) {
    final idx = out.indexOf('://');
    final protocol = out.substring(0, idx);
    var rest = out.substring(idx + 3);
    rest = rest.replaceAll(RegExp(r'/+'), '/');
    out = '$protocol://$rest';
  }
  return out;
}

final _dimInBrackets = RegExp(r'\[(\d{3,5})[xX](\d{3,5})\]');
final _dimInText = RegExp(r'(\d{3,5})[xX](\d{3,5})');
final _kTag = RegExp(r'(\d{1,2})[kK](?!B)');

/// EarthPorn-style `[8192x4320]` in title or description.
({int w, int h})? parseBracketDimensions(String text) {
  final m = _dimInBrackets.firstMatch(text);
  if (m == null) return null;
  return (w: int.parse(m.group(1)!), h: int.parse(m.group(2)!));
}

/// Skip download when title already states dimensions that violate [orientation].
bool titleOrientationMatches(String title, WallpaperOrientation orientation) {
  if (orientation == WallpaperOrientation.any) return true;
  final d = parseBracketDimensions(title);
  if (d == null) return true;
  switch (orientation) {
    case WallpaperOrientation.landscape:
      return d.w >= d.h;
    case WallpaperOrientation.portrait:
      return d.h >= d.w;
    case WallpaperOrientation.any:
      return true;
  }
}

/// Direct GET attempts: normalized `i.redd.it` and original URL if different
/// (preview CDN sometimes needs full query; normalization strips it).
List<String> redditImageDownloadCandidates(String rawUrl) {
  final fixed = rawUrl.replaceAll('&amp;', '&').trim();
  final normalized = normalizeRedditImageUrl(rawUrl);
  final out = <String>[];
  void add(String s) {
    final t = s.trim();
    if (t.isEmpty) return;
    if (!out.contains(t)) out.add(t);
  }

  add(normalized);
  add(fixed);
  return out;
}

String imageIdentityHash(String url) {
  final normalized = normalizeRedditImageUrl(url);
  final uri = Uri.parse(normalized);
  final filename = p.basename(uri.path);
  final lower = normalized.toLowerCase();
  if (lower.contains('redd.it')) {
    final stem = p.basenameWithoutExtension(filename);
    final input = utf8.encode('reddit:$stem');
    return md5.convert(input).toString();
  }
  return md5.convert(utf8.encode(normalized)).toString();
}

int resolutionScoreFromText(String text) {
  final bracket = _dimInBrackets.firstMatch(text);
  if (bracket != null) {
    final w = int.parse(bracket.group(1)!);
    final h = int.parse(bracket.group(2)!);
    return w * h;
  }
  final plain = _dimInText.firstMatch(text);
  if (plain != null) {
    final w = int.parse(plain.group(1)!);
    final h = int.parse(plain.group(2)!);
    return w * h;
  }
  final k = _kTag.firstMatch(text);
  if (k != null) {
    final kv = int.parse(k.group(1)!);
    return kv * 1000 * 1000;
  }
  return 0;
}

final _imgUrlRe = RegExp(
  r'https?://[^\s"<>]+\.(?:jpg|jpeg|png|webp)',
  caseSensitive: false,
);

List<String> extractImageUrls(String blob) {
  final found = _imgUrlRe.allMatches(blob).map((m) => m.group(0)!).toList();
  return found;
}

/// Rough pixel area from Reddit preview URLs (`?width=` / `height=`).
int redditPixelAreaEstimate(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null) return 0;
  int? readDim(String k) {
    final raw = uri.queryParameters[k];
    if (raw == null) return null;
    return int.tryParse(raw.split('&').first);
  }

  final w = readDim('width') ?? readDim('w');
  final h = readDim('height') ?? readDim('h');
  if (w != null && h != null && w > 0 && h > 0) {
    return w * h;
  }
  return 0;
}
