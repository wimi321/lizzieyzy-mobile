import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:lizzieyzy_mobile/application/settings/settings.dart';
import 'package:lizzieyzy_mobile/design_system/design_system.dart';
import 'package:lizzieyzy_mobile/domain/domain.dart';
import 'package:lizzieyzy_mobile/infrastructure/io/io.dart';
import 'package:lizzieyzy_mobile/infrastructure/settings/settings.dart';
import 'package:lizzieyzy_mobile/l10n/l10n.dart';

import '../../common/presentation/feature_chrome.dart';

enum _AnalysisSettingsPane { connection, review }

class AnalysisServiceSettingsScreen extends StatefulWidget {
  const AnalysisServiceSettingsScreen({super.key});

  @override
  State<AnalysisServiceSettingsScreen> createState() =>
      _AnalysisServiceSettingsScreenState();
}

class _AnalysisServiceSettingsScreenState
    extends State<AnalysisServiceSettingsScreen> {
  static const _manifestCodec = AnalysisServiceManifestCodec();
  static const _manifestLoader = AnalysisServiceManifestFileLoader(
    codec: _manifestCodec,
  );

  late final TextEditingController _tokenController;
  AnalysisServiceProfile? _profile;
  late AnalysisProfile _analysisProfile;
  late bool _confirmRemoteAnalysis;
  bool _tokenVisible = false;
  bool _importing = false;
  _AnalysisSettingsPane _pane = _AnalysisSettingsPane.connection;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    final settings = AppSettingsScope.of(context).settings;
    _profile = settings.analysisService;
    _analysisProfile = settings.analysisProfile;
    _confirmRemoteAnalysis = settings.confirmRemoteAnalysis;
    _tokenController = TextEditingController(
      text: settings.analysisService?.bearerToken ?? '',
    );
    _initialized = true;
  }

  bool _initialized = false;

  @override
  void dispose() {
    if (_initialized) _tokenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final controller = AppSettingsScope.of(context);
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final largeText = textScale >= 1.6;
    return Scaffold(
      body: Column(
        children: <Widget>[
          FeatureTopBar(
            title: l10n.analysisServiceTitle,
            subtitle: textScale >= 2.5 ? null : l10n.analysisServiceSubtitle,
            leading: const BackCircleButton(),
          ),
          Expanded(
            child: SafeArea(
              top: false,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final dense = constraints.maxHeight < 610 || largeText;
                  if (largeText) {
                    return _buildLargeTextLayout(controller);
                  }
                  return Padding(
                    padding: EdgeInsets.fromLTRB(
                      GoSpacing.s4,
                      dense ? GoSpacing.s1 : GoSpacing.s2,
                      GoSpacing.s4,
                      GoSpacing.s2,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        _ServiceManifestCard(
                          profile: _profile,
                          compact: dense,
                          importing: _importing,
                          onImport: _importManifest,
                        ),
                        SizedBox(height: dense ? GoSpacing.s1 : GoSpacing.s2),
                        TextField(
                          controller: _tokenController,
                          obscureText: !_tokenVisible,
                          enableSuggestions: false,
                          autocorrect: false,
                          keyboardType: TextInputType.visiblePassword,
                          textInputAction: TextInputAction.done,
                          decoration: InputDecoration(
                            labelText: l10n.accessTokenOptional,
                            helperText: largeText
                                ? null
                                : l10n.tokenSecureStorageHelper,
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              tooltip: _tokenVisible
                                  ? l10n.hideToken
                                  : l10n.showToken,
                              onPressed: () => setState(
                                () => _tokenVisible = !_tokenVisible,
                              ),
                              icon: Icon(
                                _tokenVisible
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: dense ? GoSpacing.s1 : GoSpacing.s2),
                        _AnalysisProfileField(
                          value: _analysisProfile,
                          onChanged: (value) =>
                              setState(() => _analysisProfile = value),
                        ),
                        SizedBox(height: dense ? GoSpacing.s1 : GoSpacing.s2),
                        SwitchListTile.adaptive(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: GoSpacing.s2,
                          ),
                          title: Text(l10n.confirmEverySend),
                          subtitle: largeText
                              ? null
                              : Text(l10n.remoteAnalysisSendsFullKifu),
                          value: _confirmRemoteAnalysis,
                          onChanged: (value) =>
                              setState(() => _confirmRemoteAnalysis = value),
                        ),
                        const Spacer(),
                        if (controller.status == AppSettingsStatus.failed)
                          Semantics(
                            liveRegion: true,
                            child: Text(
                              l10n.settingsSaveFailedRetry,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ),
                        Row(
                          children: <Widget>[
                            if (controller.settings.analysisService != null)
                              Expanded(
                                child: OutlinedButton(
                                  onPressed:
                                      controller.status ==
                                          AppSettingsStatus.saving
                                      ? null
                                      : _clear,
                                  child: Text(l10n.removeService),
                                ),
                              ),
                            if (controller.settings.analysisService != null)
                              const SizedBox(width: GoSpacing.s2),
                            Expanded(
                              flex: 2,
                              child: FilledButton.icon(
                                onPressed:
                                    _profile == null ||
                                        controller.status ==
                                            AppSettingsStatus.saving
                                    ? null
                                    : _save,
                                icon:
                                    controller.status ==
                                        AppSettingsStatus.saving
                                    ? const SizedBox.square(
                                        dimension: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.check_rounded),
                                label: Text(l10n.saveConfiguration),
                              ),
                            ),
                          ],
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

  Widget _buildLargeTextLayout(AppSettingsController controller) {
    final l10n = context.l10n;
    final extraLarge = MediaQuery.textScalerOf(context).scale(1) >= 2.5;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        GoSpacing.s3,
        GoSpacing.s1,
        GoSpacing.s3,
        GoSpacing.s2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (extraLarge)
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    _pane == _AnalysisSettingsPane.connection
                        ? l10n.connectionTab
                        : l10n.reviewTab,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                IconButton(
                  tooltip: _pane == _AnalysisSettingsPane.connection
                      ? l10n.reviewTab
                      : l10n.connectionTab,
                  onPressed: () => setState(
                    () => _pane = _pane == _AnalysisSettingsPane.connection
                        ? _AnalysisSettingsPane.review
                        : _AnalysisSettingsPane.connection,
                  ),
                  icon: const Icon(Icons.swap_horiz_rounded),
                ),
              ],
            )
          else
            SegmentedButton<_AnalysisSettingsPane>(
              segments: <ButtonSegment<_AnalysisSettingsPane>>[
                ButtonSegment(
                  value: _AnalysisSettingsPane.connection,
                  label: Text(l10n.connectionTab),
                ),
                ButtonSegment(
                  value: _AnalysisSettingsPane.review,
                  label: Text(l10n.reviewTab),
                ),
              ],
              selected: <_AnalysisSettingsPane>{_pane},
              onSelectionChanged: (selection) =>
                  setState(() => _pane = selection.single),
            ),
          const SizedBox(height: GoSpacing.s1),
          Expanded(
            child: switch (_pane) {
              _AnalysisSettingsPane.connection => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  _LargeServiceManifestCard(
                    profile: _profile,
                    importing: _importing,
                    onImport: _importManifest,
                    onClear: controller.settings.analysisService == null
                        ? null
                        : _clear,
                  ),
                  const SizedBox(height: GoSpacing.s1),
                  TextField(
                    controller: _tokenController,
                    obscureText: !_tokenVisible,
                    enableSuggestions: false,
                    autocorrect: false,
                    decoration: InputDecoration(
                      labelText: l10n.tokenLabel,
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        tooltip: _tokenVisible
                            ? l10n.hideAccessToken
                            : l10n.showAccessToken,
                        onPressed: () =>
                            setState(() => _tokenVisible = !_tokenVisible),
                        icon: Icon(
                          _tokenVisible
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              _AnalysisSettingsPane.review => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  _AnalysisProfileField(
                    value: _analysisProfile,
                    compact: true,
                    onChanged: (value) =>
                        setState(() => _analysisProfile = value),
                  ),
                  const SizedBox(height: GoSpacing.s1),
                  SwitchListTile.adaptive(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: GoSpacing.s1,
                    ),
                    title: Text(l10n.confirmBeforeSend),
                    value: _confirmRemoteAnalysis,
                    onChanged: (value) =>
                        setState(() => _confirmRemoteAnalysis = value),
                  ),
                ],
              ),
            },
          ),
          if (controller.status == AppSettingsStatus.failed)
            Semantics(
              liveRegion: true,
              child: Text(
                l10n.settingsSaveFailed,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          FilledButton(
            onPressed:
                _profile == null ||
                    controller.status == AppSettingsStatus.saving
                ? null
                : _save,
            child: Text(
              controller.status == AppSettingsStatus.saving
                  ? l10n.saving
                  : l10n.save,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _importManifest() async {
    if (_importing) return;
    final l10n = context.l10n;
    setState(() => _importing = true);
    try {
      final type = XTypeGroup(
        label: l10n.analysisManifestFileType,
        extensions: <String>['json'],
        mimeTypes: <String>['application/json'],
        uniformTypeIdentifiers: <String>['public.json'],
      );
      final file = await openFile(acceptedTypeGroups: <XTypeGroup>[type]);
      if (file == null) return;
      final profile = await _manifestLoader.load(
        file,
        bearerToken: _tokenController.text.trim().isEmpty
            ? null
            : _tokenController.text.trim(),
      );
      if (mounted) setState(() => _profile = profile);
    } on Object catch (error) {
      if (!mounted) return;
      final message = switch (error) {
        BoundedReadLimitException() => l10n.manifestTooLarge,
        _ => l10n.manifestReadFailed,
      };
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message.toString())));
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  Future<void> _save() async {
    final controller = AppSettingsScope.of(context);
    final token = _tokenController.text.trim();
    final profile = _profile!.copyWith(
      bearerToken: token.isEmpty ? null : token,
    );
    await controller.update(
      controller.settings.copyWith(
        analysisService: profile,
        analysisProfile: _analysisProfile,
        confirmRemoteAnalysis: _confirmRemoteAnalysis,
      ),
    );
    if (mounted && controller.status == AppSettingsStatus.ready) {
      Navigator.pop(context);
    }
  }

  Future<void> _clear() async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.removeAnalysisServiceTitle),
        content: Text(l10n.removeAnalysisServiceBody),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.keep),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.remove),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final controller = AppSettingsScope.of(context);
    await controller.update(
      controller.settings.copyWith(analysisService: null),
    );
    if (mounted && controller.status == AppSettingsStatus.ready) {
      Navigator.pop(context);
    }
  }
}

class _ServiceManifestCard extends StatelessWidget {
  const _ServiceManifestCard({
    required this.profile,
    required this.compact,
    required this.importing,
    required this.onImport,
  });

  final AnalysisServiceProfile? profile;
  final bool compact;
  final bool importing;
  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return SurfacePanel(
      padding: EdgeInsets.all(compact ? GoSpacing.s2 : GoSpacing.s3),
      child: Row(
        children: <Widget>[
          Icon(
            profile == null ? Icons.cloud_off_outlined : Icons.verified_rounded,
            color: profile == null
                ? theme.colorScheme.onSurfaceVariant
                : theme.colorScheme.primary,
          ),
          const SizedBox(width: GoSpacing.s2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  profile?.model.displayName ?? l10n.manifestNotImported,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall,
                ),
                Text(
                  profile == null
                      ? l10n.manifestPurpose
                      : l10n.manifestConfiguredDetail(
                          profile!.endpoint.host,
                          profile!.model.engineVersion,
                        ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: GoSpacing.s1),
          TextButton.icon(
            onPressed: importing ? null : onImport,
            icon: importing
                ? const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.file_open_outlined),
            label: Text(profile == null ? l10n.importAction : l10n.replace),
          ),
        ],
      ),
    );
  }
}

class _LargeServiceManifestCard extends StatelessWidget {
  const _LargeServiceManifestCard({
    required this.profile,
    required this.importing,
    required this.onImport,
    required this.onClear,
  });

  final AnalysisServiceProfile? profile;
  final bool importing;
  final VoidCallback onImport;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SurfacePanel(
      padding: const EdgeInsets.all(GoSpacing.s1),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              profile?.model.displayName ?? l10n.notConfigured,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (onClear != null)
            IconButton(
              tooltip: l10n.removeAnalysisServiceTooltip,
              onPressed: onClear,
              icon: const Icon(Icons.delete_outline_rounded),
            ),
          IconButton(
            tooltip: profile == null
                ? l10n.importManifestTooltip
                : l10n.replaceManifestTooltip,
            onPressed: importing ? null : onImport,
            icon: importing
                ? const CircularProgressIndicator(strokeWidth: 2)
                : const Icon(Icons.file_open_outlined),
          ),
        ],
      ),
    );
  }
}

class _AnalysisProfileField extends StatelessWidget {
  const _AnalysisProfileField({
    required this.value,
    required this.onChanged,
    this.compact = false,
  });

  final AnalysisProfile value;
  final ValueChanged<AnalysisProfile> onChanged;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final labels = <AnalysisProfile, String>{
      AnalysisProfile.quick: l10n.analysisQuick,
      AnalysisProfile.standard: l10n.analysisStandard,
      AnalysisProfile.deep: l10n.analysisDeep,
    };
    final visits = <AnalysisProfile, int>{
      for (final profile in AnalysisProfile.values)
        profile: AppSettings(
          analysisProfile: profile,
        ).analysisRequestSettings.visitsPerMove,
    };
    return DropdownButtonFormField<AnalysisProfile>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: l10n.reviewDepth,
        border: const OutlineInputBorder(),
      ),
      selectedItemBuilder: compact
          ? (context) => <Widget>[
              Align(
                alignment: Alignment.centerLeft,
                child: Text(labels[AnalysisProfile.quick]!),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(labels[AnalysisProfile.standard]!),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(labels[AnalysisProfile.deep]!),
              ),
            ]
          : null,
      items: <DropdownMenuItem<AnalysisProfile>>[
        for (final profile in AnalysisProfile.values)
          DropdownMenuItem(
            value: profile,
            child: Text(
              l10n.analysisProfileWithVisits(
                labels[profile]!,
                visits[profile]!,
              ),
            ),
          ),
      ],
      onChanged: (next) {
        if (next != null) onChanged(next);
      },
    );
  }
}
