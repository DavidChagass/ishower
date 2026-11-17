import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ishower/core/theme/app_theme.dart';
import 'package:ishower/features/auth/services/auth_service.dart';
import 'package:ishower/main.dart';

void main() {
  testWidgets('Smoke test - Driver registration, client tabs without admin switch, light/dark mode and schedule rules', (WidgetTester tester) async {
    AppTheme.themeModeNotifier.value = ThemeMode.dark;
    AuthService().logout();

    await tester.pumpWidget(const IShowerApp());
    await tester.pumpAndSettle();

    expect(find.text('iShower'), findsOneWidget);
    expect(find.text('Criar Conta'), findsOneWidget);

    await tester.tap(find.text('Criar Conta'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('auth_name_field')), 'João Motorista');
    await tester.enterText(find.byKey(const Key('auth_email_field')), 'joao.teste@ishower.com');
    await tester.enterText(find.byKey(const Key('auth_password_field')), '123456');
    await tester.tap(find.text('Criar Conta e Entrar'));
    await tester.pumpAndSettle();

    // Driver should NOT see an Admin/Client Switch
    expect(find.byType(Switch), findsNothing);

    expect(find.text('Chuveiros Próximos'), findsOneWidget);
    expect(find.text('Chuveiros'), findsOneWidget);
    expect(find.text('Mapa'), findsOneWidget);
    expect(find.text('Horários'), findsOneWidget);
    expect(find.text('Ver QR Code'), findsOneWidget);
    expect(find.text('25 min'), findsWidgets);

    // Toggle Light/Dark mode
    expect(find.byIcon(Icons.light_mode_outlined), findsOneWidget);
    await tester.tap(find.byIcon(Icons.light_mode_outlined));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.dark_mode_outlined), findsOneWidget);
    expect(AppTheme.themeModeNotifier.value, ThemeMode.light);

    await tester.tap(find.byIcon(Icons.dark_mode_outlined));
    await tester.pumpAndSettle();
    expect(AppTheme.themeModeNotifier.value, ThemeMode.dark);

    // Navigate to Horários
    await tester.tap(find.byIcon(Icons.schedule_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Tempo limite de banho: 25 minutos'), findsOneWidget);

    // Navigate to Ver QR Code
    await tester.tap(find.byIcon(Icons.qr_code_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Meus Pedidos & QR Code'), findsOneWidget);
  });

  testWidgets('Role-based access in mobile: Gerente Graal only sees Graal and Admin Geral sees all stations', (WidgetTester tester) async {
    AppTheme.themeModeNotifier.value = ThemeMode.dark;
    AuthService().logout();

    await tester.pumpWidget(const IShowerApp());
    await tester.pumpAndSettle();

    // 1. Login as Gerente Graal -> lands directly in AdminView (no Switch)
    await tester.tap(find.text('Gerente Graal'));
    await tester.pumpAndSettle();

    expect(find.byType(Switch), findsNothing);
    expect(find.text('Administração'), findsOneWidget);
    expect(find.text('Recepção do Posto'), findsOneWidget);
    expect(find.text('Ler QR Code (Câmera)'), findsOneWidget);

    // Navigate to Postos Admin tab and verify ONLY Posto Graal is visible
    await tester.tap(find.text('Postos Admin'));
    await tester.pumpAndSettle();
    expect(find.text('Meu Posto Credenciado'), findsOneWidget);
    expect(find.text('Posto Graal - BR 381'), findsOneWidget);
    expect(find.text('Posto Ipiranga Rota 26'), findsNothing);
    expect(find.text('Posto Petrobras - Parada Certa'), findsNothing);

    // 2. Logout and login as Admin Geral -> sees all 3 stations
    await tester.tap(find.byIcon(Icons.logout_outlined));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Admin Geral'));
    await tester.tap(find.text('Admin Geral'));
    await tester.pumpAndSettle();

    expect(find.text('Área do Administrador'), findsOneWidget);
    await tester.tap(find.text('Postos Admin'));
    await tester.pumpAndSettle();
    expect(find.text('Gestão de Postos Credenciados'), findsOneWidget);
    expect(find.text('Posto Graal - BR 381'), findsOneWidget);
    expect(find.text('Posto Ipiranga Rota 26'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(find.text('Posto Petrobras - Parada Certa'), findsOneWidget);
  });
}
