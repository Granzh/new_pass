import 'dart:io';

import 'package:new_pass/services/gpg_file_store.dart';
import 'package:new_pass/services/gpg_key_memory.dart';
import 'package:new_pass/services/gpg_encryption_service.dart';
import 'package:path/path.dart' as p;

class PasswordManagerService {
  final GPGKeyMemory keyMemory;
  final GPGEncryptionService crypto;
  final GPGFileStore fileStore;

  PasswordManagerService(this.keyMemory, this.crypto, this.fileStore);

  Future<List<String>> listAll() async {
    return fileStore.listPasswordFiles().map((e) => p.basenameWithoutExtension(e.path)).toList();
  }

  Future<String> loadDecrypted(String relativePath) async {
    final encrypted = await fileStore.readEncrypted(relativePath);
    return crypto.decrypt(encrypted);
  }

  Future<void> saveEncrypted(String relativePath, String plainText) async {
    final encrypted = await crypto.encrypt(plainText);
    await fileStore.writeEncrypted(relativePath, encrypted);
  }

  Future<void> delete(String relativePath) async {
    await fileStore.deletePassword(relativePath);
  }
}