import 'dart:io';
import 'package:path/path.dart' as p;

class GPGFileStore {
  final Directory root;

  GPGFileStore(this.root);

  List<FileSystemEntity> listPasswordFiles() {
    return root
        .listSync(recursive: true)
        .where((e) => e is File && e.path.endsWith('.gpg'))
        .toList();
  }

  Future<String> readEncrypted(String relativePath) async {
    final file = File(p.join(root.path, relativePath));
    return await file.readAsString();
  }

  Future<void> writeEncrypted(String relativePath, String encryptedContent) async {
    final file = File(p.join(root.path, relativePath));
    await file.create(recursive: true);
    await file.writeAsString(encryptedContent);
  }

  Future<void> deletePassword(String relativePath) async {
    final file = File(p.join(root.path, relativePath));
    if (await file.exists()) await file.delete();
  }
}