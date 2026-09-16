import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

class ChessGoApp extends StatelessWidget {
  const ChessGoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'ChessGo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: appRouter,
    );
  }
}
