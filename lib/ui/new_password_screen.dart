// lib/ui/screens/new_password_screen.dart
import 'dart:io';

import 'package:flutter/material.dart';
import '../services/PasswordStoreService.dart';
import '../services/folder_storage_service.dart';
import '../services/gpg_key_service.dart';
import '../services/io_file_service.dart';

class NewPasswordScreen extends StatefulWidget {
  const NewPasswordScreen({super.key});

  @override
  State<NewPasswordScreen> createState() => _NewPasswordScreenState();
}

class _NewPasswordScreenState extends State<NewPasswordScreen> {
  final _nameController = TextEditingController();
  final _contentController = TextEditingController();
  bool _saving = false;

  late final GPGKeyService _keyService;
  late final PasswordService _passwordService;

  @override
  void initState() {
    super.initState();
    _initializeGPG();
  }

  Future<void> _initializeGPG() async {
    final keys = await GPGStorageService().loadKeys();
    if (keys['private'] == null || keys['public'] == null || keys['passphrase'] == null) {
      throw Exception('GPG ключи не найдены');
    }

    _keyService = GPGKeyService();
    await _keyService.loadKeys(
      privateKey: keys['private']!,
      publicKey: keys['public']!,
      passphrase: keys['passphrase']!,
    );

    _passwordService = PasswordService(_keyService);
  }

  Future<void> _savePassword() async {
    final name = _nameController.text.trim();
    final content = _contentController.text.trim();

    if (name.isEmpty || content.isEmpty) return;

    setState(() => _saving = true);

    try {
      final encrypted = await _passwordService.encryptPassword(content);

      final folderPath = await FolderStorageService().getPath();
      if (folderPath == null) throw Exception('Папка не выбрана');

      final storeService = PasswordStoreService(Directory(folderPath));
      final relativePath = '$name.gpg';
      await storeService.writeEncryptedFile(relativePath, encrypted);

      if (context.mounted) {
        Navigator.pop(context); // вернуться к списку паролей
      }
    } catch (e) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Ошибка'),
          content: Text(e.toString()),
        ),
      );
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Новый пароль')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Имя (например: github/account)',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _contentController,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: 'Содержимое (первая строка — пароль)',
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saving ? null : _savePassword,
              child: _saving
                  ? const CircularProgressIndicator()
                  : const Text('Сохранить'),
            ),
          ],
        ),
      ),
    );
  }
}

