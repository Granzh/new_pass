// lib/ui/screens/password_list_screen.dart
import 'package:flutter/material.dart';

import '../../generated/l10n.dart';
import '../../models/password_entry.dart';
import '../../services/password_directory_prefs.dart';
import '../../utils/file_utils.dart';

import 'dart:ui' show FontFeature;
import 'package:flutter/material.dart';

// Если используешь локализацию S, можно раскомментировать и подставить строки
// import '../../generated/l10n.dart';

// Предполагаю, что у тебя уже есть эти утилиты/сервисы.
// Если имена другие — просто поправь в _loadTree().
// import '../../services/password_directory_prefs.dart';
// import '../../utils/file_utils.dart';

// Твоя модель
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
  const PasswordListScreen({super.key});

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
      // ↓↓↓ ЗАМЕНИ на свою загрузку дерева ↓↓↓
      // final folderPath = await PasswordDirectoryPrefs.load();
      // if (!mounted) return;
      // if (folderPath == null) {
      //   Navigator.pushReplacementNamed(context, '/select-folder');
      //   return;
      // }
      // final tree = buildTree(folderPath); // должно вернуть корень PasswordEntry
      // setState(() { _root = tree; });

      // Временный заглушечный пример, чтобы экран не падал,
      // удали после подключения своих сервисов:
      final mock = PasswordEntry(
        name: 'root',
        fullPath: '/',
        isFolder: true,
        children: [
          PasswordEntry(
            name: 'work',
            fullPath: '/work',
            isFolder: true,
            children: const [
              PasswordEntry(name: 'jira', fullPath: '/work/jira.gpg', isFolder: false),
              PasswordEntry(name: 'email', fullPath: '/work/email.gpg', isFolder: false),
            ],
          ),
          const PasswordEntry(name: 'github', fullPath: '/github.gpg', isFolder: false),
          const PasswordEntry(name: 'bank', fullPath: '/bank.gpg', isFolder: false),
        ],
      );
      await Future<void>.delayed(const Duration(milliseconds: 250));
      if (!mounted) return;
      _root = mock;
    } finally {
      if (mounted) setState(() => _loading = false);
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
