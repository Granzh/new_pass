import 'gpg_key_service.dart';
import 'package:openpgp/openpgp.dart';

class PasswordService {
  final GPGKeyService keyService;

  PasswordService(this.keyService);

  Future<String> decryptPassword(String encryptedContent) async {
    if (!keyService.isInitialized) {
      throw Exception('Private key not loaded');
    }

    final decrypted = await OpenPGP.decrypt(
      encryptedContent,
      keyService.privateKey!,
      keyService.passphrase!,
    );

    return decrypted;
  }

  Future<String> encryptPassword(String password) async {
    if (!keyService.isInitialized) {
      throw Exception('Public key not loaded');
    }

    final encrypted = await OpenPGP.encrypt(password, keyService.publicKey!);

    return encrypted;
  }
}