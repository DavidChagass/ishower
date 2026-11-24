import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/models/user_session.dart';
import 'features/auth/services/auth_service.dart';
import 'features/auth/views/auth_view.dart';
import 'features/stations/services/api_service.dart';
import 'features/stations/views/home_view.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const IShowerApp());
}

class IShowerApp extends StatefulWidget {
  const IShowerApp({super.key});

  @override
  State<IShowerApp> createState() => _IShowerAppState();
}

class _IShowerAppState extends State<IShowerApp> {
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await ApiService.init();
    if (AuthService().currentSession == null) {
      await AuthService().restoreSession();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppTheme.themeModeNotifier,
      builder: (context, currentThemeMode, _) {
        return MaterialApp(
          title: 'iShower',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: currentThemeMode,
          home: ValueListenableBuilder<UserSession?>(
            valueListenable: AuthService().sessionNotifier,
            builder: (context, session, _) {
              if (session == null) {
                return const AuthView();
              }
              return HomeView(
                key: ValueKey(session.userId),
                session: session,
              );
            },
          ),
        );
      },
    );
  }
}
