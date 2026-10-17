import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme.dart';
import '../../../core/validators.dart';
import '../../../providers/auth_provider.dart';
import 'reset_password_screen.dart';

/// 1.3 Luxury Password Recovery Screen.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final email = _emailController.text.trim();
    final ok = await auth.requestPasswordReset(email);
    if (!mounted || !ok) return;
    // Email found: step 2, choose a new password.
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ResetPasswordScreen(email: email, token: auth.resetToken!),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Recovery')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: AppTheme.bgCard,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.borderGold),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.goldPrimary.withValues(alpha: 0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.lock_reset_rounded,
                    size: 38,
                    color: AppTheme.goldPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Reset Your Credentials',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter the email of your account, then choose a new password.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
                style: TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Gmail address',
                  hintText: 'name@gmail.com',
                  prefixIcon: Icon(Icons.mail_outline_rounded,
                      color: AppTheme.goldPrimary),
                ),
                validator: Validators.gmail,
              ),
              if (auth.error != null) ...[
                const SizedBox(height: 14),
                Text(
                  auth.error!,
                  style: const TextStyle(color: AppTheme.accentRuby, fontSize: 13),
                ),
              ],
              const SizedBox(height: 28),
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
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black,
                          ),
                        )
                      : const Text(
                          'Continue',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
