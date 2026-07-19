import 'package:flutter/material.dart';
import 'package:memox_v6/core/theme/extensions/app_theme_context.dart';
import 'package:memox_v6/presentation/shared/dialogs/mx_dialog.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_button.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_gap.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_icon.dart';
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
  final colors = context.colors;
  final iconColor = switch (tone) {
    MxConfirmTone.neutral => colors.text,
    MxConfirmTone.warning => colors.warning,
    MxConfirmTone.error => colors.error,
  };

  final confirmed = await showMxDialog<bool>(
    context,
    title: title,
    body: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          MxIcon(icon: icon, color: iconColor),
          const MxGap.s3(),
        ],
        MxText(text),
      ],
    ),
    actions: [
      Builder(
        builder: (dialogContext) => MxButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          label: cancelLabel,
          variant: MxButtonVariant.ghost,
        ),
      ),
      Builder(
        builder: (dialogContext) => MxButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          label: confirmLabel,
          danger: danger || tone == MxConfirmTone.error,
        ),
      ),
    ],
  );
  return confirmed ?? false;
}
