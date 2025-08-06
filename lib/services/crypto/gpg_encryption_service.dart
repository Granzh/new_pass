import '../memory/gpg_key_memory.dart';
import 'package:openpgp/openpgp.dart';
import 'package:logging/logging.dart';

class GPGEncryptionService {
  final GPGKeyMemory keyMemory;
  static final _log = Logger('GPGEncryptionService');

  GPGEncryptionService({required this.keyMemory});

  Future<String> encrypt(String content) async {
    _log.info('Start encrypting content');
    if (!keyMemory.isInitialized) {
      _log.warning('GPG public key not loaded');
      throw Exception('GPG public key not loaded');
    }
    _log.info('End encrypting content');
    return await OpenPGP.encrypt(content, keyMemory.publicKey!);
  }

  Future<String> decrypt(String encrypted) async {
    _log.info('Start decrypting content');
    if (!keyMemory.isInitialized) {
      _log.warning('GPG private key not loaded');
      throw Exception('GPG private key not loaded');
    }
    _log.info('End decrypting content');
    return await OpenPGP.decrypt(encrypted, keyMemory.privateKey!, keyMemory.passphrase!);
  }
}