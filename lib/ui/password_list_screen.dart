// lib/ui/screens/password_list_screen.dart
import 'package:flutter/material.dart';

import '../models/password_entry.dart';
import '../services/folder_storage_service.dart';
import '../utils/file_utils.dart';

class PasswordListScreen extends StatefulWidget {
  const PasswordListScreen({super.key});

  @override
  State<PasswordListScreen> createState() => _PasswordListScreenState();
}

class _PasswordListScreenState extends State<PasswordListScreen> {
  PasswordEntry? root;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadTree();
  }

  Future<void> _loadTree() async {
    final folderPath = await FolderStorageService().getPath();
    if (folderPath == null) {
      if (context.mounted) Navigator.pushReplacementNamed(context, '/select-folder');
      return;
    }

    final tree = buildTree(folderPath);
    setState(() {
      root = tree;
      loading = false;
    });
  }

  Widget _buildEntry(PasswordEntry entry) {
    if (entry.isFolder) {
      return ExpansionTile(
        title: Text(entry.name),
        children: entry.children.map(_buildEntry).toList(),
      );
    } else {
      return ListTile(
        title: Text(entry.name.replaceAll('.gpg', '')),
        onTap: () {
          Navigator.pushNamed(
            context,
            '/password/view',
            arguments: entry.fullPath,
          );
        },
      );
    }
  }

  void _onAddPassword() {
    Navigator.pushNamed(context, '/password/new');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your passwords'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTree,
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        children: root!.children.map(_buildEntry).toList(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _onAddPassword,
        child: const Icon(Icons.add),
      ),
    );
  }
}
