import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lizzieyzy_mobile/application/native_license_registry.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('registers complete locked CocoaPods and Maven notices', () async {
    registerNativeLicenseEntries();

    final entries = await LicenseRegistry.licenses.toList();
    final cocoaPods = entries.singleWhere(
      (entry) => entry.packages.contains('CocoaPods native dependencies'),
    );
    final maven = entries.singleWhere(
      (entry) => entry.packages.contains('Android Maven native dependencies'),
    );

    expect(
      cocoaPods.paragraphs.map((paragraph) => paragraph.text).join('\n'),
      contains('## MLKitCommon'),
    );
    expect(
      maven.paragraphs.map((paragraph) => paragraph.text).join('\n'),
      contains('com.google.mlkit:text-recognition:16.0.1'),
    );
  });
}
