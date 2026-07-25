import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:memox_v6/l10n/generated/app_localizations.dart';
import 'package:memox_v6/presentation/features/deck/viewmodels/library_viewmodel.dart';
import 'package:memox_v6/presentation/shared/bottom_sheets/mx_select_sheet.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_chip.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_gap.dart';

/// Kit `FilterRow`: scope · filters · sort, over a deck list.
///
/// The kit renders this same row on the Library root and on a nested deck
/// list (`SubdeckList.jsx` uses `LIB.FilterRow` under its own node prefix),
/// so it is shared and its state is keyed by [scopeId] — one shared state
/// would mean filtering the Library also filtered the nested list behind it.
///
/// The scope chip is static until multi-pair scoping lands; filters and sort
/// drive [LibraryControlsViewmodel].
class DeckListControls extends ConsumerWidget {
  const DeckListControls({super.key, required this.scopeId});

  /// Which list this row controls — `DeckListControls.libraryScope` for the
  /// Library root, or a deck id for a nested list.
  final String scopeId;

  /// The Library root's scope key.
  static const String libraryScope = 'library';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final controls = ref.watch(libraryControlsViewmodelProvider(scopeId));
    final notifier = ref.read(
      libraryControlsViewmodelProvider(scopeId).notifier,
    );
    final filtered = controls.status != LibraryStatusFilter.all;

    return Row(
      children: [
        MxChip(label: l10n.libraryScopeAllLabel),
        const Spacer(),
        MxChip(
          label: filtered
              ? l10n.libraryFiltersActiveLabel(1)
              : l10n.libraryFiltersLabel,
          icon: Symbols.tune_rounded,
          selected: filtered,
          onTap: () =>
              _openStatusSheet(context, l10n, controls.status, notifier),
        ),
        const MxGap.s2(),
        MxChip(
          label: controls.sort == LibrarySort.az
              ? l10n.librarySortAzLabel
              : l10n.librarySortZaLabel,
          icon: Symbols.swap_vert_rounded,
          onTap: notifier.toggleSort,
        ),
      ],
    );
  }

  Future<void> _openStatusSheet(
    BuildContext context,
    AppLocalizations l10n,
    LibraryStatusFilter current,
    LibraryControlsViewmodel notifier,
  ) async {
    final picked = await showMxSelectSheet<LibraryStatusFilter>(
      context,
      title: l10n.libraryFilterTitle,
      selected: current,
      options: [
        MxSelectOption(
          key: LibraryStatusFilter.all,
          icon: Symbols.stacks_rounded,
          label: l10n.libraryScopeAllLabel,
        ),
        MxSelectOption(
          key: LibraryStatusFilter.due,
          icon: Symbols.schedule_rounded,
          label: l10n.libraryFilterDueLabel,
        ),
        MxSelectOption(
          key: LibraryStatusFilter.isNew,
          icon: Symbols.fiber_new_rounded,
          label: l10n.libraryFilterNewLabel,
        ),
      ],
    );
    if (picked != null) notifier.setStatus(picked);
  }
}
