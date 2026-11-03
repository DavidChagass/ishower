import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ishower/core/theme/app_theme.dart';
import 'package:ishower/main.dart';

void main() {
  testWidgets('Smoke test - App loads, displays tabs, toggles light/dark mode, and validates schedule rules', (WidgetTester tester) async {
    // Reset theme mode to dark initially
    AppTheme.themeModeNotifier.value = ThemeMode.dark;

    // Build our app and trigger frames
    await tester.pumpWidget(const IShowerApp());
    await tester.pumpAndSettle();

    // Verify app title and navigation items in bottom bar
    expect(find.text('Chuveiros Próximos'), findsOneWidget);
    expect(find.text('Chuveiros'), findsOneWidget);
    expect(find.text('Mapa'), findsOneWidget);
    expect(find.text('Horários'), findsOneWidget);
    expect(find.text('Ver QR Code'), findsOneWidget);

    // Verify 25 min limit badge on station cards
    expect(find.text('25 min'), findsWidgets);

    // Verify theme toggle button exists and toggles to Light Mode
    expect(find.byIcon(Icons.light_mode_outlined), findsOneWidget);
    await tester.tap(find.byIcon(Icons.light_mode_outlined));
    await tester.pumpAndSettle();

    // After toggle, the icon changes to dark_mode_outlined (indicating app is in light mode)
    expect(find.byIcon(Icons.dark_mode_outlined), findsOneWidget);
    expect(AppTheme.themeModeNotifier.value, ThemeMode.light);

    // Toggle back to Dark Mode
    await tester.tap(find.byIcon(Icons.dark_mode_outlined));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.light_mode_outlined), findsOneWidget);
    expect(AppTheme.themeModeNotifier.value, ThemeMode.dark);

    // Verify navigating to Horários tab via bottom navigation
    await tester.tap(find.byIcon(Icons.schedule_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Tempo limite de banho: 25 minutos'), findsOneWidget);
    expect(find.text('Horários de Banho'), findsWidgets);

    // Verify navigating to Ver QR Code tab via bottom navigation
    await tester.tap(find.byIcon(Icons.qr_code_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Meus Pedidos & QR Code'), findsOneWidget);
    expect(find.text('Ver QR Code'), findsWidgets);
  });
}
