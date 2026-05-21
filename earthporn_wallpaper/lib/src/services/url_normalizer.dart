import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

/// Reddit image URL cleanup (matches the original Python helper).
String normalizeRedditImageUrl(String url) {
  var u = url.replaceAll('&amp;', '&').trim();
  final uri = Uri.tryParse(u);
  if (uri == null) return u;
  var host = uri.host;
  host = host.replaceAll('preview.redd.it', 'i.redd.it');
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

final _dimInBrackets = RegExp(r'\[(\d{3,5})[xX](\d{3,5})\]');
final _dimInText = RegExp(r'(\d{3,5})[xX](\d{3,5})');
final _kTag = RegExp(r'(\d{1,2})[kK](?!B)');

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
