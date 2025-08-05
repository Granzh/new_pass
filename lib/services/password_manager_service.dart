import 'package:new_pass/services/files/gpg_file_store.dart';
import 'package:new_pass/services/crypto/gpg_encryption_service.dart';
import 'package:path/path.dart' as p;


class PasswordManagerService {
  final GPGEncryptionService _crypto;
  final GPGFileStore _fileStore;

  PasswordManagerService({
    required GPGEncryptionService crypto,
    required GPGFileStore fileStore
  }) : _crypto = crypto, _fileStore = fileStore;

  Future<List<String>> listAll() async {
    return _fileStore.listPasswordFiles().map((e) => p.basenameWithoutExtension(e.path)).toList();
  }

  Future<String> loadDecrypted(String relativePath) async {
    final encrypted = await _fileStore.readEncrypted(relativePath);
    return _crypto.decrypt(encrypted);
  }

  Future<void> saveEncrypted(String relativePath, String plainText) async {
    final encrypted = await _crypto.encrypt(plainText);
    await _fileStore.writeEncrypted(relativePath, encrypted);
  }

  Future<void> delete(String relativePath) async {
    await _fileStore.deletePassword(relativePath);
  }
}