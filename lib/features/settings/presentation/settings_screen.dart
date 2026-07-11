import 'package:flutter/material.dart';
import 'package:lizzieyzy_mobile/application/settings/settings.dart';
import 'package:lizzieyzy_mobile/design_system/design_system.dart';
import 'package:lizzieyzy_mobile/l10n/l10n.dart';

import '../../../app/app_routes.dart';
import '../../common/presentation/feature_chrome.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final controller = AppSettingsScope.of(context);
    final settings = controller.settings;
    final useLargeTextLayout = MediaQuery.textScalerOf(context).scale(1) >= 1.6;
    return Scaffold(
      body: Column(
        children: <Widget>[
          FeatureTopBar(
            title: l10n.settingsTitle,
            subtitle: l10n.settingsSubtitle,
            leading: const BackCircleButton(),
          ),
          Expanded(
            child: SafeArea(
              top: false,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final dense = constraints.maxHeight < 610;
                  if (useLargeTextLayout) {
                    return _LargeTextSettingsGrid(
                      analysisConfigured: settings.analysisService != null,
                    );
                  }
                  return Padding(
                    padding: EdgeInsets.fromLTRB(
                      GoSpacing.s4,
                      dense ? GoSpacing.s1 : GoSpacing.s3,
                      GoSpacing.s4,
                      GoSpacing.s3,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        _SettingsTile(
                          icon: Icons.memory_rounded,
                          title: l10n.analysisServiceTitle,
                          detail: settings.analysisService == null
                              ? l10n.analysisServiceUnconfigured
                              : l10n.analysisServiceConfigured(
                                  settings.analysisService!.model.displayName,
                                ),
                          onTap: () => Navigator.pushNamed(
                            context,
                            AppRoutes.analysisServiceSettings,
                          ),
                        ),
                        SizedBox(height: dense ? GoSpacing.s1 : GoSpacing.s2),
                        _SettingsTile(
                          icon: Icons.contrast_rounded,
                          title: l10n.appearanceTitle,
                          detail: _themeLabel(l10n, settings.theme),
                          onTap: () => Navigator.pushNamed(
                            context,
                            AppRoutes.appearanceSettings,
                          ),
                        ),
                        SizedBox(height: dense ? GoSpacing.s1 : GoSpacing.s2),
                        _SettingsTile(
                          icon: Icons.translate_rounded,
                          title: l10n.languageTitle,
                          detail: _localeLabel(l10n, settings.locale),
                          onTap: () => Navigator.pushNamed(
                            context,
                            AppRoutes.languageSettings,
                          ),
                        ),
                        SizedBox(height: dense ? GoSpacing.s1 : GoSpacing.s2),
                        _SettingsTile(
                          icon: Icons.privacy_tip_outlined,
                          title: l10n.privacyOpenSourceTitle,
                          detail: l10n.privacyOpenSourceDetail,
                          onTap: () => Navigator.pushNamed(
                            context,
                            AppRoutes.privacySettings,
                          ),
                        ),
                        const Spacer(),
                        Semantics(
                          label: l10n.appVersionSemantics,
                          child: Text(
                            l10n.appVersionLabel,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LargeTextSettingsGrid extends StatelessWidget {
  const _LargeTextSettingsGrid({required this.analysisConfigured});

  final bool analysisConfigured;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        GoSpacing.s3,
        GoSpacing.s1,
        GoSpacing.s3,
        GoSpacing.s3,
      ),
      child: Column(
        children: <Widget>[
          Expanded(
            child: Row(
              children: <Widget>[
                Expanded(
                  child: _SettingsShortcut(
                    icon: Icons.memory_rounded,
                    label: analysisConfigured
                        ? l10n.analysisShortcutConfigured
                        : l10n.analysisShortcutUnconfigured,
                    route: AppRoutes.analysisServiceSettings,
                  ),
                ),
                const SizedBox(width: GoSpacing.s2),
                Expanded(
                  child: _SettingsShortcut(
                    icon: Icons.contrast_rounded,
                    label: l10n.appearanceTitle,
                    route: AppRoutes.appearanceSettings,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: GoSpacing.s2),
          Expanded(
            child: Row(
              children: <Widget>[
                Expanded(
                  child: _SettingsShortcut(
                    icon: Icons.translate_rounded,
                    label: l10n.languageTitle,
                    route: AppRoutes.languageSettings,
                  ),
                ),
                const SizedBox(width: GoSpacing.s2),
                Expanded(
                  child: _SettingsShortcut(
                    icon: Icons.privacy_tip_outlined,
                    label: l10n.privacyShortcut,
                    route: AppRoutes.privacySettings,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsShortcut extends StatelessWidget {
  const _SettingsShortcut({
    required this.icon,
    required this.label,
    required this.route,
  });

  final IconData icon;
  final String label;
  final String route;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label.replaceAll('\n', '，'),
    excludeSemantics: true,
    child: InkWell(
      borderRadius: BorderRadius.circular(GoRadii.card),
      onTap: () => Navigator.pushNamed(context, route),
      child: Ink(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(GoRadii.card),
          border: Border.all(color: Theme.of(context).colorScheme.outline),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(GoSpacing.s2),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: GoSpacing.s1),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class AppearanceSettingsScreen extends StatelessWidget {
  const AppearanceSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final controller = AppSettingsScope.of(context);
    return _ChoiceScreen<AppThemePreference>(
      title: l10n.appearanceTitle,
      subtitle: l10n.appearanceSubtitle,
      selected: controller.settings.theme,
      values: AppThemePreference.values,
      label: (value) => _themeLabel(l10n, value),
      icon: (value) => switch (value) {
        AppThemePreference.system => Icons.brightness_auto_rounded,
        AppThemePreference.light => Icons.light_mode_rounded,
        AppThemePreference.dark => Icons.dark_mode_rounded,
      },
      onSelected: (value) =>
          controller.update(controller.settings.copyWith(theme: value)),
    );
  }
}

class LanguageSettingsScreen extends StatelessWidget {
  const LanguageSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final controller = AppSettingsScope.of(context);
    return _ChoiceScreen<AppLocalePreference>(
      title: l10n.languageTitle,
      subtitle: l10n.languageSubtitle,
      selected: controller.settings.locale,
      values: AppLocalePreference.values,
      label: (value) => _localeLabel(l10n, value),
      icon: (_) => Icons.language_rounded,
      onSelected: (value) =>
          controller.update(controller.settings.copyWith(locale: value)),
    );
  }
}

class _ChoiceScreen<T> extends StatelessWidget {
  const _ChoiceScreen({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.values,
    required this.label,
    required this.icon,
    required this.onSelected,
  });

  final String title;
  final String subtitle;
  final T selected;
  final List<T> values;
  final String Function(T value) label;
  final IconData Function(T value) icon;
  final Future<void> Function(T value) onSelected;

  @override
  Widget build(BuildContext context) {
    final compactForLargeText =
        MediaQuery.textScalerOf(context).scale(1) >= 2.5;
    return Scaffold(
      body: Column(
        children: <Widget>[
          FeatureTopBar(
            title: title,
            subtitle: subtitle,
            leading: const BackCircleButton(),
          ),
          Expanded(
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(GoSpacing.s4),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    const columns = 2;
                    final rows = (values.length / columns).ceil();
                    final gap = GoSpacing.s2;
                    return Column(
                      children: <Widget>[
                        for (var row = 0; row < rows; row++) ...<Widget>[
                          Expanded(
                            child: Row(
                              children: <Widget>[
                                for (
                                  var column = 0;
                                  column < columns;
                                  column++
                                ) ...<Widget>[
                                  if (column > 0) SizedBox(width: gap),
                                  Expanded(
                                    child:
                                        row * columns + column < values.length
                                        ? _ChoiceTile<T>(
                                            value:
                                                values[row * columns + column],
                                            selected:
                                                values[row * columns +
                                                    column] ==
                                                selected,
                                            label: label,
                                            icon: icon,
                                            onSelected: onSelected,
                                            compact: compactForLargeText,
                                          )
                                        : const SizedBox.shrink(),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (row + 1 < rows) SizedBox(height: gap),
                        ],
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChoiceTile<T> extends StatelessWidget {
  const _ChoiceTile({
    required this.value,
    required this.selected,
    required this.label,
    required this.icon,
    required this.onSelected,
    required this.compact,
  });

  final T value;
  final bool selected;
  final String Function(T value) label;
  final IconData Function(T value) icon;
  final Future<void> Function(T value) onSelected;
  final bool compact;

  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    button: true,
    label: label(value),
    excludeSemantics: true,
    child: InkWell(
      borderRadius: BorderRadius.circular(GoRadii.card),
      onTap: () async {
        await onSelected(value);
        if (context.mounted) Navigator.pop(context);
      },
      child: Ink(
        decoration: BoxDecoration(
          color: selected
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(GoRadii.card),
          border: Border.all(
            color: selected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline,
          ),
        ),
        child: compact
            ? Stack(
                children: <Widget>[
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(GoSpacing.s2),
                      child: Text(
                        label(value),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  if (selected)
                    const Positioned(
                      right: GoSpacing.s1,
                      top: GoSpacing.s1,
                      child: Icon(Icons.check_circle_rounded, size: 20),
                    ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(icon(value)),
                  const SizedBox(height: GoSpacing.s1),
                  Text(
                    label(value),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (selected) const Icon(Icons.check_circle_rounded),
                ],
              ),
      ),
    ),
  );
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.detail,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String detail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      label: context.l10n.settingsTileSemantics(title, detail),
      excludeSemantics: true,
      child: Material(
        color: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(GoRadii.card),
          side: BorderSide(color: theme.colorScheme.outline),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(GoRadii.card),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: GoSizes.comfortableTouchTarget,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: GoSpacing.s3,
                vertical: GoSpacing.s2,
              ),
              child: Row(
                children: <Widget>[
                  Icon(icon, color: theme.colorScheme.primary),
                  const SizedBox(width: GoSpacing.s3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(title, style: theme.textTheme.titleSmall),
                        Text(
                          detail,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String _themeLabel(AppLocalizations l10n, AppThemePreference value) =>
    switch (value) {
      AppThemePreference.system => l10n.themeSystem,
      AppThemePreference.light => l10n.themeLight,
      AppThemePreference.dark => l10n.themeDark,
    };

String _localeLabel(AppLocalizations l10n, AppLocalePreference value) =>
    switch (value) {
      AppLocalePreference.system => l10n.localeSystem,
      AppLocalePreference.simplifiedChinese => l10n.localeSimplifiedChinese,
      AppLocalePreference.traditionalChinese => l10n.localeTraditionalChinese,
      AppLocalePreference.english => l10n.localeEnglish,
      AppLocalePreference.japanese => l10n.localeJapanese,
      AppLocalePreference.korean => l10n.localeKorean,
    };
