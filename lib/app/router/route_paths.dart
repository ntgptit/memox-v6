import 'package:memox_v6/app/router/route_params.dart';

/// Canonical route paths. The only place route paths may be written.
abstract final class RoutePaths {
  static const String home = '/';
  static const String firstRunLanding = '/first-run';
  static const String firstRunLanguage = '/first-run/language';
  static const String firstRunDeckSetup = '/first-run/deck';
  static const String library = '/library';
  static const String stats = '/stats';
  static const String profile = '/profile';

  /// Deck detail path template; build concrete paths with [deckDetail].
  static const String deckDetailPattern = '/deck/:${RouteParams.deckId}';

  static String deckDetail(String deckId) => '/deck/$deckId';

  /// Card Editor path template for creating in a deck.
  static const String newCardPattern = '/deck/:${RouteParams.deckId}/new-card';

  static String newCard(String deckId) => '/deck/$deckId/new-card';

  /// The active study session (WBS 5.6). Top-level, full-screen: it covers the
  /// tab bar and shows the current stage's mode screen.
  static const String study = '/study';
}
