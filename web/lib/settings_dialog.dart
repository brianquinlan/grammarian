import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:grammarian_web/grammarian_client.dart';
import 'package:grammarian_web/main.dart';
import 'package:grammarian_web/models.dart';
import 'package:http/http.dart' as http;

class SettingsDialog extends StatefulWidget {
  const SettingsDialog({super.key});

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  late final GrammarianClient _client;
  UserSettings? _settings;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _client = GrammarianClient(client: http.Client());
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        _client.authToken = await user.getIdToken();
      }
      final settings = await _client.getSettings();
      if (mounted) {
        setState(() {
          _settings = settings;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateSettings(UserSettings newSettings) async {
    setState(() {
      _settings = newSettings;
    });
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        _client.authToken = await user.getIdToken();
      }
      await _client.updateSettings(newSettings);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save settings: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surfaceCard,
      title: const Text(
        'User Settings',
        style: TextStyle(color: AppColors.textWhite),
      ),
      content: SizedBox(
        width: 400,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? Text(_error!, style: const TextStyle(color: Colors.red))
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SwitchListTile(
                    title: const Text(
                      'Geek Mode',
                      style: TextStyle(color: AppColors.textWhite),
                    ),
                    subtitle: const Text(
                      'Show advanced usage statistics',
                      style: TextStyle(color: AppColors.textGray),
                    ),
                    value: _settings?.geekMode ?? false,
                    onChanged: (value) {
                      _updateSettings(UserSettings(geekMode: value));
                    },
                    activeColor: AppColors.primary,
                  ),
                ],
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'Close',
            style: TextStyle(color: AppColors.textGray),
          ),
        ),
      ],
    );
  }
}
