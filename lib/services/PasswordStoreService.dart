import 'dart:io';
import 'package:path/path.dart' as p;

class PasswordStoreService {
  final Directory root;

  PasswordStoreService(this.root);

  List<FileSystemEntity> listEntries() {
    return root.listSync(recursive: true).where((e) => e is File && e.path.endsWith('.gpg')).toList();
  }

  Future<String> readEncryptedFile(File file) async {
    return await file.readAsString();
  }

  Future<void> writeEncryptedFile(String relativePath, String content) async {
    final path = p.join(root.path, relativePath);
    final file = File(path);
    await file.create(recursive: true);
    await file.writeAsString(content);
  }

  Future<void> deleteFile(String relativePath) async {
    final path = p.join(root.path, relativePath);
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }
}