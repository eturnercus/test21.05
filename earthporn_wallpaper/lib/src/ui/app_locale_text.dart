import 'package:flutter/widgets.dart';

/// Minimal UI language switch (settings-driven [MaterialApp] locale).
bool localeIsEn(BuildContext context) {
  final l = Localizations.localeOf(context);
  return l.languageCode.toLowerCase() == 'en';
}

String t(BuildContext context, {required String ru, required String en}) =>
    localeIsEn(context) ? en : ru;
