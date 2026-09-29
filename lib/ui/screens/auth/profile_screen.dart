import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme.dart';
import '../../../data/api/api_client.dart';
import '../../../providers/auth_provider.dart';

/// 1.4 Luxury Profile Management Screen.
/// Displays student identity, profile photo, credentials management,
/// and local network endpoint settings.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _photoUrlController;
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  String _currentServerUrl = '';

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _nameController = TextEditingController(text: user?.fullName ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _photoUrlController = TextEditingController(text: user?.photoUrl ?? '');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AuthProvider>().loadProfile();
      _loadServerUrl();
    });
  }

  Future<void> _loadServerUrl() async {
    final url = await ApiClient.instance.baseUrl;
    if (mounted) setState(() => _currentServerUrl = url);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _photoUrlController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.updateProfile(
      fullName: _nameController.text.trim(),
      email: _emailController.text.trim(),
      photoUrl: _photoUrlController.text.trim(),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? 'Profile updated.' : (auth.error ?? 'Could not update profile.'),
        ),
      ),
    );
  }

  Future<void> _changePassword() async {
    FocusScope.of(context).unfocus();
    final auth = context.read<AuthProvider>();
    final ok = await auth.changePassword(
      currentPassword: _currentPasswordController.text,
      newPassword: _newPasswordController.text,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? 'Security credentials changed successfully.' : (auth.error ?? 'Could not change password.'),
        ),
      ),
    );
    if (ok) {
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
    }
  }

  Future<void> _showServerConfigDialog() async {
    final controller = TextEditingController(text: _currentServerUrl);
    final newUrl = await showDialog<String>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppTheme.borderGold),
        ),
        title: const Row(
          children: [
            Icon(Icons.hub_outlined, color: AppTheme.goldPrimary),
            SizedBox(width: 10),
            Text('Server Endpoint', style: TextStyle(fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Specify host machine IP for mobile testing on same Wi-Fi:',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
              decoration: const InputDecoration(
                hintText: 'http://192.168.8.56:8000/api',
                labelText: 'API Base URL',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.goldPrimary,
              foregroundColor: Colors.black,
            ),
            onPressed: () => Navigator.of(dialogCtx).pop(controller.text.trim()),
            child: const Text('Save & Apply'),
          ),
        ],
      ),
    );

    if (newUrl != null && newUrl.isNotEmpty) {
      await ApiClient.instance.setBaseUrl(newUrl);
      await _loadServerUrl();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Server endpoint saved: $_currentServerUrl'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // -- Luxury Avatar & Identity Header ----------------------------
            Center(
              child: Column(
                children: [
                  Container(
                    width: 92,
                    height: 92,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppTheme.goldGradient,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.goldPrimary.withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(3),
                    child: CircleAvatar(
                      backgroundColor: AppTheme.bgCard,
                      child: Text(
                        (user?.fullName.isNotEmpty ?? false)
                            ? user!.fullName[0].toUpperCase()
                            : 'M',
                        style: const TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.goldPrimary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    user?.fullName ?? 'Student Member',
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.email ?? '',
                    style: const TextStyle(
                      color: AppTheme.goldLight,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.goldPrimary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: AppTheme.goldPrimary.withValues(alpha: 0.3)),
                    ),
                    child: const Text(
                      'PREMIUM MEMBER',
                      style: TextStyle(
                        color: AppTheme.goldPrimary,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // -- Personal Information Card ----------------------------------
            Container(
              padding: const EdgeInsets.all(20),
              decoration: AppTheme.luxuryCardDecoration,
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.badge_outlined,
                            color: AppTheme.goldPrimary, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Personal Details',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      style: const TextStyle(color: AppTheme.textPrimary),
                      decoration: const InputDecoration(
                        labelText: 'Full name',
                        prefixIcon: Icon(Icons.person_outline,
                            color: AppTheme.goldPrimary),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Enter your name.'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _emailController,
                      style: const TextStyle(color: AppTheme.textPrimary),
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.mail_outline,
                            color: AppTheme.goldPrimary),
                      ),
                      validator: (v) => (v == null || !v.contains('@'))
                          ? 'Enter a valid email.'
                          : null,
                    ),
                    const SizedBox(height: 18),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.goldPrimary,
                        foregroundColor: Colors.black,
                        minimumSize: const Size.fromHeight(48),
                      ),
                      onPressed: auth.isLoading ? null : _saveProfile,
                      child: const Text('Save changes'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // -- Security Card ----------------------------------------------
            Container(
              padding: const EdgeInsets.all(20),
              decoration: AppTheme.luxuryCardDecoration,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.shield_outlined,
                          color: AppTheme.goldPrimary, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Security & Credentials',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _currentPasswordController,
                    obscureText: _obscureCurrent,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Current password',
                      prefixIcon: const Icon(Icons.lock_outline,
                          color: AppTheme.goldPrimary),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureCurrent
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: AppTheme.textMuted,
                        ),
                        onPressed: () => setState(
                            () => _obscureCurrent = !_obscureCurrent),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _newPasswordController,
                    obscureText: _obscureNew,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'New password',
                      prefixIcon: const Icon(Icons.vpn_key_outlined,
                          color: AppTheme.goldPrimary),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureNew
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: AppTheme.textMuted,
                        ),
                        onPressed: () =>
                            setState(() => _obscureNew = !_obscureNew),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureNew,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'Confirm new password',
                      prefixIcon: Icon(Icons.lock_reset,
                          color: AppTheme.goldPrimary),
                    ),
                  ),
                  const SizedBox(height: 18),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                    onPressed: auth.isLoading ? null : _changePassword,
                    child: const Text('Update password'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // -- Server Connection Card -------------------------------------
            Container(
              padding: const EdgeInsets.all(20),
              decoration: AppTheme.luxuryCardDecoration,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.wifi_tethering,
                          color: AppTheme.goldPrimary, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Backend Network Connection',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Active API: $_currentServerUrl',
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.settings, size: 18),
                    label: const Text('CONFIGURE HOST IP'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(44),
                    ),
                    onPressed: _showServerConfigDialog,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
