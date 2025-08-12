import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class GPGKeyMemory {
  String? _publicKey;
  String? _privateKey;
  String? _passphrase;

  GPGKeyMemory.empty();

  GPGKeyMemory({
    required String publicKey,
    required String privateKey,
    required String passphrase,
  }) :
      _publicKey = publicKey,
      _privateKey = privateKey,
      _passphrase = passphrase;

  Future<void> load({
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
