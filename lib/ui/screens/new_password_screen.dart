// lib/ui/screens/new_password_screen.dart
import 'dart:io';

import 'package:flutter/material.dart';
import '../../generated/l10n.dart';
import '../../services/files/gpg_file_store.dart';
import '../../services/storage/gpg_key_storage.dart';
import '../../services/password_directory_prefs.dart';
import '../../services/memory/gpg_key_memory.dart';
import '../../services/crypto/gpg_encryption_service.dart';

class NewPasswordScreen extends StatefulWidget {
  const NewPasswordScreen({super.key});

  @override
  State<NewPasswordScreen> createState() => _NewPasswordScreenState();
}

class _NewPasswordScreenState extends State<NewPasswordScreen> {
  final _nameController = TextEditingController();
  final _contentController = TextEditingController();
  bool _saving = false;

  late final GPGKeyMemory _keyService;
  late final GPGEncryptionService _passwordService;

  @override
  void initState() {
    super.initState();
    _initializeGPG();
  }

  Future<void> _initializeGPG() async {
    final keys = await GPGKeyStorage().loadKeys();
    if (keys['private'] == null || keys['public'] == null || keys['passphrase'] == null) {
      throw Exception('Keys not found');
    }

    _keyService = GPGKeyMemory(
      publicKey: keys['public']!,
      privateKey: keys['private']!,
      passphrase: keys['passphrase']!,
    );


    _passwordService = GPGEncryptionService(keyMemory: _keyService);
  }

  Future<void> _savePassword() async {
    final l10n = S.of(context);
    final name = _nameController.text.trim();
    final content = _contentController.text.trim();

    if (name.isEmpty || content.isEmpty) return;

    setState(() => _saving = true);

    try {
      final encrypted = await _passwordService.encrypt(content);

      final folderPath = await PasswordDirectoryPrefs.load();
      if (folderPath == null) throw Exception('Folder not selected');

      final storeService = GPGFileStore(root:Directory(folderPath));
      final relativePath = '$name.gpg';
      await storeService.writeEncrypted(relativePath, encrypted);

      if (context.mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(l10n.error),
          content: Text(e.toString()),
        ),
      );
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.newPassword)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: l10n.passwordName,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _contentController,
              maxLines: 6,
              decoration: InputDecoration(
                labelText: l10n.passwordContent,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saving ? null : _savePassword,
              child: _saving
                  ? const CircularProgressIndicator()
                  : Text(l10n.save),
            ),
          ],
        ),
      ),
    );
  }
}

