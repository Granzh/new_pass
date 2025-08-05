import 'dart:io';

import 'package:new_pass/services/PasswordStoreService.dart';
import 'package:new_pass/services/gpg_key_service.dart';
import 'package:new_pass/services/io_file_service.dart';
import 'package:path/path.dart' as p;

class PasswordManager {
  final GPGKeyService keyService;
  final PasswordService passwordService;
  final PasswordStoreService storeService;

  PasswordManager(this.keyService, this.passwordService, this.storeService);

  Future<List<String>> listAllPasswords() async {
    final entries = storeService.listEntries();
    return entries.map((e) => p.basenameWithoutExtension(e.path)).toList();
  }

  Future<String> getDecryptedPassword(String relativePath) async {
    final file = File(p.join(storeService.root.path, relativePath));
    final encryptedContent = await storeService.readEncryptedFile(file);
    return passwordService.decryptPassword(encryptedContent);
  }

  Future<File> encryptPassword(String relativePath, String password) async {
    final encryptedContent = await passwordService.encryptPassword(password);
    await storeService.writeEncryptedFile(relativePath, encryptedContent);
    return File(p.join(storeService.root.path, relativePath));
  }
}