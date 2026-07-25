import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:memox_v6/app/router/app_navigation.dart';
import 'package:memox_v6/l10n/generated/app_localizations.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_button.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_empty_state.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_icon_tile.dart';

/// The deck detail's two failure surfaces, split out of the screen so they
/// can be rendered and asserted on their own.

class DeckNotFoundState extends StatelessWidget {
  const DeckNotFoundState({super.key, required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    // Kit `subdeck-list--not-found`: a warning tile with a safe way out, not
    // a bare line of text. The deck is gone, so the only action offered is
    // the one that still works.
    return MxEmptyState(
      icon: Symbols.folder_off_rounded,
      tone: MxIconTileTone.warning,
      title: l10n.deckNotFoundTitle,
      body: l10n.deckNotFoundBody,
      action: MxButton(
        label: l10n.backToLibraryLabel,
        icon: Symbols.arrow_back_rounded,
        onPressed: () => context.goLibrary(),
      ),
    );
  }
}

/// Kit `subdeck-list--error` / `flashcard-list--error`: a centred failure
/// with a retry, rather than an inline banner over an empty screen.
class DeckLoadErrorState extends StatelessWidget {
  const DeckLoadErrorState({
    super.key,
    required this.title,
    required this.onRetry,
  });

  final String title;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return MxEmptyState(
      icon: Symbols.cloud_off_rounded,
      tone: MxIconTileTone.error,
      title: title,
      body: l10n.loadErrorBody,
      action: MxButton(
        label: l10n.tryAgainLabel,
        icon: Symbols.refresh_rounded,
        onPressed: onRetry,
      ),
    );
  }
}
