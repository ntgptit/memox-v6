import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:memox_v6/core/utils/string_utils.dart';
import 'package:memox_v6/domain/language_pair/supported_languages.dart';
import 'package:memox_v6/l10n/generated/app_localizations.dart';
import 'package:memox_v6/presentation/shared/bottom_sheets/mx_sheet.dart';
import 'package:memox_v6/presentation/shared/widgets/inputs/mx_search_field.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_gap.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_icon.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_tappable.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_text.dart';

/// Searchable language picker sheet (WBS 5.1.2).
///
/// Long names stay readable: native name leads, English reference
/// follows, and the distinguishing part never ellipsizes
/// (`create-language-pair.md`). Returns the picked code or null.
Future<String?> showLanguageSelectSheet(
  BuildContext context, {
  required String title,
  String? selected,
}) {
  return showMxSheet<String>(
    context,
    title: title,
    child: _LanguageSelectSheetBody(selected: selected),
  );
}

class _LanguageSelectSheetBody extends HookWidget {
  const _LanguageSelectSheetBody({required this.selected});

  final String? selected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final query = useState('');

    final needle = StringUtils.lowerCased(StringUtils.trimmed(query.value));
    final matches = supportedLanguages.where((language) {
      if (needle.isEmpty) return true;
      final haystack = StringUtils.lowerCased(
        '${language.nativeName} ${language.englishName} ${language.code}',
      );
      return haystack.contains(needle);
    }).toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MxSearchField(
          placeholder: l10n.searchLanguagesHint,
          clearLabel: l10n.searchClearLabel,
          autofocus: false,
          onChanged: (value) => query.value = value,
        ),
        const MxGap.s3(),
        if (matches.isEmpty) ...[
          const MxGap.s4(),
          MxText(
            l10n.noLanguagesFoundMessage,
            role: MxTextRole.body,
            textAlign: TextAlign.center,
          ),
          const MxGap.s4(),
        ],
        for (final language in matches)
          _LanguageRow(
            language: language,
            isSelected: language.code == selected,
          ),
      ],
    );
  }
}

class _LanguageRow extends StatelessWidget {
  const _LanguageRow({required this.language, required this.isSelected});

  final SupportedLanguage language;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return MxTappable(
      onTap: () => Navigator.of(context).pop(language.code),
      semanticLabel: language.englishName,
      child: Row(
        children: [
          const MxGap.s2(),
          const MxIcon(icon: Symbols.language),
          const MxGap.s3(),
          Expanded(
            child: MxText(
              '${language.nativeName} · ${language.englishName}',
              role: MxTextRole.body,
            ),
          ),
          if (isSelected) const MxIcon(icon: Symbols.check),
          const MxGap.s2(),
        ],
      ),
    );
  }
}
