import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class GPGKeyStorage {
  final _storage = const FlutterSecureStorage();
  static const _privateKeyKey = 'gpg_private_key';
  static const _publicKeyKey = 'gpg_public_key';
  static const _passphraseKey = 'gpg_passphrase';

  Future<void> saveKeys(String privateKey, String publicKey, String passphrase) async {
    await _storage.write(key: _privateKeyKey, value: privateKey);
    await _storage.write(key: _publicKeyKey, value: publicKey);
    await _storage.write(key: _passphraseKey, value: passphrase);
  }

  Future<Map<String, String?>> loadKeys() async {
    return {
      'private': await _storage.read(key: _privateKeyKey),
      'public': await _storage.read(key: _publicKeyKey),
      'passphrase': await _storage.read(key: _passphraseKey),
    };
  }

  Future<void> clear() async => _storage.deleteAll();
}