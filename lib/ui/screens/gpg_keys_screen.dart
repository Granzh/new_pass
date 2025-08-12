import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';

import '../../services/keys/gpg_key_service.dart';

class GpgKeysScreen extends StatefulWidget {
  const GpgKeysScreen({super.key, required this.keyService});

  final GPGKeyService keyService;

  @override
  State<GpgKeysScreen> createState() => _GpgKeysScreenState();
}

class _GpgKeysScreenState extends State<GpgKeysScreen> {
  bool _loading = true;
  bool _hasKeys = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final ok = await widget.keyService.loadFromStorage();
      setState(() {
        _hasKeys = ok || widget.keyService.hasKeys;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      _showError(e);
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  void _showError(Object e) {
    _showSnack('Ошибка: $e');
  }

  Future<void> _onGenerate() async {
    final res = await showDialog<_GenKeysResult>(
      context: context,
      builder: (_) => const _GenerateKeysDialog(),
    );
    if (res == null) return;
    try {
      setState(() => _loading = true);
      await widget.keyService.generate(
        name: res.name,
        email: res.email,
        passphrase: res.passphrase,
      );
      setState(() {
        _hasKeys = true;
        _loading = false;
      });
      _showSnack('Ключи сгенерированы и сохранены');
    } catch (e) {
      setState(() => _loading = false);
      _showError(e);
    }
  }

  Future<void> _onImport() async {
    final choice = await showModalBottomSheet<_ImportMode>(
      context: context,
      showDragHandle: true,
      builder: (_) => const _ImportPickerSheet(),
    );
    if (choice == null) return;

    String? publicKey;
    String? privateKey;
    String? passphrase;

    try {
      switch (choice) {
        case _ImportMode.files:
          final result = await FilePicker.platform.pickFiles(allowMultiple: true);
          if (result == null) return;
          for (final f in result.files) {
            final text = await File(f.path!).readAsString();
            if (text.contains('BEGIN PGP PUBLIC KEY BLOCK')) publicKey = text;
            if (text.contains('BEGIN PGP PRIVATE KEY BLOCK')) privateKey = text;
          }
          passphrase = await _askPassphrase();
          break;
        case _ImportMode.clipboard:
          final text = await Clipboard.getData(Clipboard.kTextPlain);
          final value = text?.text ?? '';
          if (value.contains('BEGIN PGP PUBLIC KEY BLOCK')) publicKey = value;
          if (value.contains('BEGIN PGP PRIVATE KEY BLOCK')) privateKey = value;
          passphrase = await _askPassphrase();
          break;
        case _ImportMode.pasteBoth:
          final res = await showDialog<_PasteBothResult>(
            context: context,
            builder: (_) => const _PasteBothDialog(),
          );
          if (res == null) return;
          publicKey = res.publicKey.trim();
          privateKey = res.privateKey.trim();
          passphrase = res.passphrase;
          break;
      }

      if (publicKey == null || privateKey == null) {
        _showSnack('Не нашли оба ключа. Убедись, что выбраны public и private .asc');
        return;
      }

      setState(() => _loading = true);
      await widget.keyService.importArmored(
        publicKey: publicKey,
        privateKey: privateKey,
        passphrase: passphrase,
      );
      setState(() {
        _hasKeys = true;
        _loading = false;
      });
      _showSnack('Ключи импортированы');
    } catch (e) {
      setState(() => _loading = false);
      _showError(e);
    }
  }

  Future<void> _onExport({required bool privateKey}) async {
    try {
      setState(() => _loading = true);
      final data = privateKey
          ? await widget.keyService.exportPrivate()
          : await widget.keyService.exportPublic();
      setState(() => _loading = false);
      if (data == null || data.isEmpty) {
        _showSnack('Ключ не найден');
        return;
      }

      final extName = privateKey ? 'private_key' : 'public_key';
      await FileSaver.instance.saveFile(
        name: extName,
        bytes: utf8.encode(data),
        fileExtension: 'asc',
        mimeType: MimeType.text,
      );
      _showSnack('Сохранено как $extName.asc');
    } catch (e) {
      setState(() => _loading = false);
      _showError(e);
    }
  }

  Future<void> _onDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Удалить ключи?'),
        content: const Text('Действие необратимо. Убедись, что у тебя есть бэкап приватного ключа.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Удалить')),
        ],
      ),
    );
    if (ok != true) return;

    try {
      setState(() => _loading = true);
      await widget.keyService.deleteAll();
      setState(() {
        _hasKeys = false;
        _loading = false;
      });
      _showSnack('Ключи удалены');
    } catch (e) {
      setState(() => _loading = false);
      _showError(e);
    }
  }

  Future<String> _askPassphrase() async {
    final res = await showDialog<String>(
      context: context,
      builder: (_) => const _PassphraseDialog(),
    );
    return res ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('GPG ключи')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(_hasKeys ? Icons.verified : Icons.error_outline),
                const SizedBox(width: 8),
                Text(_hasKeys ? 'Ключи настроены' : 'Ключи не найдены'),
                const Spacer(),
                IconButton(onPressed: _init, icon: const Icon(Icons.refresh)),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _ActionCard(
                  title: 'Импортировать',
                  subtitle: 'Из файлов .asc, буфера или вставкой',
                  icon: Icons.download,
                  onTap: _onImport,
                ),
                _ActionCard(
                  title: 'Экспортировать (public)',
                  subtitle: 'Сохранить public_key.asc',
                  icon: Icons.upload_file,
                  onTap: () => _onExport(privateKey: false),
                  enabled: _hasKeys,
                ),
                _ActionCard(
                  title: 'Экспортировать (private)',
                  subtitle: 'Сохранить private_key.asc',
                  icon: Icons.lock_outline,
                  onTap: () => _onExport(privateKey: true),
                  enabled: _hasKeys,
                ),
                _ActionCard(
                  title: 'Сгенерировать',
                  subtitle: 'Новая пара ключей',
                  icon: Icons.key,
                  onTap: _onGenerate,
                ),
                _ActionCard(
                  title: 'Удалить',
                  subtitle: 'Очистить ключи',
                  icon: Icons.delete_outline,
                  onTap: _onDelete,
                  enabled: _hasKeys,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.enabled = true,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final card = Card(
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: 260,
            child: Row(
              children: [
                Icon(icon, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return Opacity(opacity: enabled ? 1 : 0.5, child: card);
  }
}

// ======= dialogs & sheets =======

enum _ImportMode { files, clipboard, pasteBoth }

class _ImportPickerSheet extends StatelessWidget {
  const _ImportPickerSheet();
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.folder_open),
            title: const Text('Из файлов (.asc)'),
            onTap: () => Navigator.pop(context, _ImportMode.files),
          ),
          ListTile(
            leading: const Icon(Icons.paste),
            title: const Text('Из буфера обмена (один ключ)'),
            subtitle: const Text('Скопируй public или private и вставь'),
            onTap: () => Navigator.pop(context, _ImportMode.clipboard),
          ),
          ListTile(
            leading: const Icon(Icons.note_alt_outlined),
            title: const Text('Вставить оба ключа вручную'),
            onTap: () => Navigator.pop(context, _ImportMode.pasteBoth),
          ),
        ],
      ),
    );
  }
}

class _PassphraseDialog extends StatefulWidget {
  const _PassphraseDialog();
  @override
  State<_PassphraseDialog> createState() => _PassphraseDialogState();
}

class _PassphraseDialogState extends State<_PassphraseDialog> {
  final ctrl = TextEditingController();
  bool hidden = true;
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Passphrase (если есть)'),
      content: TextField(
        controller: ctrl,
        obscureText: hidden,
        decoration: InputDecoration(
          hintText: 'Введите passphrase',
          suffixIcon: IconButton(
            icon: Icon(hidden ? Icons.visibility : Icons.visibility_off),
            onPressed: () => setState(() => hidden = !hidden),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, ''), child: const Text('Без пароля')),
        FilledButton(onPressed: () => Navigator.pop(context, ctrl.text), child: const Text('ОК')),
      ],
    );
  }
}

class _GenerateKeysDialog extends StatefulWidget {
  const _GenerateKeysDialog();
  @override
  State<_GenerateKeysDialog> createState() => _GenerateKeysDialogState();
}

class _GenerateKeysDialogState extends State<_GenerateKeysDialog> {
  final name = TextEditingController();
  final email = TextEditingController();
  final pass = TextEditingController();
  bool hidden = true;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Сгенерировать ключи'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Имя (UID)')
            ),
            const SizedBox(height: 8),
            TextField(
                controller: email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email')
            ),
            const SizedBox(height: 8),
            TextField(
              controller: pass,
              obscureText: hidden,
              decoration: InputDecoration(
                labelText: 'Passphrase',
                suffixIcon: IconButton(
                  icon: Icon(hidden ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => hidden = !hidden),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
        FilledButton(
          onPressed: () {
            if (name.text.trim().isEmpty || email.text.trim().isEmpty) return;
            Navigator.pop(context, _GenKeysResult(
              name: name.text.trim(),
              email: email.text.trim(),
              passphrase: pass.text,
            ));
          },
          child: const Text('Создать'),
        ),
      ],
    );
  }
}

class _GenKeysResult {
  final String name;
  final String email;
  final String passphrase;
  const _GenKeysResult({required this.name, required this.email, required this.passphrase});
}

class _PasteBothDialog extends StatefulWidget {
  const _PasteBothDialog();
  @override
  State<_PasteBothDialog> createState() => _PasteBothDialogState();
}

class _PasteBothDialogState extends State<_PasteBothDialog> {
  final pub = TextEditingController();
  final priv = TextEditingController();
  final pass = TextEditingController();
  bool hidden = true;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Вставь оба ключа'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: pub,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: 'PUBLIC KEY (-----BEGIN PGP PUBLIC KEY BLOCK-----)',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: priv,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: 'PRIVATE KEY (-----BEGIN PGP PRIVATE KEY BLOCK-----)',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: pass,
              obscureText: hidden,
              decoration: InputDecoration(
                labelText: 'Passphrase',
                suffixIcon: IconButton(
                  icon: Icon(hidden ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => hidden = !hidden),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
        FilledButton(
          onPressed: () {
            if (pub.text.contains('BEGIN PGP PUBLIC KEY') &&
                priv.text.contains('BEGIN PGP PRIVATE KEY')) {
              Navigator.pop(context, _PasteBothResult(
                publicKey: pub.text,
                privateKey: priv.text,
                passphrase: pass.text,
              ));
            }
          },
          child: const Text('Импортировать'),
        ),
      ],
    );
  }
}

class _PasteBothResult {
  final String publicKey;
  final String privateKey;
  final String passphrase;
  const _PasteBothResult({
    required this.publicKey,
    required this.privateKey,
    required this.passphrase,
  });
}