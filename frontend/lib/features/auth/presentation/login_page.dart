import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/constants/brand_assets.dart';
import '../../../shared/widgets/brand_logo_image.dart';
import '../application/session_controller.dart';
import '../data/auth_repository.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _rememberMe = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final session = ref.read(sessionControllerProvider);
    _rememberMe = session.rememberMe;
    if (session.email != null) {
      _emailController.text = session.email!;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      await ref.read(sessionControllerProvider.notifier).signIn(
            email: _emailController.text,
            password: _passwordController.text,
            rememberMe: _rememberMe,
          );
      if (!mounted) return;
      context.go('/catalog');
    } on AuthFailure catch (e) {
      _showError(e.message);
    } catch (_) {
      _showError('Bir sorun oluştu. Lütfen tekrar deneyin.');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.critical,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String? _validateEmail(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'E-posta gerekli.';
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(v)) return 'Geçerli bir e-posta girin.';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Şifre gerekli.';
    if (value.length < 4) return 'Şifre çok kısa.';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final viewInsetsBottom = MediaQuery.viewInsetsOf(context).bottom;
            final usableHeight = constraints.maxHeight;

            // Logo ile kart aras\u0131 telefon boyutuna g\u00f6re hafif\u00e7e b\u00fcy\u00fcs\u00fcn
            // ama \u00e7ok a\u00e7\u0131lmas\u0131n.
            final headerToCardGap = (usableHeight * 0.035).clamp(16.0, 28.0);

            return SingleChildScrollView(
              keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                bottom: viewInsetsBottom,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: usableHeight - viewInsetsBottom,
                ),
                child: Align(
                  // Blo\u011fu sayfan\u0131n biraz \u00fcst\u00fcne hizala. Y de\u011feri ne kadar
                  // negatif olursa o kadar yukar\u0131 \u00e7\u0131kar.
                  alignment: const Alignment(0, -0.35),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const _BrandHeader(),
                        SizedBox(height: headerToCardGap),
                        _LoginCard(
                          formKey: _formKey,
                          emailController: _emailController,
                          passwordController: _passwordController,
                          obscurePassword: _obscurePassword,
                          rememberMe: _rememberMe,
                          isSubmitting: _isSubmitting,
                          validateEmail: _validateEmail,
                          validatePassword: _validatePassword,
                          onTogglePassword: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                          onToggleRemember: () => setState(
                            () => _rememberMe = !_rememberMe,
                          ),
                          onSubmit: _submit,
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'GÜVENLİ B2B PORTAL',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AppColors.textMuted,
                            fontSize: 12,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _LoginCard extends StatelessWidget {
  const _LoginCard({
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.obscurePassword,
    required this.rememberMe,
    required this.isSubmitting,
    required this.validateEmail,
    required this.validatePassword,
    required this.onTogglePassword,
    required this.onToggleRemember,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final bool rememberMe;
  final bool isSubmitting;
  final String? Function(String?) validateEmail;
  final String? Function(String?) validatePassword;
  final VoidCallback onTogglePassword;
  final VoidCallback onToggleRemember;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Tekrar hoş geldiniz',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              const Text(
                'Giriş bilgilerinizle hesabınıza erişin.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textMuted),
              ),
              const SizedBox(height: 22),
              TextFormField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                validator: validateEmail,
                decoration: const InputDecoration(
                  labelText: 'Kurumsal E-posta',
                  prefixIcon: Icon(Icons.mail_outline),
                  hintText: 'isim@sirket.com',
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: passwordController,
                obscureText: obscurePassword,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                validator: validatePassword,
                onFieldSubmitted: (_) => onSubmit(),
                decoration: InputDecoration(
                  labelText: 'Şifre',
                  prefixIcon: const Icon(Icons.lock_outline),
                  hintText: '••••••••',
                  suffixIcon: IconButton(
                    tooltip: obscurePassword
                        ? 'Şifreyi göster'
                        : 'Şifreyi gizle',
                    onPressed: onTogglePassword,
                    icon: Icon(
                      obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: onToggleRemember,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Checkbox(
                              value: rememberMe,
                              onChanged: (_) => onToggleRemember(),
                              visualDensity: VisualDensity.compact,
                            ),
                            const Text('Beni hatırla'),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: isSubmitting ? null : onSubmit,
                icon: isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.arrow_forward_rounded),
                label: Text(
                  isSubmitting ? 'Giriş yapılıyor...' : 'Giriş Yap',
                ),
              ),
              const SizedBox(height: 18),
              const _InfoBox(),
            ],
          ),
        ),
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Center(
          child: Transform.translate(
            offset: const Offset(-10, 0),
            child: const BrandLogoImage(
              assetPath: BrandAssets.textileFlowLogo,
              fallbackLabel: 'TextileFlow',
              height: 96,
              maxWidth: 280,
            ),
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'B2B Sipariş Portalı',
          style: TextStyle(
            color: AppColors.textMuted,
            fontWeight: FontWeight.w600,
            fontSize: 13,
            letterSpacing: 0.4,
          ),
        ),
      ],
    );
  }
}

class _InfoBox extends StatelessWidget {
  const _InfoBox();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Padding(
        padding: EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(Icons.shield_outlined, color: AppColors.textMuted),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Doğrulanmış iş ortakları için güvenli giriş.',
                style: TextStyle(color: AppColors.textMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

