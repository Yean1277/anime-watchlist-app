import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'providers/watchlist_provider.dart';
import 'screens/watchlist_screen.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  );

  // Anonymous auth: give this device an account on first launch so RLS-scoped
  // rows have an owner. Existing sessions are restored automatically.
  final auth = Supabase.instance.client.auth;
  if (auth.currentSession == null) {
    await auth.signInAnonymously();
  }

  runApp(const AnimeWatchlistApp());
}

class AnimeWatchlistApp extends StatelessWidget {
  const AnimeWatchlistApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => WatchlistProvider()..load(),
      child: MaterialApp(
        title: 'Anime Watchlist',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        home: const WatchlistScreen(),
      ),
    );
  }
}
