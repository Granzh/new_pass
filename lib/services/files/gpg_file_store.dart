import 'dart:io';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;

class GPGFileStore {
  final Directory root;
  static final _log = Logger('GPGFileStore');

  GPGFileStore({required this.root});

  List<FileSystemEntity> listPasswordFiles() {
    _log.info('Listing password files');
    return root
        .listSync(recursive: true)
        .where((e) => e is File && e.path.endsWith('.gpg'))
        .toList();
  }

  Future<String> readEncrypted(String relativePath) async {
    _log.info('Reading encrypted file with path: $relativePath');
    final file = File(p.join(root.path, relativePath));
    return await file.readAsString();
  }

  Future<void> writeEncrypted(String relativePath, String encryptedContent) async {
    _log.info('Writing encrypted file with path: $relativePath');
    final file = File(p.join(root.path, relativePath));
    await file.create(recursive: true);
    await file.writeAsString(encryptedContent);
  }

  Future<void> deletePassword(String relativePath) async {
    _log.info('Deleting password file with path: $relativePath');
    final file = File(p.join(root.path, relativePath));
    if (await file.exists()) await file.delete();
  }
}