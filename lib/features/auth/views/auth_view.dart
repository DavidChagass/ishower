import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/custom_primary_button.dart';
import '../../stations/services/api_service.dart';
import '../services/auth_service.dart';

class AuthView extends StatefulWidget {
  const AuthView({super.key});

  @override
  State<AuthView> createState() => _AuthViewState();
}

class _AuthViewState extends State<AuthView> {
  final AuthService _authService = AuthService();

  bool _isRegisterMode = false;
  bool _isLoading = false;
  String? _errorMessage;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_isRegisterMode) {
        await _authService.register(
          name: _nameController.text,
          email: _emailController.text,
          password: _passwordController.text,
        );
      } else {
        await _authService.login(
          identifier: _emailController.text,
          password: _passwordController.text,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _quickLogin(String email) async {
    _emailController.text = email;
    _passwordController.text = '123456';
    setState(() => _isRegisterMode = false);
    await _submit();
  }

  Future<void> _openServerSettingsDialog() async {
    final urlController = TextEditingController(text: ApiService.baseUrl);
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Configurar Servidor API'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Informe o endereço do backend iShower na rede local (ex: http://192.168.0.10:3000/api/v1).',
              style: TextStyle(fontSize: 12.5),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: urlController,
              decoration: const InputDecoration(
                labelText: 'URL da API',
                hintText: 'http://localhost:3000/api/v1',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              urlController.text = ApiService.defaultBaseUrl;
            },
            child: const Text('Padrão'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
    if (saved == true) {
      await ApiService.setCustomBaseUrl(urlController.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Servidor atualizado: ${ApiService.baseUrl}')),
        );
      }
    }
    urlController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.cardBackground : AppColors.lightCard;
    final textPrimary = isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;
    final accentBlue = isDark ? AppColors.buttonSky : AppColors.primary;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: 8,
              right: 12,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                      color: accentBlue,
                    ),
                    tooltip: isDark ? 'Ativar Modo Claro' : 'Ativar Modo Escuro',
                    onPressed: AppTheme.toggleTheme,
                  ),
                  IconButton(
                    icon: Icon(Icons.dns_outlined, color: textSecondary),
                    tooltip: 'Configurar servidor da API',
                    onPressed: _openServerSettingsDialog,
                  ),
                ],
              ),
            ),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 52, 24, 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            gradient: AppColors.blueGradient,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.28),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.water_drop_outlined,
                            color: Colors.white,
                            size: 36,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'iShower',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.6,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Rede inteligente de banhos em rodovias',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13.5, color: textSecondary),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isDark ? AppColors.border : AppColors.lightBorder,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: ChoiceChip(
                                    label: const Center(child: Text('Entrar')),
                                    selected: !_isRegisterMode,
                                    onSelected: (_) => setState(() {
                                      _isRegisterMode = false;
                                      _errorMessage = null;
                                    }),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: ChoiceChip(
                                    label: const Center(child: Text('Criar Conta')),
                                    selected: _isRegisterMode,
                                    onSelected: (_) => setState(() {
                                      _isRegisterMode = true;
                                      _errorMessage = null;
                                    }),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            if (_errorMessage != null) ...[
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.statusBusy.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: AppColors.statusBusy.withValues(alpha: 0.35),
                                  ),
                                ),
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(
                                    color: AppColors.statusBusy,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                            ],
                            if (_isRegisterMode) ...[
                              TextField(
                                key: const Key('auth_name_field'),
                                controller: _nameController,
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                  labelText: 'Nome / Usuário',
                                  prefixIcon: Icon(Icons.person_outline),
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                            TextField(
                              key: const Key('auth_email_field'),
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              decoration: InputDecoration(
                                labelText: _isRegisterMode
                                    ? 'E-mail'
                                    : 'E-mail ou Usuário',
                                prefixIcon: const Icon(Icons.email_outlined),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              key: const Key('auth_password_field'),
                              controller: _passwordController,
                              obscureText: true,
                              onSubmitted: (_) => _submit(),
                              decoration: const InputDecoration(
                                labelText: 'Senha',
                                prefixIcon: Icon(Icons.lock_outline),
                              ),
                            ),
                            const SizedBox(height: 18),
                            CustomPrimaryButton(
                              text: _isLoading
                                  ? 'Aguarde...'
                                  : (_isRegisterMode
                                      ? 'Criar Conta e Entrar'
                                      : 'Entrar'),
                              icon: _isRegisterMode
                                  ? Icons.person_add_alt_1
                                  : Icons.login,
                              onPressed: _isLoading ? null : _submit,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),
                      Text(
                        'Acesso rápido para demonstração (senha: 123456):',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: textSecondary),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ActionChip(
                            avatar: const Icon(Icons.local_shipping_outlined, size: 16),
                            label: const Text('Motorista'),
                            onPressed: () => _quickLogin('motorista@ishower.com'),
                          ),
                          ActionChip(
                            avatar: const Icon(Icons.storefront_outlined, size: 16),
                            label: const Text('Gerente Graal'),
                            onPressed: () => _quickLogin('gerente.graal@ishower.com'),
                          ),
                          ActionChip(
                            avatar: const Icon(Icons.qr_code_scanner_outlined, size: 16),
                            label: const Text('Operador Graal'),
                            onPressed: () => _quickLogin('operador.graal@ishower.com'),
                          ),
                          ActionChip(
                            avatar: const Icon(Icons.admin_panel_settings_outlined, size: 16),
                            label: const Text('Admin Geral'),
                            onPressed: () => _quickLogin('admin@ishower.com'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
