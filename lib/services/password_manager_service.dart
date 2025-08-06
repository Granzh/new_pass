import 'package:new_pass/services/files/gpg_file_store.dart';
import 'package:new_pass/services/crypto/gpg_encryption_service.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;


class PasswordManagerService {
  static final _log = Logger('PasswordManagerService');
  final GPGEncryptionService _crypto;
  final GPGFileStore _fileStore;

  PasswordManagerService({
    required GPGEncryptionService crypto,
    required GPGFileStore fileStore
  }) : _crypto = crypto, _fileStore = fileStore;

  Future<List<String>> listAll() async {
    _log.info('Listing all passwords');
    return _fileStore.listPasswordFiles().map((e) => p.basenameWithoutExtension(e.path)).toList();
  }

  Future<String> loadDecrypted(String relativePath) async {
    _log.info('Loading decrypted password with path: $relativePath');
    final encrypted = await _fileStore.readEncrypted(relativePath);
    return _crypto.decrypt(encrypted);
  }

  Future<void> saveEncrypted(String relativePath, String plainText) async {
    _log.info('Saving encrypted password with path: $relativePath');
    final encrypted = await _crypto.encrypt(plainText);
    await _fileStore.writeEncrypted(relativePath, encrypted);
  }

  Future<void> delete(String relativePath) async {
    _log.info('Deleting password with path: $relativePath');
    await _fileStore.deletePassword(relativePath);
  }
}