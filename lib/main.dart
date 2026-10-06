import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const IShowerApp());
}

class IShowerApp extends StatelessWidget {
  const IShowerApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'iShower MVP',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.blueAccent,
        scaffoldBackgroundColor: const Color(0xFF121212), // Fundo escuro padrão
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF121212),
          elevation: 0,
        ),
        colorScheme: const ColorScheme.dark(
          primary: Colors.blueAccent,
          secondary: Colors.blueAccent,
        ),
      ),
      home: HomeScreen(),
    );
  }
}