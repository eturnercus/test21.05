import 'package:shared_preferences/shared_preferences.dart';

/// Last successful HTTP path for Reddit image bytes (persisted for faster retries).
enum ImageFetchChannel {
  direct,
  allOrigins,
  corsProxy,
}

class ImageFetchPrefs {
  ImageFetchPrefs._();

  static const _key = 'image_fetch_last_ok_channel_v1';

  static Future<ImageFetchChannel?> loadPreferred() async {
    final p = await SharedPreferences.getInstance();
    return _parse(p.getString(_key));
  }

  static ImageFetchChannel? _parse(String? s) {
    switch (s) {
      case 'direct':
        return ImageFetchChannel.direct;
      case 'allorigins':
        return ImageFetchChannel.allOrigins;
      case 'cors':
        return ImageFetchChannel.corsProxy;
      default:
        return null;
    }
  }

  static Future<void> savePreferred(ImageFetchChannel channel) async {
    final p = await SharedPreferences.getInstance();
    final v = switch (channel) {
      ImageFetchChannel.direct => 'direct',
      ImageFetchChannel.allOrigins => 'allorigins',
      ImageFetchChannel.corsProxy => 'cors',
    };
    await p.setString(_key, v);
  }

  /// Try [preferred] first when non-null; otherwise default engine order.
  static List<ImageFetchChannel> ordered(ImageFetchChannel? preferred) {
    const all = ImageFetchChannel.values;
    if (preferred == null) return all.toList();
    final rest = all.where((c) => c != preferred).toList();
    return [preferred, ...rest];
  }
}
