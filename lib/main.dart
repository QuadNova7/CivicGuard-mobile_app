import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';

import 'core/services/local_cache_service.dart';
import 'core/network/api_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final savedIp = await LocalCacheService.instance.getBaseIp();
  if (savedIp != null && savedIp.isNotEmpty) {
    ApiConfig.setBaseIp(savedIp);
  }
  
  runApp(const CivicGuardApp());
}

class CivicGuardApp extends StatelessWidget {
  const CivicGuardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'CivicGuard',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: appRouter,
    );
  }
}
