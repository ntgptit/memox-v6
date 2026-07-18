import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:memox_v6/core/utils/string_utils.dart';

/// MemoX search-input hook (WBS 3.3 child B).
///
/// Guard contract (`memox.hooks.search_field_uses_shared_hook`): search
/// surfaces own their controller through this hook so query trimming and
/// clearing behave identically everywhere. Debounce policy arrives with
/// the Search feature wave (WBS 10.x) and will extend this hook
/// additively.
({TextEditingController controller, String query, void Function() clear})
useMxSearchController() {
  final controller = useTextEditingController();
  final query = useState('');
  useEffect(() {
    void onChanged() => query.value = StringUtils.trimmed(controller.text);
    controller.addListener(onChanged);
    return () => controller.removeListener(onChanged);
  }, [controller]);
  return (controller: controller, query: query.value, clear: controller.clear);
}
