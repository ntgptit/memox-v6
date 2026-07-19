import 'package:memox_v6/app/router/route_params.dart';

/// Canonical route paths. The only place route paths may be written.
abstract final class RoutePaths {
  static const String home = '/';
  static const String firstRunLanding = '/first-run';
  static const String firstRunLanguage = '/first-run/language';
  static const String firstRunDeckSetup = '/first-run/deck';
  static const String library = '/library';

  /// Deck detail path template; build concrete paths with [deckDetail].
  static const String deckDetailPattern = '/deck/:${RouteParams.deckId}';

  static String deckDetail(String deckId) => '/deck/$deckId';
}
