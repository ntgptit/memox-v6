// Custom Flutter bootstrap — its only job is to keep Flutter's service worker
// out of the way of ours (`offline_shell.js`, WBS 5.7.4).
//
// The generated bootstrap passes `serviceWorkerSettings`, and `flutter.js`
// treats that as: register Flutter's worker if a registration already exists,
// otherwise do nothing (a first visit gets no worker at all, which is why
// nothing was cached — `int-95`). With MemoX registering its own shell worker,
// that "already exists" branch fires on the *second* load and Flutter's worker
// takes the scope from ours, so the shell stops being cached and an offline
// start still finds nothing. Two workers, one scope, neither doing the job.
//
// Omitting `serviceWorkerSettings` makes `loadServiceWorker` a no-op, which is
// the whole fix. Flutter's own worker is deprecated and slated for removal
// (flutter/flutter#156910), so this is the direction the framework is going
// anyway — MemoX just needs to get there before its offline story depends on
// something that is being deleted.
{{flutter_js}}
{{flutter_build_config}}

_flutter.loader.load();
