import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme.dart';
import '../../../providers/auth_provider.dart';

/// 1.3 Password Recovery — second step: choose a new password for the
/// email verified on the previous screen.
class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key, required this.email, required this.token});

  final String email;

  /// Short-lived token returned by the server when the email was verified.
  final String token;

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.resetPassword(
      email: widget.email,
      token: widget.token,
      newPassword: _passwordController.text,
    );
    if (!mounted || !ok) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Password reset. You can now log in.')),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('New Password')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.lock_reset_rounded, size: 48, color: AppTheme.goldPrimary),
              const SizedBox(height: 16),
              Text(
                'Set a new password',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Choose a new password for ${widget.email}.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 28),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscure,
                style: TextStyle(color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  labelText: 'New password',
                  prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppTheme.goldPrimary),
                  suffixIcon: IconButton(
                    icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                validator: (v) => (v == null || v.length < 8) ? 'Use at least 8 characters.' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _confirmController,
                obscureText: _obscure,
                style: TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Confirm new password',
                  prefixIcon: Icon(Icons.lock_outline_rounded, color: AppTheme.goldPrimary),
                ),
                validator: (v) => v != _passwordController.text ? 'Passwords do not match.' : null,
              ),
              if (auth.error != null) ...[
                const SizedBox(height: 14),
                Text(auth.error!, style: const TextStyle(color: AppTheme.accentRuby, fontSize: 13)),
              ],
              const SizedBox(height: 28),
              FilledButton(
                onPressed: auth.isLoading ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.goldPrimary,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Reset password', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
