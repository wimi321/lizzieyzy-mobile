import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

const _cocoaPodsAsset = 'assets/legal/cocoapods_third_party_licenses.txt';
const _mavenAsset = 'assets/legal/maven_third_party_licenses.txt';

/// Extends Flutter's standard license registry with the exact locked native
/// dependencies. Flutter and Pub notices remain supplied by NOTICES.Z.
void registerNativeLicenseEntries() {
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks(const <String>[
      'CocoaPods native dependencies',
    ], await rootBundle.loadString(_cocoaPodsAsset));
    yield LicenseEntryWithLineBreaks(const <String>[
      'Android Maven native dependencies',
    ], await rootBundle.loadString(_mavenAsset));
  });
}
