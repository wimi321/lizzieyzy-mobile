import 'package:flutter/material.dart';
import 'package:lizzieyzy_mobile/design_system/design_system.dart';
import 'package:lizzieyzy_mobile/l10n/l10n.dart';

import '../../common/presentation/feature_chrome.dart';

enum _PrivacySection { local, remote, openSource }

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  _PrivacySection _section = _PrivacySection.local;
  int _factIndex = 0;

  void _selectSection(_PrivacySection section) {
    setState(() {
      _section = section;
      _factIndex = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final largeText = MediaQuery.textScalerOf(context).scale(1) >= 1.6;
    final extraLargeText = MediaQuery.textScalerOf(context).scale(1) >= 2.5;
    final longCopy = <String>[
      l10n.privacyLocalFact1,
      l10n.privacyLocalFact2,
      l10n.privacyLocalFact3,
      l10n.privacyRemoteFact1,
      l10n.privacyRemoteFact2,
      l10n.privacyRemoteFact3,
      l10n.privacyOpenSourceFact1,
      l10n.privacyOpenSourceFact2,
      l10n.privacyOpenSourceFact3,
    ].any((fact) => fact.runes.length > 80);
    return Scaffold(
      body: Column(
        children: <Widget>[
          FeatureTopBar(
            title: l10n.privacyOpenSourceTitle,
            subtitle: l10n.privacySubtitle,
            leading: const BackCircleButton(),
          ),
          Expanded(
            child: SafeArea(
              top: false,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compactPanel =
                      largeText || constraints.maxHeight < 620 || longCopy;
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(
                      GoSpacing.s4,
                      GoSpacing.s2,
                      GoSpacing.s4,
                      GoSpacing.s3,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        if (extraLargeText)
                          DropdownButtonFormField<_PrivacySection>(
                            initialValue: _section,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            items: <DropdownMenuItem<_PrivacySection>>[
                              DropdownMenuItem(
                                value: _PrivacySection.local,
                                child: Text(l10n.privacyLocalTab),
                              ),
                              DropdownMenuItem(
                                value: _PrivacySection.remote,
                                child: Text(l10n.privacyRemoteTab),
                              ),
                              DropdownMenuItem(
                                value: _PrivacySection.openSource,
                                child: Text(l10n.privacyOpenSourceTab),
                              ),
                            ],
                            onChanged: (value) {
                              if (value != null) _selectSection(value);
                            },
                          )
                        else
                          SegmentedButton<_PrivacySection>(
                            segments: <ButtonSegment<_PrivacySection>>[
                              ButtonSegment(
                                value: _PrivacySection.local,
                                label: Text(l10n.privacyLocalTab),
                                icon: largeText
                                    ? null
                                    : const Icon(Icons.phone_iphone_rounded),
                              ),
                              ButtonSegment(
                                value: _PrivacySection.remote,
                                label: Text(l10n.privacyRemoteTab),
                                icon: largeText
                                    ? null
                                    : const Icon(Icons.cloud_outlined),
                              ),
                              ButtonSegment(
                                value: _PrivacySection.openSource,
                                label: Text(l10n.privacyOpenSourceTab),
                                icon: largeText
                                    ? null
                                    : const Icon(Icons.code_rounded),
                              ),
                            ],
                            selected: <_PrivacySection>{_section},
                            onSelectionChanged: (selection) =>
                                _selectSection(selection.single),
                          ),
                        const SizedBox(height: GoSpacing.s3),
                        Expanded(
                          child: AnimatedSwitcher(
                            duration: GoMotion.resolve(context, GoMotion.fast),
                            child: _PrivacyPanel(
                              key: ValueKey<_PrivacySection>(_section),
                              section: _section,
                              largeText: compactPanel,
                              extraLargeText: extraLargeText,
                              factIndex: _factIndex,
                              onPreviousFact: () => setState(
                                () => _factIndex = (_factIndex + 2) % 3,
                              ),
                              onNextFact: () => setState(
                                () => _factIndex = (_factIndex + 1) % 3,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: GoSpacing.s2),
                        if (_section == _PrivacySection.openSource)
                          OutlinedButton.icon(
                            onPressed: () => showLicensePage(
                              context: context,
                              applicationName: 'LizzieYZY Mobile',
                              applicationVersion: '0.1.0',
                              applicationLegalese: 'MPL-2.0',
                            ),
                            icon: const Icon(Icons.description_outlined),
                            label: Text(
                              compactPanel
                                  ? l10n.licenses
                                  : l10n.viewThirdPartyLicenses,
                            ),
                          )
                        else if (!compactPanel)
                          const _PrivacyPromise(),
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

class _PrivacyPanel extends StatelessWidget {
  const _PrivacyPanel({
    super.key,
    required this.section,
    required this.largeText,
    required this.extraLargeText,
    required this.factIndex,
    required this.onPreviousFact,
    required this.onNextFact,
  });

  final _PrivacySection section;
  final bool largeText;
  final bool extraLargeText;
  final int factIndex;
  final VoidCallback onPreviousFact;
  final VoidCallback onNextFact;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final (icon, title, facts) = switch (section) {
      _PrivacySection.local => (
        Icons.lock_person_outlined,
        l10n.privacyLocalTitle,
        <String>[
          l10n.privacyLocalFact1,
          l10n.privacyLocalFact2,
          l10n.privacyLocalFact3,
        ],
      ),
      _PrivacySection.remote => (
        Icons.cloud_sync_outlined,
        l10n.privacyRemoteTitle,
        <String>[
          l10n.privacyRemoteFact1,
          l10n.privacyRemoteFact2,
          l10n.privacyRemoteFact3,
        ],
      ),
      _PrivacySection.openSource => (
        Icons.source_outlined,
        l10n.privacyOpenSourcePanelTitle,
        <String>[
          l10n.privacyOpenSourceFact1,
          l10n.privacyOpenSourceFact2,
          l10n.privacyOpenSourceFact3,
        ],
      ),
    };
    final theme = Theme.of(context);
    if (largeText) {
      return Semantics(
        label: l10n.privacyPanelSemantics(title, facts.join('；')),
        excludeSemantics: true,
        child: SurfacePanel(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(GoSpacing.s2),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(icon, color: theme.colorScheme.primary),
                  const SizedBox(height: GoSpacing.s1),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: GoSpacing.s1),
                  Row(
                    children: <Widget>[
                      IconButton(
                        tooltip: l10n.privacyPreviousFact,
                        onPressed: onPreviousFact,
                        icon: const Icon(Icons.chevron_left_rounded),
                      ),
                      Expanded(
                        child: Text(
                          facts[factIndex],
                          textAlign: TextAlign.center,
                          maxLines: extraLargeText ? 1 : 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        tooltip: l10n.privacyNextFact,
                        onPressed: onNextFact,
                        icon: const Icon(Icons.chevron_right_rounded),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return SurfacePanel(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(icon, size: 48, color: theme.colorScheme.primary),
          const SizedBox(height: GoSpacing.s3),
          Text(title, style: theme.textTheme.titleLarge),
          const SizedBox(height: GoSpacing.s3),
          for (final fact in facts)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: GoSpacing.s1),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Icon(
                    Icons.check_circle_outline_rounded,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: GoSpacing.s2),
                  Expanded(child: Text(fact)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _PrivacyPromise extends StatelessWidget {
  const _PrivacyPromise();

  @override
  Widget build(BuildContext context) => Semantics(
    label: context.l10n.privacyPromiseSemantics,
    child: Text(
      context.l10n.privacyPromise,
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.labelMedium,
    ),
  );
}
