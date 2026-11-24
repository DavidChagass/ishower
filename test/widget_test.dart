import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ishower/core/theme/app_theme.dart';
import 'package:ishower/features/auth/services/auth_service.dart';
import 'package:ishower/main.dart';

void main() {
  testWidgets(
    'Smoke test - Default dark mode, light mode toggle, driver registration, wallet PIX top-up and no duplicate AppBars',
    (WidgetTester tester) async {
      AppTheme.themeModeNotifier.value = ThemeMode.dark;
      AuthService().logout();

      await tester.pumpWidget(const IShowerApp());
      await tester.pumpAndSettle();

      // Default theme is Dark Mode
      expect(AppTheme.themeModeNotifier.value, ThemeMode.dark);
      expect(find.text('iShower'), findsOneWidget);
      expect(find.text('Criar Conta'), findsOneWidget);

      await tester.tap(find.text('Criar Conta'));
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byKey(const Key('auth_name_field')), 'João Motorista');
      await tester.enterText(
          find.byKey(const Key('auth_email_field')), 'joao.teste@ishower.com');
      await tester.enterText(
          find.byKey(const Key('auth_password_field')), '123456');
      await tester.tap(find.text('Criar Conta e Entrar'));
      await tester.pumpAndSettle();

      // Driver should NOT see an Admin/Client Switch
      expect(find.byType(Switch), findsNothing);

      // 5 tabs for driver (Chuveiros, Mapa, Horários, QR Code, Carteira)
      expect(find.text('Chuveiros Próximos'), findsOneWidget);
      expect(find.text('Chuveiros'), findsOneWidget);
      expect(find.text('Mapa'), findsOneWidget);
      expect(find.text('Horários'), findsOneWidget);
      expect(find.text('QR Code'), findsOneWidget);
      expect(find.text('Carteira'), findsOneWidget);
      expect(find.text('25 min'), findsWidgets);

      // Toggle Light Mode and back to Dark Mode
      expect(find.byIcon(Icons.light_mode_outlined), findsOneWidget);
      await tester.tap(find.byIcon(Icons.light_mode_outlined));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.dark_mode_outlined), findsOneWidget);
      expect(AppTheme.themeModeNotifier.value, ThemeMode.light);

      await tester.tap(find.byIcon(Icons.dark_mode_outlined));
      await tester.pumpAndSettle();
      expect(AppTheme.themeModeNotifier.value, ThemeMode.dark);

      // Navigate to Horários -> should have ONLY 1 AppBar (no duplicate!)
      await tester.tap(find.byIcon(Icons.schedule_outlined));
      await tester.pumpAndSettle();
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('Tempo limite de banho: 25 minutos'), findsOneWidget);

      // Navigate to QR Code -> should have ONLY 1 AppBar
      await tester.tap(find.byIcon(Icons.qr_code_outlined));
      await tester.pumpAndSettle();
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('Meus QR Codes'), findsOneWidget);

      // Navigate to Carteira -> verify balance and mock PIX top-up
      await tester.tap(find.byIcon(Icons.account_balance_wallet_outlined));
      await tester.pumpAndSettle();
      expect(find.text('Saldo Carteira iShower'), findsOneWidget);
      expect(find.text('+ R\$ 50'), findsOneWidget);
      await tester.tap(find.text('+ R\$ 50'));
      await tester.pumpAndSettle();
      expect(AuthService().currentSession?.balance, greaterThanOrEqualTo(200.0));

      // Regression test: Make a purchase and then logout cleanly
      await tester.tap(find.byIcon(Icons.shower_outlined));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Reservar').first);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Confirmar e Gerar Código'));
      await tester.tap(find.text('Confirmar e Gerar Código'));
      await tester.pumpAndSettle();
      // Close QR bottom sheet -> returns to HomeView
      await tester.tap(find.text('Fechar'));
      await tester.pumpAndSettle();

      // Click Logout button -> must return cleanly to AuthView
      await tester.tap(find.byIcon(Icons.logout_outlined));
      await tester.pumpAndSettle();
      expect(AuthService().currentSession, isNull);
      expect(find.text('Entrar'), findsWidgets);
    },
  );

  testWidgets(
    'Role-based access in mobile: Operador has 2 tabs only, Gerente Graal sees only Graal, Admin Geral sees all 3 stations',
    (WidgetTester tester) async {
      AppTheme.themeModeNotifier.value = ThemeMode.dark;
      AuthService().logout();

      await tester.pumpWidget(const IShowerApp());
      await tester.pumpAndSettle();

      // 1. Login as Operador Graal -> NO Postos Admin tab!
      await tester.ensureVisible(find.text('Operador Graal'));
      await tester.tap(find.text('Operador Graal'));
      await tester.pumpAndSettle();

      expect(find.byType(Switch), findsNothing);
      expect(find.text('Leitor QR'), findsOneWidget);
      expect(find.text('Reservas'), findsOneWidget);
      expect(find.text('Postos Admin'), findsNothing);

      // Logout -> Login as Gerente Graal -> sees Postos Admin with ONLY Posto Graal
      await tester.tap(find.byIcon(Icons.logout_outlined));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Gerente Graal'));
      await tester.tap(find.text('Gerente Graal'));
      await tester.pumpAndSettle();

      expect(find.text('Administração'), findsOneWidget);
      expect(find.text('Recepção do Posto'), findsOneWidget);
      expect(find.text('Postos Admin'), findsOneWidget);

      await tester.tap(find.text('Postos Admin'));
      await tester.pumpAndSettle();
      expect(find.text('Meu Posto Credenciado'), findsOneWidget);
      expect(find.text('Posto Graal - BR 381'), findsOneWidget);
      expect(find.text('Posto Ipiranga Rota 26'), findsNothing);
      expect(find.text('Posto Petrobras - Parada Certa'), findsNothing);

      // Logout -> Login as Admin Geral -> sees all 3 stations
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
    },
  );
}
