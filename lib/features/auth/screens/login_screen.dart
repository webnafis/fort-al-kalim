import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/router/app_router.dart';
import '../../../data/services/auth_service.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey    = GlobalKey<FormState>();
  final _emailCtrl  = TextEditingController();
  final _passCtrl   = TextEditingController();
  bool _isLogin     = true;   // toggle login / register
  bool _loading     = false;
  bool _obscure     = true;
  String? _errorMsg;
  final _nameCtrl   = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() { _loading = true; _errorMsg = null; });
    try {
      final user = await ref.read(authServiceProvider).signInWithGoogle();
      if (user != null && mounted) context.go(Routes.home);
    } catch (e) {
      setState(() { _errorMsg = e.toString(); });
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  Future<void> _handleEmailAuth() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _errorMsg = null; });
    try {
      final svc = ref.read(authServiceProvider);
      if (_isLogin) {
        await svc.signInWithEmail(_emailCtrl.text.trim(), _passCtrl.text);
      } else {
        await svc.registerWithEmail(
          _emailCtrl.text.trim(), _passCtrl.text, _nameCtrl.text.trim(),
        );
      }
      if (mounted) context.go(Routes.home);
    } catch (e) {
      setState(() { _errorMsg = e.toString(); });
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              // Header
              Center(
                child: Column(
                  children: [
                    Text(
                      'قلعة الكليم',
                      style: TextStyle(
                        fontFamily: 'Amiri',
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.gold,
                        shadows: [Shadow(color: AppTheme.gold.withOpacity(0.4), blurRadius: 20)],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isLogin ? 'Welcome back, warrior.' : 'Join the battle.',
                      style: const TextStyle(
                        fontSize: 15, color: AppTheme.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),

              // Google Sign-In button
              _GoogleSignInButton(loading: _loading, onTap: _handleGoogleSignIn),
              const SizedBox(height: 24),

              // Divider
              Row(children: [
                const Expanded(child: Divider(color: AppTheme.borderColor)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text('or', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                ),
                const Expanded(child: Divider(color: AppTheme.borderColor)),
              ]),
              const SizedBox(height: 24),

              // Email / Password Form
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    if (!_isLogin) ...[
                      _buildTextField(
                        controller: _nameCtrl,
                        label: 'Display Name',
                        icon: Icons.person_outline,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Enter your name' : null,
                      ),
                      const SizedBox(height: 16),
                    ],
                    _buildTextField(
                      controller: _emailCtrl,
                      label: 'Email',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) => (v == null || !v.contains('@'))
                          ? 'Enter a valid email' : null,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _passCtrl,
                      label: 'Password',
                      icon: Icons.lock_outline,
                      obscure: _obscure,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscure ? Icons.visibility_off : Icons.visibility,
                          color: AppTheme.textSecondary, size: 20,
                        ),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                      validator: (v) => (v == null || v.length < 6)
                          ? 'Password must be 6+ characters' : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Error message
              if (_errorMsg != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.redFortDim,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.redFort.withOpacity(0.3)),
                  ),
                  child: Text(
                    _errorMsg!,
                    style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                  ),
                ),
              ],
              const SizedBox(height: 24),

              // Submit button
              ElevatedButton(
                onPressed: _loading ? null : _handleEmailAuth,
                child: _loading
                    ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                    : Text(_isLogin ? 'Enter the Fort' : 'Create Account'),
              ),
              const SizedBox(height: 20),

              // Toggle login/register
              Center(
                child: GestureDetector(
                  onTap: () => setState(() {
                    _isLogin = !_isLogin;
                    _errorMsg = null;
                  }),
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                      children: [
                        TextSpan(text: _isLogin
                            ? "New warrior? " : "Already have an account? "),
                        TextSpan(
                          text: _isLogin ? 'Create Account' : 'Sign In',
                          style: const TextStyle(
                            color: AppTheme.gold, fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscure = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller:   controller,
      obscureText:  obscure,
      keyboardType: keyboardType,
      validator:    validator,
      style: const TextStyle(color: AppTheme.textPrimary),
      decoration: InputDecoration(
        labelText:   label,
        prefixIcon:  Icon(icon, color: AppTheme.textSecondary, size: 20),
        suffixIcon:  suffixIcon,
      ),
    );
  }
}

// ── Google Sign-In Button ─────────────────────────────────────────
class _GoogleSignInButton extends StatelessWidget {
  final bool loading;
  final VoidCallback onTap;
  const _GoogleSignInButton({required this.loading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Google "G" logo in colour
            Container(
              width: 24, height: 24,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Center(
                child: Text(
                  'G',
                  style: TextStyle(
                    color: Color(0xFF4285F4),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Continue with Google',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
