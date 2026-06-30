import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'providers/watchlist_provider.dart';
import 'services/in_memory_watchlist_repository.dart';
import 'services/watchlist_repository.dart';
import 'services/watchlist_service.dart';
import 'screens/watchlist_screen.dart';
import 'theme.dart';

// Optional build-time config (e.g. `flutter build web --dart-define=SUPABASE_URL=...`).
// Takes effect only when not provided via the .env file.
const _defineUrl = String.fromEnvironment('SUPABASE_URL');
const _defineKey = String.fromEnvironment('SUPABASE_ANON_KEY');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final env = await _loadEnv();
  final url = _firstNonEmpty(env['SUPABASE_URL'], _defineUrl);
  final anonKey = _firstNonEmpty(env['SUPABASE_ANON_KEY'], _defineKey);

  final configured = _looksConfigured(url, anonKey);

  late final WatchlistRepository repository;
  if (configured) {
    // Production: real Supabase backend with anonymous auth.
    await Supabase.initialize(url: url, anonKey: anonKey);
    final auth = Supabase.instance.client.auth;
    if (auth.currentSession == null) {
      await auth.signInAnonymously();
    }
    repository = WatchlistService();
  } else {
    // Demo mode: no credentials -> in-memory store so the UI is still browsable.
    repository = InMemoryWatchlistRepository();
  }

  runApp(AnimeWatchlistApp(repository: repository, demoMode: !configured));
}

/// Loads `.env` if present; returns an empty map when it's missing (demo mode).
Future<Map<String, String>> _loadEnv() async {
  try {
    await dotenv.load(fileName: '.env');
    return dotenv.env;
  } catch (_) {
    return const {};
  }
}

String _firstNonEmpty(String? a, String b) =>
    (a != null && a.isNotEmpty) ? a : b;

/// True only when both values are present and not the example placeholders.
bool _looksConfigured(String url, String anonKey) {
  if (url.isEmpty || anonKey.isEmpty) return false;
  if (!url.startsWith('http')) return false;
  if (url.contains('YOUR-') || anonKey.contains('YOUR-')) return false;
  return true;
}

class AnimeWatchlistApp extends StatelessWidget {
  final WatchlistRepository repository;
  final bool demoMode;

  const AnimeWatchlistApp({
    super.key,
    required this.repository,
    required this.demoMode,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) =>
          WatchlistProvider(repository, demoMode: demoMode)..load(),
      child: MaterialApp(
        title: 'Anime Watchlist',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        home: const WatchlistScreen(),
      ),
    );
  }
}
