import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import '../services/folder_storage_service.dart';

class SelectFolderScreen extends StatefulWidget {
  const SelectFolderScreen({super.key});

  @override
  State<SelectFolderScreen> createState() => _SelectFolderScreenState();
}

class _SelectFolderScreenState extends State<SelectFolderScreen> {
  String? selectedPath;
  bool loading = false;
  final folderService = FolderStorageService();

  Future<void> pickFolder() async {
    String? path = await FilePicker.platform.getDirectoryPath();
    if (path != null) {
      setState(() {
        selectedPath = path;
      });
    }
  }

  Future<void> confirmSelection() async {
    if (selectedPath == null) return;
    setState(() => loading = true);

    await folderService.savePath(selectedPath!);

    // Здесь можно создать структуру папки или проверить её

    if (context.mounted) {
      Navigator.pushReplacementNamed(context, '/init-gpg');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Выберите папку')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: pickFolder,
              child: const Text('Выбрать папку'),
            ),
            if (selectedPath != null) ...[
              const SizedBox(height: 12),
              Text('Выбранная папка:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(selectedPath!),
            ],
            const Spacer(),
            ElevatedButton(
              onPressed: selectedPath != null && !loading ? confirmSelection : null,
              child: loading ? const CircularProgressIndicator() : const Text('Продолжить'),
            ),
          ],
        ),
      ),
    );
  }
}