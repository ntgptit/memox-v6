import 'package:flutter/widgets.dart';
import 'package:memox_v6/core/theme/responsive/app_adaptive_values.dart';

/// The page-content wrapper owning gutter and width caps.
///
/// Purpose:
/// Every screen body gets its horizontal page gutter and optional
/// content-width cap from here (guard
/// `memox.screen_shell.no_manual_page_gutter`), so page edges and
/// max-widths follow the responsive contract on every class.
///
/// Use when:
/// Wrapping screen body content — normally via the `MxScaffold` family,
/// which does it for you.
///
/// Do not use when:
/// Nesting inside a scaffold body that already applied it (guard
/// `no_redundant_content_shell`).
///
/// Category:
/// layout
///
/// Public API:
/// - child: the body content.
/// - surface: optional kit width cap (reading/study/list/dashboard);
///   capped content centers on wide windows.
/// - flush: drops the side gutter for full-bleed lists.
class MxContentShell extends StatelessWidget {
  const MxContentShell({
    super.key,
    required this.child,
    this.surface,
    this.flush = false,
  });

  final Widget child;
  final ContentSurface? surface;
  final bool flush;

  @override
  Widget build(BuildContext context) {
    final surface = this.surface;
    Widget content = child;

    if (surface != null) {
      content = Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: context.layout.maxWidthFor(surface),
          ),
          child: content,
        ),
      );
    }

    if (flush) return content;
    return Padding(padding: context.spacing.screenPadding, child: content);
  }
}
