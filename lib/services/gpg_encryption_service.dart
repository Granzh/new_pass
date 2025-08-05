import 'gpg_key_memory.dart';
import 'package:openpgp/openpgp.dart';

class GPGEncryptionService {
  final GPGKeyMemory keyMemory;

  GPGEncryptionService(this.keyMemory);

  Future<String> encrypt(String content) async {
    if (!keyMemory.isInitialized) throw Exception('GPG public key not loaded');
    return await OpenPGP.encrypt(content, keyMemory.publicKey!);
  }

  Future<String> decrypt(String encrypted) async {
    if (!keyMemory.isInitialized) throw Exception('GPG private key not loaded');
    return await OpenPGP.decrypt(encrypted, keyMemory.privateKey!, keyMemory.passphrase!);
  }
}