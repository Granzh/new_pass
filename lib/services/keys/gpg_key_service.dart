import 'package:openpgp/openpgp.dart';
import 'package:logging/logging.dart';

import '../memory/gpg_key_memory.dart';
import '../storage/gpg_key_storage.dart';

class GPGKeyService {
  final Logger _log = Logger('GPGKeyService');
  final GPGKeyStorage storage;
  final GPGKeyMemory memory;

  GPGKeyService({
    required this.storage,
    required this.memory,
  });

  Future<bool> loadFromStorage() async {
    _log.info('Loading keys from secure storage');
    final map = await storage.loadKeys();
    final pub = map['public'];
    final priv = map['private'];
    final pass = map['passphrase'];

    final ready = pub != null && priv != null && pass != null && pub.isNotEmpty && priv.isNotEmpty;
    if (!ready) {
      _log.info('No keys in storage');
      return false;
    }

    await memory
        .load(publicKey: pub, privateKey: priv, passphrase: pass);
    _log.info('Keys loaded to memory');
    return true;
  }

  Future<void> generate({
    required String name,
    required String email,
    required String passphrase,
  }) async {
    _log.info('Generating new key pair for $name <$email>');


    final keyPair = await OpenPGP.generate( //TODO: добавить options
      );
    // keyPair.privateKey, keyPair.publicKey
    await storage.saveKeys(keyPair.privateKey, keyPair.publicKey, passphrase);
    await memory.load(
      publicKey: keyPair.publicKey,
      privateKey: keyPair.privateKey,
      passphrase: passphrase,
    );
    _log.info('Key pair generated & stored');
  }

  Future<void> importArmored({
    required String publicKey,
    required String privateKey,
    required String passphrase,
  }) async {
    _log.info('Importing armored keys');

    await storage.saveKeys(privateKey, publicKey, passphrase);
    await memory.load(
      publicKey: publicKey,
      privateKey: privateKey,
      passphrase: passphrase,
    );
    _log.info('Keys imported and loaded to memory');
  }

  /// Экспорт: достаём из памяти, если пусто — из storage.
  Future<String?> exportPublic() async {
    if (memory.publicKey != null && memory.publicKey!.isNotEmpty) {
      return memory.publicKey;
    }
    final map = await storage.loadKeys();
    return map['public'];
  }

  Future<String?> exportPrivate() async {
    if (memory.privateKey != null && memory.privateKey!.isNotEmpty) {
      return memory.privateKey;
    }
    final map = await storage.loadKeys();
    return map['private'];
  }

  /// Удалить ключи везде.
  Future<void> deleteAll() async {
    _log.info('Deleting keys from storage & memory');
    await storage.clear();
    await memory.load(publicKey: '', privateKey: '', passphrase: '');
  }

  bool get hasKeys => memory.isInitialized;
}
