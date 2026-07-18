import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:memox_v6/core/utils/string_utils.dart';

/// MemoX text-input hooks (WBS 3.3 child B).
///
/// Guard contract (`memox.hooks.text_controller_requires_mx_hook`): every
/// presentation consumer owns `TextEditingController`s through these
/// `useMx*` hooks — never directly — so lifecycle, trimming and submit
/// semantics stay consistent. Hooks are presentation-only.

/// Owns a [TextEditingController] and rebuilds with its current [value].
({TextEditingController controller, String value}) useMxTextValue({
  String initial = '',
}) {
  final controller = useTextEditingController(text: initial);
  final value = useState(initial);
  useEffect(() {
    void onChanged() => value.value = controller.text;
    controller.addListener(onChanged);
    return () => controller.removeListener(onChanged);
  }, [controller]);
  return (controller: controller, value: value.value);
}

/// [useMxTextValue] plus the derived single-field submit state:
/// [canSubmit] is true only when the trimmed value is non-empty.
({TextEditingController controller, String value, bool canSubmit})
useMxTextSubmitState({String initial = ''}) {
  final text = useMxTextValue(initial: initial);
  return (
    controller: text.controller,
    value: text.value,
    canSubmit: StringUtils.trimmed(text.value).isNotEmpty,
  );
}
