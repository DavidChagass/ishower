import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/models/user_session.dart';
import 'features/auth/services/auth_service.dart';
import 'features/auth/views/auth_view.dart';
import 'features/stations/views/home_view.dart';

void main() {
  runApp(const IShowerApp());
}

class IShowerApp extends StatelessWidget {
  const IShowerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppTheme.themeModeNotifier,
      builder: (context, currentThemeMode, _) {
        return MaterialApp(
          title: 'iShower MVP',
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
              return HomeView(session: session);
            },
          ),
        );
      },
    );
  }
}
