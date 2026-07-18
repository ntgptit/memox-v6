import 'package:flutter/material.dart';
import 'package:memox_v6/core/theme/responsive/app_adaptive_values.dart';
import 'package:memox_v6/presentation/shared/layouts/mx_content_shell.dart';

/// The root phone shell every screen mounts into (kit `MxScaffold`).
///
/// Purpose:
/// One screen frame — app bar, scrolling body, bottom nav and optional
/// FAB slots — honouring top/bottom safe areas, with the page gutter and
/// width caps applied through `MxContentShell` so screens never hand-roll
/// frame layout.
///
/// Use when:
/// The top-level widget of a feature screen. Once per screen, never
/// nested; overlays/sheets/dialogs layer above it.
///
/// Do not use when:
/// List/form/study screens with kit width caps — their dedicated shells
/// (`MxListScaffold`/`MxFormScaffold`/`MxStudyScaffold`, WBS 3.5 child B)
/// preconfigure this frame.
///
/// Category:
/// layout
///
/// Public API:
/// - body: screen content (scrolls by default while bars stay fixed).
/// - appBar / bottomNav / fab: fixed frame slots.
/// - flush: full-bleed body (drops the side gutter).
/// - surface: optional kit content-width cap for the body.
/// - scrollable: set false when the body owns its own scrolling (lists).
///
/// States:
/// with/without each slot, flush, empty body (caller renders the empty
/// state), overflowing body (scrolls), short viewports (scrolls, no
/// overflow).
class MxScaffold extends StatelessWidget {
  const MxScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.bottomNav,
    this.fab,
    this.flush = false,
    this.surface,
    this.scrollable = true,
  });

  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNav;
  final Widget? fab;
  final bool flush;
  final ContentSurface? surface;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final bottomNav = this.bottomNav;
    Widget content = MxContentShell(
      surface: surface,
      flush: flush,
      child: body,
    );

    if (scrollable) {
      content = SingleChildScrollView(child: content);
    }

    return Scaffold(
      appBar: appBar,
      body: SafeArea(bottom: bottomNav == null, child: content),
      bottomNavigationBar: bottomNav == null
          ? null
          : SafeArea(top: false, child: bottomNav),
      floatingActionButton: fab,
    );
  }
}
