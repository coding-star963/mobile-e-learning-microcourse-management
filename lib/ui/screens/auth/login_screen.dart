import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants.dart';
import '../../../core/theme.dart';
import '../../../core/validators.dart';
import '../../../providers/auth_provider.dart';
import '../../widgets/server_config_dialog.dart';

/// 1.1 Luxury Login Screen.
/// Provides secure credential authentication without any demo account hints.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    await auth.login(_emailController.text.trim(), _passwordController.text);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF141C2E), Color(0xFF090D16)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Brand Emblem (long-press to change the server address)
                    Center(
                      child: GestureDetector(
                        onLongPress: () => showServerConfigDialog(context),
                        child: Container(
                          width: 88,
                          height: 88,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppTheme.goldGradient,
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.goldPrimary.withValues(
                                  alpha: 0.35,
                                ),
                                blurRadius: 30,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppTheme.bgDark,
                            ),
                            child: const Icon(
                              Icons.auto_stories,
                              size: 38,
                              color: AppTheme.goldPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),

                    Text(
                      AppConstants.appName.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.0,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'PREMIUM EXECUTIVE LEARNING',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppTheme.goldLight,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.8,
                      ),
                    ),
                    const SizedBox(height: 36),

                    // Email Field
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      style: const TextStyle(color: AppTheme.textPrimary),
                      decoration: const InputDecoration(
                        labelText: 'Gmail address',
                        hintText: 'name@gmail.com',
                        prefixIcon: Icon(
                          Icons.mail_outline_rounded,
                          color: AppTheme.goldPrimary,
                        ),
                      ),
                      validator: Validators.gmail,
                    ),
                    const SizedBox(height: 18),

                    // Password Field
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submit(),
                      style: const TextStyle(color: AppTheme.textPrimary),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(
                          Icons.lock_outline_rounded,
                          color: AppTheme.goldPrimary,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: AppTheme.textMuted,
                          ),
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                        ),
                      ),
                      validator: (value) => (value == null || value.isEmpty)
                          ? 'Enter your password.'
                          : null,
                    ),

                    // Error banner
                    AnimatedSize(
                      duration: const Duration(milliseconds: 200),
                      alignment: Alignment.topCenter,
                      child: auth.error != null
                          ? Container(
                              margin: const EdgeInsets.only(top: 16),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppTheme.accentRuby.withValues(
                                  alpha: 0.15,
                                ),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: AppTheme.accentRuby.withValues(
                                    alpha: 0.4,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.error_outline,
                                    size: 18,
                                    color: AppTheme.accentRuby,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      auth.error!,
                                      style: const TextStyle(
                                        color: AppTheme.textPrimary,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : const SizedBox(width: double.infinity),
                    ),

                    const SizedBox(height: 24),

                    // FilledButton with 'Log in' label for widget tests + luxury theme
                    FilledButton(
                      onPressed: auth.isLoading ? null : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.goldPrimary,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: auth.isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.black,
                              ),
                            )
                          : const Text(
                              'Log in',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                                letterSpacing: 0.8,
                              ),
                            ),
                    ),
                    const SizedBox(height: 12),

                    // Forgot Password
                    TextButton(
                      onPressed: auth.isLoading
                          ? null
                          : () => Navigator.of(
                              context,
                            ).pushNamed('/forgot-password'),
                      child: const Text(
                        'Forgot password?',
                        style: TextStyle(
                          color: AppTheme.goldLight,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    // Student self-registration (Gmail only)
                    TextButton(
                      onPressed: auth.isLoading
                          ? null
                          : () => Navigator.of(context).pushNamed('/register'),
                      child: const Text(
                        "New student? Create an account",
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
