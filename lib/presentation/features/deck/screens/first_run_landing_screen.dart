import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox_v6/app/router/app_navigation.dart';
import 'package:memox_v6/l10n/generated/app_localizations.dart';
import 'package:memox_v6/presentation/features/deck/viewmodels/first_run_landing_viewmodel.dart';
import 'package:memox_v6/presentation/shared/layouts/mx_scaffold.dart';
import 'package:memox_v6/presentation/shared/viewmodels/mx_action_runner.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_button.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_gap.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_tappable.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_text.dart';

/// First-use landing (WBS 5.2.3A; `create-deck.md` §4): a focused
/// full-screen selection — no dialog, no bottom navigation, no
/// carousel, no account/notification asks. One primary CTA, an import
/// secondary and a "Not now" tertiary link.
class FirstRunLandingScreen extends StatelessWidget {
  const FirstRunLandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const MxScaffold(scrollable: true, body: _FirstRunLandingBody());
  }
}

class _FirstRunLandingBody extends ConsumerWidget {
  const _FirstRunLandingBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final dismissState = ref.watch(dismissFirstRunViewmodelProvider);

    listenMxAction(
      ref,
      dismissFirstRunViewmodelProvider,
      onSuccess: () => context.goHome(),
    );

    final isDismissing = dismissState is AsyncLoading<void>;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const MxGap.s8(),
        MxText(
          l10n.appTitle,
          role: MxTextRole.title,
          textAlign: TextAlign.center,
        ),
        const MxGap.s8(),
        MxText(l10n.firstRunLandingTitle, role: MxTextRole.headline),
        const MxGap.s3(),
        MxText(l10n.firstRunLandingBody, role: MxTextRole.body),
        const MxGap.s8(),
        MxButton(
          label: l10n.createFirstDeckLabel,
          block: true,
          onPressed: () => context.goFirstRunLanguage(),
        ),
        const MxGap.s3(),
        MxButton(
          label: l10n.importExistingCardsLabel,
          variant: MxButtonVariant.secondary,
          block: true,
          // Handoff target: the first-run import flow is content-transfer
          // scope (WBS 8.x); the CTA activates when that flow lands.
          onPressed: null,
        ),
        const MxGap.s6(),
        Center(
          child: MxTappable(
            semanticLabel: l10n.notNowLabel,
            onTap: isDismissing
                ? null
                : () => ref
                      .read(dismissFirstRunViewmodelProvider.notifier)
                      .dismissFirstRunLanding(),
            child: MxText(l10n.notNowLabel, role: MxTextRole.subtitle),
          ),
        ),
        const MxGap.s6(),
      ],
    );
  }
}
