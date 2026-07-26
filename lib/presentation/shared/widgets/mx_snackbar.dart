import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:memox_v6/core/theme/extensions/app_theme_context.dart';
import 'package:memox_v6/core/theme/tokens/app_border_radii.dart';
import 'package:memox_v6/core/theme/tokens/app_spacing.dart';
import 'package:memox_v6/core/theme/tokens/app_strokes.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_gap.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_icon.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_link.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_text.dart';

/// Tone scale of the kit `Snackbar`, each with its own flat token set.
enum MxSnackbarTone { neutral, success, error, info }

/// A transient confirmation bar (kit `Snackbar`).
///
/// Purpose:
/// The one surface that says an action landed. Flows close their dialog and
/// return the learner to where they were; without this, "it worked" and
/// "nothing happened" look identical.
///
/// Use when:
/// A command has succeeded and the result is not obvious on the screen
/// behind it — `Deck deleted`, `Deck moved`, `Deck progress reset`.
///
/// Do not use when:
/// The message needs a decision (`MxDialog`), belongs in the flow of the
/// screen (`MxActionCallout`), or reports a failure the learner must act on
/// — a failed command shows its error where the action was.
///
/// Category:
/// feedback
///
/// Public API:
/// - message: the confirmation copy (localized by the caller).
/// - tone: kit tone; `success` is the default for a completed command.
/// - action: optional single action (label + callback); dismisses first.
///
/// Variants:
/// See [MxSnackbarTone]; with and without an action.
class MxSnackbar extends StatelessWidget {
  const MxSnackbar({
    super.key,
    required this.message,
    this.tone = MxSnackbarTone.success,
    this.action,
  });

  final String message;
  final MxSnackbarTone tone;
  final MxSnackbarAction? action;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    // The kit's tonal container: an opaque soft ground with the strong tone
    // on the glyph only — calm, not a saturated block.
    final (background, foreground, accent, border, glyph) = switch (tone) {
      MxSnackbarTone.neutral => (
        colors.snackbarNeutralBg,
        colors.snackbarNeutralText,
        colors.snackbarNeutralAccent,
        colors.snackbarNeutralBorder,
        null,
      ),
      MxSnackbarTone.success => (
        colors.snackbarSuccessBg,
        colors.snackbarSuccessText,
        colors.snackbarSuccessAccent,
        colors.snackbarSuccessBorder,
        Symbols.check_circle_rounded,
      ),
      MxSnackbarTone.error => (
        colors.snackbarErrorBg,
        colors.snackbarErrorText,
        colors.snackbarErrorAccent,
        colors.snackbarErrorBorder,
        Symbols.error_rounded,
      ),
      MxSnackbarTone.info => (
        colors.snackbarInfoBg,
        colors.snackbarInfoText,
        colors.snackbarInfoAccent,
        colors.snackbarInfoBorder,
        Symbols.info_rounded,
      ),
    };
    final action = this.action;

    return Container(
      constraints: const BoxConstraints(minHeight: AppSpacing.touchMin),
      padding: const EdgeInsets.only(
        left: AppSpacing.space4,
        right: AppSpacing.space3,
        top: AppSpacing.space2,
        bottom: AppSpacing.space2,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppBorderRadii.control,
        border: Border.all(color: border, width: AppStrokes.hairline),
        boxShadow: context.elevations.shadowLg,
      ),
      child: Row(
        children: [
          if (glyph != null) ...[
            MxIcon(icon: glyph, color: accent),
            const MxGap.s3(),
          ],
          Expanded(
            child: MxText(message, role: MxTextRole.caption, color: foreground),
          ),
          if (action != null) ...[
            const MxGap.s3(),
            MxLink(
              label: action.label,
              // The bar is transient: taking its action dismisses it first,
              // so the destination is not left with a bar floating over it.
              onTap: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                action.onPressed();
              },
            ),
          ],
        ],
      ),
    );
  }
}

/// The single optional action of an [MxSnackbar] — kit `Snackbar.action`.
class MxSnackbarAction {
  const MxSnackbarAction({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;
}

/// Shows [message] as a transient confirmation over the current screen.
///
/// The bar sits above the bottom nav on the gutter, like the kit's, and
/// replaces any bar already showing — a second confirmation supersedes the
/// first rather than queueing behind it (`navigation-overlays.md`: a status
/// message is not a focus layer).
void showMxSnackbar(
  BuildContext context, {
  required String message,
  MxSnackbarTone tone = MxSnackbarTone.success,
  MxSnackbarAction? action,
}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: MxSnackbar(message: message, tone: tone, action: action),
        // The bar draws its own tonal ground, border and shadow, so the
        // Material shell around it carries none of its own — the surface
        // token at zero alpha, as `MxIconButton`'s quiet variant does it.
        backgroundColor: context.colors.surface.withAlpha(0),
        elevation: 0,
        padding: EdgeInsets.zero,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(
          left: AppSpacing.gutter,
          right: AppSpacing.gutter,
          bottom: AppSpacing.bottomNavHeight + AppSpacing.space3,
        ),
      ),
    );
}
