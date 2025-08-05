import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class GPGKeyService {
  String? _publicKey;
  String? _privateKey;
  String? _passphrase;

  Future<void> loadPrivateKey(String publicKey, String privateKey, String passphrase) async {
    _publicKey = publicKey;
    _privateKey = privateKey;
    _passphrase = passphrase;
  }

  Future<void> loadKeys({
    required String publicKey,
    required String privateKey,
    required String passphrase,
  }) async {
    _publicKey = publicKey;
    _privateKey = privateKey;
    _passphrase = passphrase;
  }

  String? get publicKey => _publicKey;
  String? get privateKey => _privateKey;
  String? get passphrase => _passphrase;

  bool get isInitialized => publicKey != null && privateKey != null && passphrase != null;
}

class GPGStorageService {
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
    final privateKey = await _storage.read(key: _privateKeyKey);
    final publicKey = await _storage.read(key: _publicKeyKey);
    final passphrase = await _storage.read(key: _passphraseKey);
    return {
      'private': privateKey,
      'public': publicKey,
      'passphrase': passphrase,
    };
  }

  Future<void> clear() async {
    await _storage.deleteAll();
  }
}