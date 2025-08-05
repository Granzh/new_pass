import 'dart:io';
import 'package:get_it/get_it.dart';

import '../services/crypto/gpg_encryption_service.dart';
import '../services/files/gpg_file_store.dart';
import '../services/memory/gpg_key_memory.dart';
import '../services/storage/gpg_key_storage.dart';
import '../services/password_directory_prefs.dart';
import '../services/password_manager_service.dart';

final locator = GetIt.instance;

void setupLocator(Directory passwordDirectory) {
  locator.registerLazySingleton(() => PasswordDirectoryPrefs());
  locator.registerLazySingleton(() => GPGKeyStorage());

  locator.registerSingleton(GPGKeyMemory());
  locator.registerSingleton(GPGEncryptionService(locator<GPGKeyMemory>()));
  locator.registerSingleton(GPGFileStore(passwordDirectory));
  locator.registerSingleton(PasswordManagerService(
    locator<GPGKeyMemory>(),
    locator<GPGEncryptionService>(),
    locator<GPGFileStore>(),
  ));
}