import 'package:flutter/material.dart';
import 'package:memox_v6/core/theme/extensions/app_theme_context.dart';
import 'package:memox_v6/core/utils/string_utils.dart';

/// Semantic text role from the kit type scale (WBS 2.6 table).
enum MxTextRole {
  display,
  headline,
  title,
  subtitle,
  bodyLarge,
  body,
  caption,
  overline,
}

/// Kit line-height tokens (`--memox-line-height-*`) for copy whose spec
/// calls out a reading rhythm (e.g. landing body uses `relaxed`).
enum MxLineHeight { none, tight, snug, normal, relaxed }

/// Semantic text for feature UI.
///
/// Purpose:
/// Renders copy through the kit type-scale roles so the same UI intent
/// resolves to the same style on every screen; feature code never picks
/// Material text-theme roles or raw `TextStyle`s.
///
/// Use when:
/// Any user-facing text inside feature or shared surfaces.
///
/// Do not use when:
/// A component spec fixes its own text treatment — the owning `Mx*`
/// component applies it internally.
///
/// Category:
/// display
///
/// Public API:
/// - text: the copy to render (localized by the caller).
/// - role: one of the eight kit type-scale roles (default body).
/// - color: overrides the role's default token color.
/// - maxLines: passthrough to [Text].
/// - overflow: passthrough to [Text].
/// - textAlign: passthrough to [Text].
/// - semanticsLabel: passthrough to [Text].
///
/// Variants:
/// The eight [MxTextRole]s. Caption and overline default to the secondary
/// text color; overline uppercases its content (kit "caps").
class MxText extends StatelessWidget {
  const MxText(
    this.text, {
    super.key,
    this.role = MxTextRole.body,
    this.color,
    this.lineHeight,
    this.maxLines,
    this.overflow,
    this.textAlign,
    this.semanticsLabel,
  });

  final String text;
  final MxTextRole role;

  /// Overrides the role's default color (body roles: `colors.text`;
  /// caption/overline: `colors.textSecondary`).
  final Color? color;

  /// Applies a kit line-height token; null keeps the font's own metrics.
  final MxLineHeight? lineHeight;

  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign? textAlign;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final styles = context.textStyles;
    final style = switch (role) {
      MxTextRole.display => styles.display,
      MxTextRole.headline => styles.headline,
      MxTextRole.title => styles.title,
      MxTextRole.subtitle => styles.subtitle,
      MxTextRole.bodyLarge => styles.bodyLarge,
      MxTextRole.body => styles.body,
      MxTextRole.caption => styles.caption,
      MxTextRole.overline => styles.overline,
    };
    final defaultColor =
        role == MxTextRole.caption || role == MxTextRole.overline
        ? context.colors.textSecondary
        : context.colors.text;
    final height = switch (lineHeight) {
      null => null,
      MxLineHeight.none => styles.lineHeightNone,
      MxLineHeight.tight => styles.lineHeightTight,
      MxLineHeight.snug => styles.lineHeightSnug,
      MxLineHeight.normal => styles.lineHeightNormal,
      MxLineHeight.relaxed => styles.lineHeightRelaxed,
    };
    return Text(
      role == MxTextRole.overline ? StringUtils.upperCased(text) : text,
      style: style.copyWith(color: color ?? defaultColor, height: height),
      maxLines: maxLines,
      overflow: overflow,
      textAlign: textAlign,
      semanticsLabel: semanticsLabel,
    );
  }
}
