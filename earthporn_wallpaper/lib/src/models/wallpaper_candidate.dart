class WallpaperCandidate {
  const WallpaperCandidate({
    required this.url,
    required this.title,
    required this.resolutionScore,
    required this.postUrl,
  });

  final String url;
  final String title;
  final int resolutionScore;
  final String postUrl;
}
