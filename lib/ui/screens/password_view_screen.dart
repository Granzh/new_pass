import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/memory/gpg_key_memory.dart';
import '../../services/storage/gpg_key_storage.dart';
import '../../services/crypto/gpg_encryption_service.dart';

class PasswordViewScreen extends StatefulWidget {
  const PasswordViewScreen({super.key});

  @override
  State<PasswordViewScreen> createState() => _PasswordViewScreenState();
}

class _PasswordViewScreenState extends State<PasswordViewScreen> {
  late String filePath;
  String? password;
  String? note;
  bool loading = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    filePath = ModalRoute.of(context)!.settings.arguments as String;
    _loadPassword();
  }

  Future<void> _loadPassword() async {
    try {
      final encrypted = await File(filePath).readAsString();

      final gpgStorage = GPGKeyStorage();
      final keys = await gpgStorage.loadKeys();
      if (keys['private'] == null || keys['public'] == null || keys['passphrase'] == null) {
        throw Exception('Ключи не найдены');
      }

      final keyService = GPGKeyMemory(
        publicKey: keys['public']!,
        privateKey: keys['private']!,
        passphrase: keys['passphrase']!,
      );


      final passwordService = GPGEncryptionService(keyService);
      final decrypted = await passwordService.decrypt(encrypted);

      final lines = decrypted.split('\n');
      setState(() {
        password = lines.first;
        note = lines.length > 1 ? lines.sublist(1).join('\n') : null;
        loading = false;
      });
    } catch (e) {
      setState(() {
        loading = false;
      });
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Ошибка расшифровки'),
          content: Text(e.toString()),
        ),
      );
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Пароль скопирован')),
    );
  }

  Future<void> _deleteFile() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Удалить пароль?'),
        content: const Text('Это действие необратимо.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Удалить')),
        ],
      ),
    );

    if (confirm == true) {
      await File(filePath).delete();
      if (context.mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fileName = filePath.split(Platform.pathSeparator).last.replaceAll('.gpg', '');

    return Scaffold(
      appBar: AppBar(
        title: Text(fileName),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _deleteFile,
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Пароль:', style: TextStyle(fontWeight: FontWeight.bold)),
            SelectableText(password ?? '', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => _copyToClipboard(password ?? ''),
              icon: const Icon(Icons.copy),
              label: const Text('Скопировать'),
            ),
            if (note != null) ...[
              const SizedBox(height: 24),
              const Text('Комментарий:', style: TextStyle(fontWeight: FontWeight.bold)),
              SelectableText(note!, style: const TextStyle(fontSize: 16)),
            ]
          ],
        ),
      ),
    );
  }
}