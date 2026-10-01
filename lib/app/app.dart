import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import 'routes/routes_application.dart';
import '../core/services/preferences_application_service.dart';
import '../core/services/sse_notifications_service.dart';

class StagiaApp extends StatefulWidget {
  const StagiaApp({super.key});

  @override
  State<StagiaApp> createState() => _StagiaAppState();
}

class _StagiaAppState extends State<StagiaApp> {
  @override
  void initState() {
    super.initState();
    // Démarre l'écoute temps réel en tâche de fond
    SseNotificationsService.instance.demarrer();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<PreferencesApplicationService>.value(
          value: PreferencesApplicationService.instance,
        ),
        ChangeNotifierProvider<SseNotificationsService>.value(
          value: SseNotificationsService.instance,
        ),
      ],
      child: Consumer<PreferencesApplicationService>(
        builder: (context, preferences, _) => MaterialApp(
          title: 'STAGIA',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: preferences.modeSombre
              ? ThemeMode.dark
              : ThemeMode.light,
          initialRoute: RoutesApplication.demarrage,
          onGenerateRoute: RoutesApplication.generer,
        ),
      ),
    );
  }
}

