import 'package:flutter/widgets.dart';

import 'generated/app_localizations.dart';

export 'generated/app_localizations.dart';

extension AppLocalizationsContext on BuildContext {
  /// Production apps install the delegate at the root. The Chinese fallback
  /// keeps isolated components deterministic in previews and host apps that
  /// have not installed the delegate yet.
  AppLocalizations get l10n =>
      Localizations.of<AppLocalizations>(this, AppLocalizations) ??
      lookupAppLocalizations(const Locale('zh'));
}
