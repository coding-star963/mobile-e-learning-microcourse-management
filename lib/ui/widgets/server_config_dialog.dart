import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../data/api/api_client.dart';

/// Lets the user point the app at the laptop running the Laravel API
/// (e.g. when the Wi-Fi network changes). Returns the saved URL, or null.
/// Used by the profile screen and by long-pressing the logo on the login screen.
Future<String?> showServerConfigDialog(BuildContext context) async {
  final currentUrl = await ApiClient.instance.baseUrl;
  if (!context.mounted) return null;

  final controller = TextEditingController(text: currentUrl);
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

  if (newUrl == null || newUrl.isEmpty) return null;

  await ApiClient.instance.setBaseUrl(newUrl);
  final savedUrl = await ApiClient.instance.baseUrl;
  if (context.mounted) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Server endpoint saved: $savedUrl')));
  }
  return savedUrl;
}
