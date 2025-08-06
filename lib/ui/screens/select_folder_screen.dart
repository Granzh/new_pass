import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import '../../generated/l10n.dart';
import '../../services/password_directory_prefs.dart';

class SelectFolderScreen extends StatefulWidget {
  const SelectFolderScreen({super.key});

  @override
  State<SelectFolderScreen> createState() => _SelectFolderScreenState();
}

class _SelectFolderScreenState extends State<SelectFolderScreen> {
  String? selectedPath;
  bool loading = false;

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

    await PasswordDirectoryPrefs.save(selectedPath!);

    // Здесь можно создать структуру папки или проверить её

    if (context.mounted) {
      Navigator.pushReplacementNamed(context, '/init-gpg');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.selectFolder)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: pickFolder,
              child: Text(l10n.selectFolder),
            ),
            if (selectedPath != null) ...[
              const SizedBox(height: 12),
              Text(l10n.selectedFolder, style: TextStyle(fontWeight: FontWeight.bold)),
              Text(selectedPath!),
            ],
            const Spacer(),
            ElevatedButton(
              onPressed: selectedPath != null && !loading ? confirmSelection : null,
              child: loading ? const CircularProgressIndicator() : Text(l10n.continue_),
            ),
          ],
        ),
      ),
    );
  }
}