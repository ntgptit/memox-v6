import 'package:flutter/material.dart';
import 'package:memox_v6/presentation/shared/dialogs/mx_dialog.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_icon_tile.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_button.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_text.dart';

/// Icon tint tones of the kit ConfirmDialog composite.
enum MxConfirmTone { neutral, warning, error }

/// Presents the shared confirm composite (kit `_shared/ConfirmDialog`):
/// an optional tone-tinted icon, title, body copy and a Cancel/Confirm
/// pair over [showMxDialog]. Carries no copy of its own — every string
/// arrives from the caller.
///
/// Returns `true` on confirm; cancel and barrier dismiss return `false`.
Future<bool> showMxConfirmDialog(
  BuildContext context, {
  IconData? icon,
  MxConfirmTone tone = MxConfirmTone.neutral,
  required String title,
  required String text,
  required String confirmLabel,
  required String cancelLabel,
  bool danger = false,
}) async {
  final confirmed = await showMxDialog<bool>(
    context,
    // The kit's icon `Dialog`: the tone tile leads, the copy is centred under
    // it, and the two actions share one row. This used to compose the form
    // layout with a bare glyph inside the body (`int-54`).
    icon: icon,
    tone: switch (tone) {
      MxConfirmTone.neutral => MxIconTileTone.primary,
      MxConfirmTone.warning => MxIconTileTone.warning,
      MxConfirmTone.error => MxIconTileTone.error,
    },
    title: title,
    body: MxText(text),
    actions: [
      Builder(
        builder: (dialogContext) => MxButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          label: cancelLabel,
          variant: MxButtonVariant.ghost,
          block: true,
        ),
      ),
      Builder(
        builder: (dialogContext) => MxButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          label: confirmLabel,
          // Tone colours the tile, not the button: the kit's error-toned
          // dialogs still carry a primary confirm unless the action itself
          // destroys something, which is what `danger` says.
          danger: danger,
          block: true,
        ),
      ),
    ],
  );
  return confirmed ?? false;
}
