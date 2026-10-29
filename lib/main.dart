import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'config/app_config.dart';
import 'config/routes.dart';
import 'config/theme.dart';
import 'providers/auth_provider.dart';
import 'providers/listing_provider.dart';
import 'providers/theme_provider.dart';
import 'services/supabase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize configuration
  await AppConfig.initialize();
  
  // Initialize Supabase
  if (AppConfig.supabaseUrl.isNotEmpty) {
    await SupabaseService.initialize();
  }
  
  runApp(const SellScribeApp());
}

class SellScribeApp extends StatefulWidget {
  const SellScribeApp({super.key});

  @override
  State<SellScribeApp> createState() => _SellScribeAppState();
}

class _SellScribeAppState extends State<SellScribeApp> {
  GoRouter? _router;
  bool? _routerIsAuthenticated;

  // A new router restarts navigation, so only build one when the auth state flips.
  // Rebuilding it on every theme or profile change sent the user back to the start.
  GoRouter _routerFor(bool isAuthenticated) {
    if (_router == null || _routerIsAuthenticated != isAuthenticated) {
      _router = AppRoutes.createRouter(isAuthenticated);
      _routerIsAuthenticated = isAuthenticated;
    }
    return _router!;
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ListingProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer2<AuthProvider, ThemeProvider>(
        builder: (context, authProvider, themeProvider, _) {
          final router = _routerFor(authProvider.isAuthenticated);

          return MaterialApp.router(
            title: AppConfig.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.materialThemeMode,
            routerConfig: router,
          );
        },
      ),
    );
  }
}
