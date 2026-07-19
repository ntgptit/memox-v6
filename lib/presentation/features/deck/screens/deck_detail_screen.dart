import 'package:flutter/material.dart';
import 'package:memox_v6/l10n/generated/app_localizations.dart';
import 'package:memox_v6/presentation/shared/layouts/mx_scaffold.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_gap.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_text.dart';

/// Temporary deck-detail surface (WBS 5.2.4A). Child B replaces this
/// with the real open-deck screen and its Empty/Leaf/Parent branching;
/// until then the route resolves so Library/callout navigation works.
class DeckDetailScreen extends StatelessWidget {
  const DeckDetailScreen({super.key, required this.deckId});

  final String deckId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return MxScaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const MxGap.s6(),
          MxText(l10n.libraryTitle, role: MxTextRole.caption),
          const MxGap.s2(),
          MxText(deckId, role: MxTextRole.subtitle),
        ],
      ),
    );
  }
}
