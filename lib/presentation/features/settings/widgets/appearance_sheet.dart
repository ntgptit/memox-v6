import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:memox_v6/domain/preferences/appearance_mode.dart';
import 'package:memox_v6/l10n/generated/app_localizations.dart';
import 'package:memox_v6/presentation/features/settings/viewmodels/appearance_viewmodel.dart';
import 'package:memox_v6/presentation/shared/bottom_sheets/mx_sheet.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_gap.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_icon.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_tappable.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_text.dart';

/// The appearance single-selection sheet (WBS 8.1; `set-appearance-preference.md`)
/// — System / Light / Dark, with a check on the effective choice. Picking a row
/// persists it and re-themes the whole app; the sheet then closes.
Future<void> showAppearanceSheet(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  return showMxSheet<void>(
    context,
    title: l10n.appearanceLabel,
    child: const _AppearanceBody(),
  );
}

class _AppearanceBody extends ConsumerWidget {
  const _AppearanceBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final current =
        ref.watch(appearanceModeProvider).value ?? AppearanceMode.system;

    void select(AppearanceMode mode) {
      ref
          .read(appearanceCommandViewmodelProvider.notifier)
          .selectAppearance(mode);
      Navigator.of(context).pop();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _OptionRow(
          label: l10n.appearanceSystemLabel,
          selected: current == AppearanceMode.system,
          onTap: () => select(AppearanceMode.system),
        ),
        _OptionRow(
          label: l10n.appearanceLightLabel,
          selected: current == AppearanceMode.light,
          onTap: () => select(AppearanceMode.light),
        ),
        _OptionRow(
          label: l10n.appearanceDarkLabel,
          selected: current == AppearanceMode.dark,
          onTap: () => select(AppearanceMode.dark),
        ),
      ],
    );
  }
}

class _OptionRow extends StatelessWidget {
  const _OptionRow({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MxTappable(
      semanticLabel: label,
      onTap: onTap,
      child: Row(
        children: [
          const MxGap.s3(),
          Expanded(child: MxText(label, role: MxTextRole.body)),
          if (selected) const MxIcon(icon: Symbols.check_rounded),
          const MxGap.s3(),
        ],
      ),
    );
  }
}
