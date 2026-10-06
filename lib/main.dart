import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/stations/views/home_view.dart';

void main() {
  runApp(const IShowerApp());
}

class IShowerApp extends StatelessWidget {
  const IShowerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'iShower MVP',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const HomeView(),
    );
  }
}