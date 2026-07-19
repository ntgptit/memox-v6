import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox_v6/core/errors/app_failure.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_banner.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_button.dart';
import 'package:memox_v6/presentation/shared/widgets/mx_progress.dart';

/// The one async-state renderer — the "AppAsyncBuilder" the guard rule
/// `memox.state_management.use_app_async_builder` mandates, carried as
/// `MxAsyncBuilder` per the shared naming contract. Lives in viewmodels
/// because shared widget dirs stay provider-free (`no_app_wiring`).
///
/// Purpose:
/// Feature UI hands an `AsyncValue<T>` here instead of calling `.when`
/// directly, so loading, error, retry and retained-data-on-refresh render
/// identically on every screen and errors always arrive as [AppFailure].
///
/// Use when:
/// Rendering any provider-owned `AsyncValue` in feature or shell UI.
///
/// Do not use when:
/// Rendering plain synchronous state.
///
/// Category:
/// async
///
/// Public API:
/// - value: the async state.
/// - data: builder for the loaded value.
/// - loadingLabel: localized announcement for the default spinner (or pass
///   a custom `loading` builder).
/// - errorTitle: localized title for the default error banner (or pass a
///   custom `error` builder receiving the mapped failure).
/// - onRetry + retryLabel: adds the retry action to the default error
///   surface.
/// - retain: keep showing previous data while refreshing (default true —
///   the retained-composition contract).
///
/// States:
/// data, loading (spinner), refreshing (retained data), error (banner with
/// optional retry).
class MxAsyncBuilder<T> extends StatelessWidget {
  const MxAsyncBuilder({
    super.key,
    required this.value,
    required this.data,
    this.loading,
    this.loadingLabel,
    this.error,
    this.errorTitle,
    this.onRetry,
    this.retryLabel,
    this.retain = true,
  }) : assert(
         loading != null || loadingLabel != null,
         'provide loadingLabel for the default spinner or a loading builder',
       ),
       assert(
         error != null || errorTitle != null,
         'provide errorTitle for the default banner or an error builder',
       ),
       assert(
         onRetry == null || retryLabel != null || error != null,
         'retry on the default surface needs retryLabel',
       );

  final AsyncValue<T> value;
  final Widget Function(BuildContext context, T value) data;
  final Widget Function(BuildContext context)? loading;
  final String? loadingLabel;
  final Widget Function(BuildContext context, AppFailure failure)? error;
  final String? errorTitle;
  final VoidCallback? onRetry;
  final String? retryLabel;
  final bool retain;

  @override
  Widget build(BuildContext context) {
    return value.when(
      skipLoadingOnRefresh: retain,
      data: (loaded) => data(context, loaded),
      loading: () =>
          loading?.call(context) ??
          Center(child: MxProgress.spinner(semanticLabel: loadingLabel ?? '')),
      error: (rawError, stackTrace) {
        final failure = rawError is AppFailure
            ? rawError
            : AppFailure.from(rawError, stackTrace);
        final errorBuilder = error;
        if (errorBuilder != null) return errorBuilder(context, failure);
        final retryLabel = this.retryLabel;
        return MxBanner(
          tone: MxBannerTone.error,
          title: errorTitle ?? '',
          action: onRetry == null || retryLabel == null
              ? null
              : MxButton(
                  onPressed: onRetry,
                  label: retryLabel,
                  variant: MxButtonVariant.ghost,
                  size: MxButtonSize.sm,
                ),
        );
      },
    );
  }
}
