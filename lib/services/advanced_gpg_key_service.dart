class AdvancedGpgKeyService {
  final UnderlyingOpenPgp api;
  final KeyStore keyStore;

  AdvancedGpgKeyService({
    required this.api,
    required this.keyStore,
  });

  Future<GeneratedKeyBundle> generateKey(AdvancedKeyParams p) async {
    // 1) Валидируем
    p.validate();

    // 2) Сборка userId
    final userId = _buildUserId(p);

    // 3) Ветка по алгоритму
    GeneratedKeyBundle bundle;
    if (p.algorithm == KeyAlgorithm.rsa) {
      bundle = await api.generateRsa(
        userId: userId,
        passphrase: p.passphrase,
        rsaBits: p.rsaBits!,
        expiresAt: p.expiresAt,
        canSign: p.canSign,
        canEncrypt: p.canEncrypt,
        canAuthenticate: p.canAuthenticate,
        addEncryptionSubkey: p.makeSeparateEncryptionSubkey,
      );
    } else {
      bundle = await api.generateEcc(
        userId: userId,
        passphrase: p.passphrase,
        curve: p.curve!,
        expiresAt: p.expiresAt,
        canSign: p.canSign,
        canEncrypt: p.canEncrypt,
        canAuthenticate: p.canAuthenticate,
        addEncryptionSubkey: p.makeSeparateEncryptionSubkey,
        // Рекомендуем связку: подпись — ed25519, шифрование — cv25519
        encryptionSubkeyCurve: p.encryptionSubkeyCurve ?? EccCurve.cv25519,
      );
    }

    await keyStore.save(bundle);

    return bundle;
  }

  String _buildUserId(AdvancedKeyParams p) {
    // "Name (Comment) <email>"
    final name = p.name.trim();
    final comment = (p.comment ?? '').trim();
    final email = p.email.trim();

    final buf = StringBuffer(name);
    if (comment.isNotEmpty) buf.write(' ($comment)');
    if (email.isNotEmpty) buf.write(' <$email>');
    return buf.toString();
  }
}

class AdvancedKeyParams {
  final KeyAlgorithm algorithm;

  final int? rsaBits; // 2048/3072/4096

  final EccCurve? curve;
  final EccCurve? encryptionSubkeyCurve;

  final String name;
  final String email;
  final String? comment;

  final bool canSign;
  final bool canEncrypt;
  final bool canAuthenticate;

  final bool makeSeparateEncryptionSubkey;

  final String passphrase;

  final DateTime? expiresAt;

  AdvancedKeyParams({
    required this.algorithm,
    this.rsaBits,
    this.curve,
    this.encryptionSubkeyCurve,
    required this.name,
    required this.email,
    this.comment,
    this.canSign = true,
    this.canEncrypt = true,
    this.canAuthenticate = false,
    this.makeSeparateEncryptionSubkey = true,
    required this.passphrase,
    this.expiresAt,
  });

  void validate() {
    if (name.trim().isEmpty) {
      throw ArgumentError('Name is required');
    }
    if (email.trim().isEmpty) {
      throw ArgumentError('Email is required');
    }
    if (passphrase.isEmpty) {
      throw ArgumentError('Passphrase is required');
    }
    if (algorithm == KeyAlgorithm.rsa) {
      if (rsaBits == null || !(rsaBits == 2048 || rsaBits == 3072 || rsaBits == 4096)) {
        throw ArgumentError('RSA bits must be 2048, 3072 or 4096');
      }
    } else {
      if (curve == null) {
        throw ArgumentError('ECC curve must be provided');
      }
    }
  }
}

enum KeyAlgorithm { rsa, ecc }

enum EccCurve {
  ed25519,  // подпись
  cv25519,  // шифрование
  secp256k1,
  p256,
  p384,
  p521,
}

class GeneratedKeyBundle {
  final String userId;
  final String publicArmored;
  final String privateArmored;
  final String fingerprint;
  final List<String> subkeyFingerprints;

  GeneratedKeyBundle({
    required this.userId,
    required this.publicArmored,
    required this.privateArmored,
    required this.fingerprint,
    required this.subkeyFingerprints,
  });
}

abstract class KeyStore {
  Future<void> save(GeneratedKeyBundle bundle);
}

abstract class UnderlyingOpenPgp {
  Future<GeneratedKeyBundle> generateRsa({
    required String userId,
    required String passphrase,
    required int rsaBits,
    DateTime? expiresAt,
    bool canSign = true,
    bool canEncrypt = true,
    bool canAuthenticate = false,
    bool addEncryptionSubkey = true,
  });

  Future<GeneratedKeyBundle> generateEcc({
    required String userId,
    required String passphrase,
    required EccCurve curve,
    EccCurve? encryptionSubkeyCurve,
    DateTime? expiresAt,
    bool canSign = true,
    bool canEncrypt = true,
    bool canAuthenticate = false,
    bool addEncryptionSubkey = true,
  });
}