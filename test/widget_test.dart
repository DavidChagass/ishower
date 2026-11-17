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

  testWidgets('Admin switch toggles AdminView and validates order code displaying contracted extras', (WidgetTester tester) async {
    AppTheme.themeModeNotifier.value = ThemeMode.dark;

    await tester.pumpWidget(const IShowerApp());
    await tester.pumpAndSettle();

    // Toggle Admin Switch in top-left AppBar
    expect(find.byType(Switch), findsOneWidget);
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    // Verify Admin View is active with 3 admin pages in bottom bar and Test Mock Toggler
    expect(find.text('Administração'), findsOneWidget);
    expect(find.text('Área do Administrador'), findsOneWidget);
    expect(find.text('Gerar Pedido e QR Code Único (Teste)'), findsOneWidget);
    expect(find.byKey(const Key('admin_test_mock_switch')), findsOneWidget);
    expect(find.text('Ler QR Code (Câmera)'), findsOneWidget);
    expect(find.text('Leitor QR'), findsOneWidget);
    expect(find.text('Reservas'), findsOneWidget);
    expect(find.text('Postos Admin'), findsOneWidget);

    // Navigate to Reservas admin tab and back
    await tester.tap(find.text('Reservas'));
    await tester.pumpAndSettle();
    expect(find.text('Reservas & Histórico de Leituras'), findsOneWidget);

    // Navigate to Postos Admin tab and back
    await tester.tap(find.text('Postos Admin'));
    await tester.pumpAndSettle();
    expect(find.text('Gestão de Postos Credenciados'), findsOneWidget);

    await tester.tap(find.text('Leitor QR'));
    await tester.pumpAndSettle();

    // Enter initial order code 749281 and validate
    await tester.enterText(find.byType(TextField), '749281');
    await tester.tap(find.text('Validar Código'));
    await tester.pumpAndSettle();

    // Verify validation dialog shows order confirmed and contracted extras
    expect(find.text('Pedido Validado!'), findsOneWidget);
    expect(find.text('Código: 749281'), findsOneWidget);
    expect(find.text('• Toalha'), findsOneWidget);
    expect(find.text('• Sabonete'), findsOneWidget);

    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    // Verify status in this app is now JÁ LIDO and can be reset via Resetar QR Único
    expect(find.text('Status neste app: JÁ LIDO (#749281)'), findsOneWidget);
    await tester.tap(find.text('Resetar QR Único'));
    await tester.pumpAndSettle();
    expect(find.text('Status neste app: ATIVO (#749281)'), findsOneWidget);
  });
}
