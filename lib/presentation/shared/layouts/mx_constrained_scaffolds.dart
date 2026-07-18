import 'package:flutter/material.dart';
import 'package:memox_v6/core/theme/responsive/app_adaptive_values.dart';
import 'package:memox_v6/core/theme/tokens/app_spacing.dart';
import 'package:memox_v6/presentation/shared/layouts/mx_scaffold.dart';

/// Constrained screen shells (WBS 3.5 child B) — thin preconfigurations of
/// [MxScaffold] that pin each screen archetype to its kit width cap, so
/// feature screens never choose caps or scrolling modes ad hoc (guard
/// `memox.screen_shell.use_mx_scaffold_family`).

/// Lazy list screen shell on the kit list cap.
///
/// Purpose:
/// The frame for dense scrolling lists (library, flashcard list, search
/// results): full-bleed lazy `ListView` with the standard space-3 row
/// separators, page gutter as list padding, centered under the list cap
/// on wide windows.
///
/// Use when:
/// A screen whose body is one scrolling list.
///
/// Do not use when:
/// Mixed card/section bodies (plain `MxScaffold`), forms
/// (`MxFormScaffold`) or study stages (`MxStudyScaffold`).
///
/// Category:
/// layout
///
/// Public API:
/// - itemCount / itemBuilder: lazy list content.
/// - appBar / bottomNav / fab: frame slots (passthrough).
/// - emptyState: rendered instead of the list when `itemCount == 0`.
class MxListScaffold extends StatelessWidget {
  const MxListScaffold({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.appBar,
    this.bottomNav,
    this.fab,
    this.emptyState,
  });

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNav;
  final Widget? fab;
  final Widget? emptyState;

  @override
  Widget build(BuildContext context) {
    final emptyState = this.emptyState;
    final Widget body = itemCount == 0 && emptyState != null
        ? emptyState
        : Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: context.layout.maxWidthFor(ContentSurface.list),
              ),
              child: ListView.separated(
                padding: EdgeInsets.symmetric(
                  horizontal: context.spacing.gutter,
                  vertical: AppSpacing.space4,
                ),
                itemCount: itemCount,
                itemBuilder: itemBuilder,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSpacing.space3),
              ),
            ),
          );

    return MxScaffold(
      appBar: appBar,
      bottomNav: bottomNav,
      fab: fab,
      flush: itemCount != 0 || emptyState == null,
      scrollable: itemCount == 0 && emptyState != null,
      body: body,
    );
  }
}

/// Form screen shell on the kit reading cap.
///
/// Purpose:
/// The frame for field stacks: scrolling body under the reading cap so
/// line lengths stay comfortable, with the keyboard inset honoured by the
/// scaffold resize behavior.
///
/// Use when:
/// Editors and settings-style forms.
///
/// Do not use when:
/// Lists (`MxListScaffold`) or study stages (`MxStudyScaffold`).
///
/// Category:
/// layout
///
/// Public API:
/// - body: the form content (scrolls).
/// - appBar / bottomNav / fab: frame slots (passthrough).
class MxFormScaffold extends StatelessWidget {
  const MxFormScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.bottomNav,
    this.fab,
  });

  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNav;
  final Widget? fab;

  @override
  Widget build(BuildContext context) {
    return MxScaffold(
      appBar: appBar,
      bottomNav: bottomNav,
      fab: fab,
      surface: ContentSurface.reading,
      body: body,
    );
  }
}

/// Study stage shell on the kit study cap.
///
/// Purpose:
/// The frame for learning stages: content constrained to the study cap so
/// prompts never stretch across large windows; the stage composition
/// itself (progress/header/prompt/actions) is owned by the shared study
/// shell (WBS 5.6.4).
///
/// Use when:
/// Any study-session stage screen.
///
/// Do not use when:
/// Non-study screens.
///
/// Category:
/// layout
///
/// Public API:
/// - body: the stage content.
/// - appBar / bottomNav / fab: frame slots (passthrough).
/// - scrollable: default true; stages with fixed compositions opt out.
class MxStudyScaffold extends StatelessWidget {
  const MxStudyScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.bottomNav,
    this.fab,
    this.scrollable = true,
  });

  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNav;
  final Widget? fab;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    return MxScaffold(
      appBar: appBar,
      bottomNav: bottomNav,
      fab: fab,
      surface: ContentSurface.study,
      scrollable: scrollable,
      body: body,
    );
  }
}
