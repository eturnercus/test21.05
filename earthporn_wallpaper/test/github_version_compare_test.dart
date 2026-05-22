import 'package:flutter_test/flutter_test.dart';

import 'package:earthporn_wallpaper/src/services/github_update_check.dart';

void main() {
  test('compareReleaseVersions orders semver-like tags', () {
    expect(compareReleaseVersions('1.0.0', '1.0.1'), lessThan(0));
    expect(compareReleaseVersions('v1.2.0', '1.1.9'), greaterThan(0));
    expect(compareReleaseVersions('1.3.0+24', '1.3.1'), lessThan(0));
  });

  test('isRemoteNewerThanCurrent', () {
    expect(isRemoteNewerThanCurrent('v1.4.0', '1.3.0'), isTrue);
    expect(isRemoteNewerThanCurrent('1.3.0', '1.3.0'), isFalse);
    expect(isRemoteNewerThanCurrent('1.2.9', '1.3.0'), isFalse);
  });
}
