// lib/ui/screens/password_list_screen.dart
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:flutter/material.dart';
import 'package:new_pass/services/sync/google_drive_key_exporter.dart';

import '../../generated/l10n.dart';
import '../../models/password_entry.dart';
import '../../services/keys/gpg_key_service.dart';
import '../../services/password_directory_prefs.dart';
import '../../utils/file_utils.dart';

import 'dart:ui' show FontFeature;
import 'package:flutter/material.dart';

import 'gpg_keys_screen.dart';


class PasswordEntry {
  final String name;
  final String fullPath;
  final bool isFolder;
  final List<PasswordEntry> children;

  const PasswordEntry({
    required this.name,
    required this.fullPath,
    required this.isFolder,
    this.children = const [],
  });
}

class PasswordListScreen extends StatefulWidget {
  final GPGKeyService keyService;
  const PasswordListScreen({super.key, required this.keyService});

  @override
  State<PasswordListScreen> createState() => _PasswordListScreenState();
}

class _PasswordListScreenState extends State<PasswordListScreen> {
  PasswordEntry? _root;
  bool _loading = true;
  String _query = '';
  bool _searchFocused = false;

  @override
  void initState() {
    super.initState();
    _loadTree();
  }

  Future<void> _loadTree() async {
    setState(() => _loading = true);

    try {
      final folderPath = await PasswordDirectoryPrefs.load();
      if (folderPath == null) {
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/select-folder');
        }
        return;
      }

      final root = Directory(folderPath);
      if (!await root.exists()) {
        throw Exception('Папка не существует: $folderPath');
      }

      final entities = await root
          .list(recursive: true, followLinks: false)
          .where((e) => e is File && e.path.toLowerCase().endsWith('.gpg'))
          .toList();

      PasswordEntry buildTree() {
        final Map<String, Map> folders = {};
        final List<Map<String, dynamic>> leaves = [];

        for (final e in entities) {
          final file = e as File;
          final rel = file.path.substring(root.path.length).replaceFirst(RegExp(r'^[\/\\]'), '');
          final parts = rel.split(RegExp(r'[\/\\]'));

          final fileName = parts.removeLast();
          Map node = folders;
          String accPath = root.path;
          for (final part in parts) {
            accPath = p.join(accPath, part);
            node = node.putIfAbsent(part, () => <String, dynamic>{}) as Map;
            node['__path'] ??= accPath;
          }
          leaves.add({
            'name': fileName.replaceAll('.gpg', ''),
            'fullPath': file.path,
            'parent': parts.isEmpty ? null : parts.join('/'),
          });
        }

        PasswordEntry buildNode(String name, Map nodeMap) {
          final String fullPath = (nodeMap['__path'] as String?) ?? root.path;
          final children = <PasswordEntry>[];

          for (final entry in nodeMap.entries) {
            if (entry.key == '__path') continue;
            children.add(buildNode(entry.key, entry.value as Map));
          }

          for (final f in leaves.where((m) => m['parent'] == null && name == 'root' ||
              (m['parent'] != null && p.join(root.path, m['parent']) == fullPath))) {
            children.add(PasswordEntry(
              name: f['name'] as String,
              fullPath: f['fullPath'] as String,
              isFolder: false,
            ));
          }

          children.sort((a, b) {
            if (a.isFolder != b.isFolder) return a.isFolder ? -1 : 1;
            return a.name.toLowerCase().compareTo(b.name.toLowerCase());
          });

          return PasswordEntry(
            name: name == 'root' ? p.basename(root.path) : name,
            fullPath: fullPath,
            isFolder: true,
            children: children,
          );
        }

        final rootMap = <String, dynamic>{'__path': root.path, ...folders};
        return buildNode('root', rootMap);
      }

      setState(() {
        _root = buildTree();
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка загрузки: $e')),
      );
    }
  }

  void _onAddPassword() {
    Navigator.pushNamed(context, '/password/new');
  }

  void _onOpenEntry(PasswordEntry entry) {
    Navigator.pushNamed(
      context,
      '/password/view',
      arguments: entry.fullPath,
    );
  }

  List<PasswordEntry> _filter(List<PasswordEntry> items) {
    if (_query.trim().isEmpty) return items;
    final q = _query.toLowerCase();

    bool matches(PasswordEntry e) => e.name.toLowerCase().contains(q);

    List<PasswordEntry> walk(List<PasswordEntry> list) {
      final result = <PasswordEntry>[];
      for (final e in list) {
        if (e.isFolder) {
          final children = walk(e.children);
          if (matches(e) || children.isNotEmpty) {
            result.add(PasswordEntry(
              name: e.name,
              fullPath: e.fullPath,
              isFolder: true,
              children: children,
            ));
          }
        } else {
          if (matches(e)) result.add(e);
        }
      }
      return result;
    }

    return walk(items);
  }

  Widget _buildFolder(PasswordEntry folder) {
    // Прячем системный divider, делаем ExpansionTile более «карточным»
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: Card(
        margin: EdgeInsets.zero,
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          childrenPadding: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          leading: const Icon(Icons.folder_outlined),
          title: Text(folder.name, style: const TextStyle(fontWeight: FontWeight.w600)),
          children: folder.children.map(_buildEntry).toList(),
        ),
      ),
    );
  }

  Widget _buildFile(PasswordEntry file) {
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        leading: const Icon(Icons.vpn_key_outlined),
        title: Hero(
          tag: 'title:${file.fullPath}',
          flightShuttleBuilder: (flightContext, animation, flightDirection, fromHeroContext, toHeroContext) {
            return toHeroContext.widget;
          },
          child: Text(
            file.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        subtitle: Text(
          file.fullPath,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontFeatures: [FontFeature.tabularFigures()]),
        ),
        onTap: () => _onOpenEntry(file),
        trailing: IconButton(
          tooltip: 'Open',
          icon: const Icon(Icons.arrow_outward),
          onPressed: () => _onOpenEntry(file),
        ),
      ),
    );
  }

  Widget _buildEntry(PasswordEntry e) {
    final child = e.isFolder ? _buildFolder(e) : _buildFile(e);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: child,
    );
  }

  Widget _buildEmpty() {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline, size: 64),
            const SizedBox(height: 12),
            Text('Нет паролей', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Нажми «Добавить», чтобы создать первую запись.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _onAddPassword,
              icon: const Icon(Icons.add),
              label: const Text('Добавить'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {


    final queryField = _SearchField(
      initial: _query,
      onChanged: (v) => setState(() => _query = v),
      onFocus: (focused) => setState(() => _searchFocused = focused),
      hintText: 'Поиск по имени…', // можно заменить на S.of(context).search
    );

    final listBody = _loading
        ? const SliverFillRemaining(
      hasScrollBody: false,
      child: Center(child: CircularProgressIndicator()),
    )
        : (_root == null || _root!.children.isEmpty)
        ? SliverFillRemaining(hasScrollBody: false, child: _buildEmpty())
        : SliverToBoxAdapter(
      child: RefreshIndicator(
        onRefresh: _loadTree,
        child: ListView(
          primary: false,
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
          children: _filter(_root!.children).map(_buildEntry).toList(),
        ),
      ),
    );

    return Scaffold(
      floatingActionButton: AnimatedSlide(
        offset: _searchFocused ? const Offset(0, 2) : Offset.zero,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        child: FloatingActionButton.extended(
          onPressed: _onAddPassword,
          icon: const Icon(Icons.add),
          label: const Text('Добавить'),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            snap: true,
            pinned: true,
            expandedHeight: 160,
            title: const Text('Пароли'),
            actions: [
              IconButton(
                tooltip: 'Обновить',
                onPressed: _loadTree,
                icon: const Icon(Icons.refresh),
              ),
              IconButton(
                tooltip: 'Экспорт ключей в облако',
                icon: const Icon(Icons.cloud_upload_outlined),
                onPressed: () {
                  // получаем инстанс сервиса как у тебя принято
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => GpgKeysScreen(
                        keyService: widget.keyService,
                        autoStartExport: true,
                      ),
                    ),
                  );
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Padding(
                padding: const EdgeInsets.fromLTRB(16, 72, 16, 8),
                child: queryField,
              ),
            ),
          ),
          listBody,
        ],
      ),
    );
  }
}

/// Красивое поле поиска с Material 3 и фокус‑анимацией
class _SearchField extends StatefulWidget {
  final String initial;
  final ValueChanged<String> onChanged;
  final ValueChanged<bool>? onFocus;
  final String hintText;

  const _SearchField({
    required this.initial,
    required this.onChanged,
    this.onFocus,
    required this.hintText,
  });

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  late final TextEditingController _c;
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _c = TextEditingController(text: widget.initial);
    _focus.addListener(() => widget.onFocus?.call(_focus.hasFocus));
  }

  @override
  void dispose() {
    _c.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _focus.hasFocus ? 1.0 : 0.99,
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      child: TextField(
        controller: _c,
        focusNode: _focus,
        onChanged: widget.onChanged,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: widget.hintText,
          prefixIcon: const Icon(Icons.search),
          suffixIcon: (_c.text.isEmpty)
              ? null
              : IconButton(
            tooltip: 'Очистить',
            icon: const Icon(Icons.close),
            onPressed: () {
              _c.clear();
              widget.onChanged('');
            },
          ),
        ),
      ),
    );
  }
}
