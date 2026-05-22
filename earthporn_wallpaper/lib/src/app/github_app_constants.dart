/// Upstream GitHub project (releases + API).
abstract final class GithubAppConstants {
  static const owner = 'eturnercus';
  static const repo = 'test21.05';

  static Uri get releasesLatestPage =>
      Uri.parse('https://github.com/$owner/$repo/releases/latest');

  static Uri get apiLatestRelease =>
      Uri.parse('https://api.github.com/repos/$owner/$repo/releases/latest');

  /// Asset names attached by CI to each tagged release (see `.github/workflows`).
  static const linuxAssetName = 'EarthPorn-Wallpaper-Linux-x64.tar.gz';
  static const windowsAssetName = 'EarthPorn-Wallpaper-Windows-x64.zip';
  static const androidAssetName = 'EarthPorn-Wallpaper-Android-debug.apk';
}
