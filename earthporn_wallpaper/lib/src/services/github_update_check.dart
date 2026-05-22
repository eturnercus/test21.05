import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app/github_app_constants.dart';
import '../ui/app_locale_text.dart';
import 'settings_repository.dart';

const _kLastGithubUpdateCheckMs = 'github_update_last_check_ms';

/// Compares `1.3.0` / `v1.4.2` style strings (numeric segments only).
int compareReleaseVersions(String a, String b) {
  List<int> parts(String raw) {
    var s = raw.trim();
    if (s.startsWith('v') || s.startsWith('V')) {
      s = s.substring(1);
    }
    s = s.split('+').first;
    final segs = s.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    while (segs.length < 3) {
      segs.add(0);
    }
    return segs;
  }

  final pa = parts(a);
  final pb = parts(b);
  for (var i = 0; i < 3; i++) {
    final c = pa[i].compareTo(pb[i]);
    if (c != 0) return c;
  }
  return 0;
}

/// Returns `true` if [remoteTag] is newer than [currentVersion] (pubspec `version` without build).
bool isRemoteNewerThanCurrent(String remoteTag, String currentVersion) {
  final cur = currentVersion.split('+').first.trim();
  return compareReleaseVersions(remoteTag, cur) > 0;
}

class GithubUpdateCheck {
  GithubUpdateCheck._();

  /// Throttled check; opens a dialog if a newer GitHub release exists.
  static Future<void> runIfEligible({
    required BuildContext context,
    required SettingsRepository settingsRepo,
    bool force = false,
  }) async {
    if (!settingsRepo.settings.checkGithubUpdates && !force) return;

    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().millisecondsSinceEpoch;
    if (!force) {
      final last = prefs.getInt(_kLastGithubUpdateCheckMs) ?? 0;
      if (now - last < const Duration(hours: 8).inMilliseconds) return;
    }

    final info = await PackageInfo.fromPlatform();
    final current = info.version;

    final client = http.Client();
    try {
      final r = await client
          .get(
            GithubAppConstants.apiLatestRelease,
            headers: const {
              'Accept': 'application/vnd.github+json',
              'X-GitHub-Api-Version': '2022-11-28',
            },
          )
          .timeout(const Duration(seconds: 14));
      if (!context.mounted) return;
      if (r.statusCode != 200) return;
      await prefs.setInt(_kLastGithubUpdateCheckMs, now);
      final map = jsonDecode(r.body) as Map<String, dynamic>;
      final tag = (map['tag_name'] as String?)?.trim() ?? '';
      if (tag.isEmpty) return;
      if (!isRemoteNewerThanCurrent(tag, current)) {
        if (force && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                t(
                  context,
                  ru: 'Обновлений нет — установлена актуальная версия.',
                  en: 'You are on the latest version.',
                ),
              ),
            ),
          );
        }
        return;
      }
      if (!context.mounted) return;

      final name = (map['name'] as String?)?.trim();
      final title = name != null && name.isNotEmpty ? name : tag;

      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(
            t(ctx, ru: 'Доступна новая версия', en: 'Update available'),
          ),
          content: Text(
            '${t(ctx, ru: 'Установлено', en: 'Installed')}: $current\n'
            '${t(ctx, ru: 'На GitHub', en: 'On GitHub')}: $title\n\n'
            '${t(ctx, ru: 'Откроется страница релизов, чтобы скачать сборку.', en: 'The releases page will open to download a build.')}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(t(ctx, ru: 'Позже', en: 'Later')),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.pop(ctx);
                final ok = await launchUrl(
                  GithubAppConstants.releasesLatestPage,
                  mode: LaunchMode.externalApplication,
                );
                if (!ok && context.mounted) {
                  ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                    SnackBar(
                      content: Text(
                        t(
                          context,
                          ru: 'Не удалось открыть браузер',
                          en: 'Could not open browser',
                        ),
                      ),
                    ),
                  );
                }
              },
              child: Text(
                t(ctx, ru: 'Открыть релизы', en: 'Open releases'),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      debugPrint('GitHub update check: $e');
    } finally {
      client.close();
    }
  }
}
