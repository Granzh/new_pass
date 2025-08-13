import 'dart:convert';
import 'dart:nativewrappers/_internal/vm/lib/typed_data_patch.dart';

import 'package:openpgp/openpgp.dart';
import 'package:logging/logging.dart';

import '../memory/gpg_key_memory.dart';
import '../storage/gpg_key_storage.dart';
import '../sync/cloud_key_exporter.dart';

class GPGKeyService {
  final Logger _log = Logger('GPGKeyService');
  final GPGKeyStorage storage;
  final GPGKeyMemory memory;

  final List<CloudKeyExporter> exporters;

  GPGKeyService({
    required this.storage,
    required this.memory,
    this.exporters = const [],
  });

  // ------------------- Load & Generate -------------------
  Future<bool> load() async {
    _log.info('Loading keys from storage into memory');
    final map = await storage.loadKeys();
    final pub = map['public'];
    final priv = map['private'];
    final pass = map['passphrase'];

    if ((pub == null || pub.isEmpty) || (priv == null || priv.isEmpty)) {
      _log.warning('No keys found in storage');
      return false;
    }

    await memory.load(publicKey: pub, privateKey: priv, passphrase: pass ?? '');
    _log.info('Keys loaded to memory');
    return true;
  }

  Future<void> generate({
    required String name,
    required String email,
    required String passphrase,
  }) async {
    _log.info('Generating new key pair for $name <$email>');

    final keyPair = await OpenPGP.generate();
    final publicKey = keyPair.publicKey;
    final privateKey = keyPair.privateKey;

    await storage.saveKeys(publicKey, privateKey, passphrase);
    await memory.load(publicKey: publicKey, privateKey: privateKey, passphrase: passphrase);
    _log.info('Key pair generated and saved');
  }

  // ------------------- Export (Local) -------------------
  Future<Map<String, Uint8List>> exportAsFiles({
    bool includePrivate = false,
    String publicFileName = 'public.asc',
    String privateFileName = 'private.asc',
  }) async {
    final pub = await _getPublicKey();
    if (pub == null || pub.isEmpty) {
      throw StateError('Public key not found');
    }

    final result = <String, Uint8List>{
      publicFileName: Uint8List.fromList(utf8.encode(pub)),
    };

    if (includePrivate) {
      final priv = await _getPrivateKey();
      if (priv == null || priv.isEmpty) {
        throw StateError('Private key not found');
      }
      result[privateFileName] = Uint8List.fromList(utf8.encode(priv));
    }

    return result;
  }

  // ------------------- Export (Cloud via exporters) -------------------
  Future<String?> exportPublic() async => _getPublicKey();

  Future<String?> exportPrivate() async => _getPrivateKey();

  Future<CloudExportResult> exportToCloud({
    required String providerId, // например: 'google-drive', 'dropbox', 'onedrive'
    bool includePrivate = false,
    String folderName = 'PassAppKeys',
    String publicFileName = 'public.asc',
    String privateFileName = 'private.asc',
  }) async {
    final exporter = exporters.firstWhere(
          (e) => e.id == providerId,
      orElse: () => throw StateError('No exporter registered for $providerId'),
    );

    final pub = await _getPublicKey();
    if (pub == null || pub.isEmpty) {
      throw StateError('Public key not found');
    }

    String? priv;
    if (includePrivate) {
      priv = await _getPrivateKey();
      if (priv == null || priv.isEmpty) {
        throw StateError('Private key not found');
      }
    }

    final result = await exporter.exportKeys(
      publicKeyArmored: pub,
      privateKeyArmored: priv,
      folderName: folderName,
      publicFileName: publicFileName,
      privateFileName: privateFileName,
    );

    _log.info('Exported keys via ${exporter.id} → $result');
    return result;
  }

  // ------------------- Helpers -------------------
  Future<String?> _getPublicKey() async {
    if (memory.isInitialized && memory.publicKey!.isNotEmpty) {
      return memory.publicKey;
    }
    final map = await storage.loadKeys();
    return map['public'];
  }

  Future<String?> _getPrivateKey() async {
    if (memory.isInitialized && memory.privateKey!.isNotEmpty) {
      return memory.privateKey;
    }
    final map = await storage.loadKeys();
    return map['private'];
  }

  Future<void> deleteAll() async {
    _log.info('Deleting keys from storage & memory');
    await storage.clear();
    await memory.load(publicKey: '', privateKey: '', passphrase: '');
  }

  bool get hasKeys => memory.isInitialized;
}
