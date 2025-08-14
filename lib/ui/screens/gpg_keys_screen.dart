import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:file_saver/file_saver.dart';

import '../../services/keys/gpg_key_service.dart';
import '../../services/sync/cloud_key_exporter.dart';

/// Screen for managing GPG keys using the *new* GPGKeyService API.
/// Focus: exporting keys to cloud (Google Drive via registered exporter) and to files.
class GpgKeysScreen extends StatefulWidget {
  const GpgKeysScreen({super.key, required this.keyService, this.autoStartExport = false});

  final GPGKeyService keyService;
  final bool autoStartExport;

  @override
  State<GpgKeysScreen> createState() => _GpgKeysScreenState();
}

enum _ExportMode { publicOnly, both }

class _GpgKeysScreenState extends State<GpgKeysScreen> {
  bool _loading = false;
  bool _hasKeys = false;

  @override
  void initState() {
    super.initState();
    _loadState();

    // Optionally kick off export flow right after the first frame
    if (widget.autoStartExport) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        // Ensure keys/service loaded
        if (!_hasKeys) {
          try {
            await widget.keyService.load();
            if (mounted) setState(() => _hasKeys = widget.keyService.hasKeys);
          } catch (_) {}
        }
        if (mounted) await _exportToCloud();
      });
    }
  }

  Future<void> _loadState() async {
    setState(() => _loading = true);
    try {
      await widget.keyService.load();
      setState(() => _hasKeys = widget.keyService.hasKeys);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSnack(String msg) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(msg)),
  );

  void _showError(Object e) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('$e'), backgroundColor: Theme.of(context).colorScheme.error),
  );

  Future<void> _generateKeys() async {
    final res = await showDialog<_GenData>(
      context: context,
      builder: (_) => const _GenerateDialog(),
    );
    if (res == null) return;

    setState(() => _loading = true);
    try {
      await widget.keyService.generate(
        name: res.name,
        email: res.email,
        passphrase: res.passphrase,
      );
      _showSnack('Ключи сгенерированы и сохранены');
      setState(() => _hasKeys = true);
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _exportToFiles() async {
    if (!_hasKeys) {
      _showSnack('Сначала создайте или импортируйте ключи');
      return;
    }

    final includePrivate = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Экспорт в файлы'),
        content: const Text('Экспортировать только публичный ключ или оба?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Только публичный')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Публичный + приватный')),
        ],
      ),
    );
    if (includePrivate == null) return;

    setState(() => _loading = true);
    try {
      final Map<String, Uint8List> files = await widget.keyService.exportAsFiles(
        includePrivate: includePrivate,
      );

      for (final entry in files.entries) {
        // FileSaver: works for mobile/desktop/web
        await FileSaver.instance.saveFile(
          name: entry.key,
          bytes: entry.value,
          // Let FileSaver detect MIME by extension.
        );
      }

      _showSnack(includePrivate
          ? 'Экспортировано два файла: public.asc и private.asc'
          : 'Экспортирован файл: public.asc');
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _exportToCloud() async {
    if (!_hasKeys) {
      _showSnack('Сначала создайте или импортируйте ключи');
      return;
    }

    final exporters = widget.keyService.exporters;
    if (exporters.isEmpty) {
      _showError('Нет доступных провайдеров для экспорта');
      return;
    }

    // 1) choose provider if multiple
    final CloudKeyExporter exporter = exporters.length == 1
        ? exporters.first
        : (await showModalBottomSheet<CloudKeyExporter>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            const Text('Куда экспортировать?', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ...exporters.map(
                  (e) => ListTile(
                leading: const Icon(Icons.cloud_outlined),
                title: Text(e.label),
                subtitle: Text(e.id),
                onTap: () => Navigator.of(ctx).pop(e),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    )) ??
        exporters.first;

    // 2) choose mode (public or public+private)
    final mode = await showModalBottomSheet<_ExportMode>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            const Text('Что экспортировать?', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.vpn_key_outlined),
              title: const Text('Только публичный ключ'),
              onTap: () => Navigator.of(ctx).pop(_ExportMode.publicOnly),
            ),
            ListTile(
              leading: const Icon(Icons.all_inbox_outlined),
              title: const Text('Публичный + приватный'),
              onTap: () => Navigator.of(ctx).pop(_ExportMode.both),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (mode == null) return;

    // Confirm for private export
    if (mode == _ExportMode.both) {
      final sure = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Экспорт приватного ключа'),
          content: const Text(
              'Хранение приватного ключа в облаке потенциально рискованно. Продолжить?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Да, продолжить')),
          ],
        ),
      );
      if (sure != true) return;
    }

    setState(() => _loading = true);
    try {
      final result = await widget.keyService.exportToCloud(
        providerId: exporter.id,
        includePrivate: mode == _ExportMode.both,
        folderName: 'PassAppKeys',
        publicFileName: 'public.asc',
        privateFileName: 'private.asc',
      );

      final link = result.folderUrl?.toString();
      _showSnack(link == null
          ? 'Экспорт завершён: ${exporter.label}'
          : 'Экспорт завершён: ${exporter.label}\nПапка: $link');
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _deleteAll() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Удалить ключи?'),
        content: const Text('Ключи будут удалены из памяти и локального хранилища.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Удалить')),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _loading = true);
    try {
      await widget.keyService.deleteAll();
      _showSnack('Ключи удалены');
      setState(() => _hasKeys = false);
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('GPG ключи'),
        actions: [
          IconButton(
            tooltip: 'Экспорт в облако',
            icon: const Icon(Icons.cloud_upload_outlined),
            onPressed: _loading ? null : _exportToCloud,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: Icon(_hasKeys ? Icons.key_outlined : Icons.key_off_outlined,
                  color: _hasKeys ? theme.colorScheme.primary : theme.disabledColor),
              title: Text(_hasKeys ? 'Ключи готовы' : 'Ключи отсутствуют'),
              subtitle: Text(_hasKeys
                  ? 'Можно экспортировать в файлы или Google Drive'
                  : 'Сгенерируйте новые ключи'),
              trailing: _loading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : null,
            ),
          ),

          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(Icons.build_outlined),
                  title: Text('Управление ключами'),
                ),
                const Divider(height: 0),
                ListTile(
                  leading: const Icon(Icons.autorenew_outlined),
                  title: const Text('Сгенерировать новую пару ключей'),
                  subtitle: const Text('Имя, email, passphrase'),
                  onTap: _loading ? null : _generateKeys,
                ),
                ListTile(
                  leading: const Icon(Icons.cloud_upload_outlined),
                  title: const Text('Экспорт в облако…'),
                  subtitle: Text(widget.keyService.exporters.isEmpty
                      ? 'Нет подключённых провайдеров'
                      : widget.keyService.exporters.map((e) => e.label).join(', ')),
                  onTap: _loading ? null : _exportToCloud,
                ),
                ListTile(
                  leading: const Icon(Icons.file_upload_outlined),
                  title: const Text('Экспорт в файлы…'),
                  subtitle: const Text('public.asc и по желанию private.asc'),
                  onTap: _loading ? null : _exportToFiles,
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.delete_forever_outlined),
                  title: const Text('Удалить все ключи'),
                  textColor: theme.colorScheme.error,
                  iconColor: theme.colorScheme.error,
                  onTap: _loading ? null : _deleteAll,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GenData {
  final String name;
  final String email;
  final String passphrase;
  const _GenData(this.name, this.email, this.passphrase);
}

class _GenerateDialog extends StatefulWidget {
  const _GenerateDialog();

  @override
  State<_GenerateDialog> createState() => _GenerateDialogState();
}

class _GenerateDialogState extends State<_GenerateDialog> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _valid = false;

  @override
  void initState() {
    super.initState();
    _name.addListener(_validate);
    _email.addListener(_validate);
    _pass.addListener(_validate);
  }

  void _validate() {
    final ok = _name.text.trim().isNotEmpty && _email.text.trim().isNotEmpty && _pass.text.isNotEmpty;
    if (ok != _valid) setState(() => _valid = ok);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Создать ключи'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Имя'),
            textInputAction: TextInputAction.next,
          ),
          TextField(
            controller: _email,
            decoration: const InputDecoration(labelText: 'Email'),
            textInputAction: TextInputAction.next,
            keyboardType: TextInputType.emailAddress,
          ),
          TextField(
            controller: _pass,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Passphrase'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
        FilledButton(
          onPressed: _valid
              ? () => Navigator.pop(context, _GenData(_name.text.trim(), _email.text.trim(), _pass.text))
              : null,
          child: const Text('Создать'),
        ),
      ],
    );
  }
}
