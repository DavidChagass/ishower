import 'package:flutter/material.dart';

class AppColors {
  // Cores Dark Mode (Essência Dark MVP)
  static const Color background = Color(0xFF121212);
  static const Color cardBackground = Color(0xFF1E1E1E);
  static const Color surface = Color(0xFF1E1E1E);
  static const Color cardSurface = Color(0xFF262626);
  static const Color border = Color(0xFF2E2E2E);

  // Cores Light Mode (Adaptado mantendo as cores dos postos/marca)
  static const Color lightBackground = Color(0xFFF6F8FC);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightSurface = Color(0xFFEEF2F6);
  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color lightTextPrimary = Color(0xFF1E293B);
  static const Color lightTextSecondary = Color(0xFF64748B);

  // Paleta de Azuis Principais e Dourado (#160AFA, #0A96FA, #FAB60A)
  static const Color primaryDark = Color(0xFF160AFA); // #160AFA (Azul Escuro / Royal Profundo)
  static const Color primary = Color(0xFF0A96FA);     // #0A96FA (Azul Claro / Azure Vibrante)
  static const Color accentGold = Color(0xFFFAB60A);  // #FAB60A (Dourado / Âmbar para Contraste)

  // Novas Cores para Botões (#00FAE8, #00BBFA, #006DFA) - Muito mais vivas!
  static const Color buttonCyan = Color(0xFF00FAE8);  // #00FAE8 (Aqua / Ciano Neon)
  static const Color buttonSky = Color(0xFF00BBFA);   // #00BBFA (Azul Céu Límpido)
  static const Color buttonBlue = Color(0xFF006DFA);  // #006DFA (Azul Elétrico Vibrante)

  // Aliases
  static const Color primaryLight = Color(0xFF0A96FA);
  static const Color secondary = Color(0xFFFAB60A);
  static const Color accent = Color(0xFFFAB60A);

  // Tipografia Dark (padrão)
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Colors.grey;
  static const Color textMuted = Color(0xFF9E9E9E);

  // Status de disponibilidade
  static const Color statusAvailable = Colors.greenAccent;
  static const Color statusAvailableBackground = Color(0x3369F0AE); // 20% opacity greenAccent
  static const Color statusBusy = Colors.redAccent;
  static const Color statusBusyBackground = Color(0x33FF5252); // 20% opacity redAccent
  static const Color statusCleaning = Color(0xFFFAB60A);
  static const Color statusCleaningBackground = Color(0x33FAB60A);

  // Gradiente vibrante dos botões (#006DFA -> #00BBFA)
  static const LinearGradient buttonGradient = LinearGradient(
    colors: [Color(0xFF006DFA), Color(0xFF00BBFA)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // Gradiente com os azuis da marca (#160AFA e #0A96FA)
  static const LinearGradient blueGradient = LinearGradient(
    colors: [Color(0xFF160AFA), Color(0xFF0A96FA)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient primaryGradient = buttonGradient;
}
