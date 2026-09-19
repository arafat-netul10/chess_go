import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chess_go/ui/features/game/view_models/game_state_notifier.dart';
import 'config/app_routes.dart';
import 'data/services/supabase_service.dart';
import 'ui/core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase if configured (runs offline-first if credentials not set)
  await SupabaseService.initialize();

  runApp(
    const ProviderScope(
      child: ChessGoApp(),
    ),
  );
}

class ChessGoApp extends ConsumerWidget {
  const ChessGoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'ChessGo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: appRouter,
    );
  }
}
