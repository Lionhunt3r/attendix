import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/supabase_config.dart';
import 'core/router/app_router.dart';
import 'core/services/app_update_service.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/toast_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    if (kDebugMode) {
      print('Warning: Could not load .env file: $e');
    }
  }

  // Initialize Supabase
  await SupabaseConfig.initialize();

  runApp(
    const ProviderScope(
      child: AttendixApp(),
    ),
  );
}

/// Main application widget
class AttendixApp extends ConsumerStatefulWidget {
  const AttendixApp({super.key});

  @override
  ConsumerState<AttendixApp> createState() => _AttendixAppState();
}

class _AttendixAppState extends ConsumerState<AttendixApp> {
  @override
  void initState() {
    super.initState();
    // Start update listener (web only)
    if (kIsWeb) {
      ref.read(appUpdateServiceProvider).startListening();
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final updateAvailable = ref.watch(appUpdateAvailableProvider);
    final updateService = ref.read(appUpdateServiceProvider);

    // Show update snackbar when available (only once)
    if (updateAvailable && !updateService.wasDialogShown) {
      updateService.markDialogShown();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showUpdateSnackbar();
        }
      });
    }

    return MaterialApp.router(
      title: 'Attendix',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }

  void _showUpdateSnackbar() {
    ToastHelper.showUpdateAvailable(
      context,
      onUpdate: () {
        ref.read(appUpdateServiceProvider).applyUpdate();
      },
    );
  }
}
