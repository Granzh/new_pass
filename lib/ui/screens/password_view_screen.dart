import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../generated/l10n.dart';
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
    final l10n = S.of(context);
    try {
      final encrypted = await File(filePath).readAsString();

      final gpgStorage = GPGKeyStorage();
      final keys = await gpgStorage.loadKeys();
      if (keys['private'] == null || keys['public'] == null || keys['passphrase'] == null) {
        throw Exception('keys not found');
      }

      final keyService = GPGKeyMemory(
        publicKey: keys['public']!,
        privateKey: keys['private']!,
        passphrase: keys['passphrase']!,
      );


      final passwordService = GPGEncryptionService(keyMemory: keyService);
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
          title: Text(l10n.decryptionError),
          content: Text(e.toString()),
        ),
      );
    }
  }

  void _copyToClipboard(String text) {
    final l10n = S.of(context);
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.copied)),
    );
  }

  Future<void> _deleteFile() async {
    final l10n = S.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.deletePassword),
        content: Text(l10n.deletePasswordMessage),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.delete)),
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
    final l10n = S.of(context);
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
            Text(l10n.password, style: TextStyle(fontWeight: FontWeight.bold)),
            SelectableText(password ?? '', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => _copyToClipboard(password ?? ''),
              icon: const Icon(Icons.copy),
              label: Text(l10n.copy),
            ),
            if (note != null) ...[
              const SizedBox(height: 24),
              Text(l10n.comment, style: TextStyle(fontWeight: FontWeight.bold)),
              SelectableText(note!, style: const TextStyle(fontSize: 16)),
            ]
          ],
        ),
      ),
    );
  }
}