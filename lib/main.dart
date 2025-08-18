import 'package:flutter/material.dart';
import 'package:new_pass/services/keys/gpg_key_service.dart';
import 'package:new_pass/services/memory/gpg_key_memory.dart';
import 'package:new_pass/services/password_directory_prefs.dart';
import 'package:new_pass/services/storage/gpg_key_storage.dart';
import 'package:new_pass/services/sync/google_drive_key_exporter.dart';
import 'package:new_pass/ui/screens/gpg_keys_screen.dart';
import 'package:logging/logging.dart';

import 'generated/l10n.dart';
import 'ui/screens/password_list_screen.dart';
import 'ui/screens/select_folder_screen.dart';
import 'ui/screens/new_password_screen.dart';
import 'ui/screens/password_view_screen.dart';
import 'ui/screens/init_gpg_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _setupLogging();

  final savedPath = await PasswordDirectoryPrefs.load();

  final keyMemory  = GPGKeyMemory.empty();
  final keyStorage = GPGKeyStorage();
  final keyService = GPGKeyService(
    storage: keyStorage,
    memory: keyMemory,
    exporters: [
      GoogleDriveKeyExporter(),
    ],
  );

  runApp(MyApp(
    startOnSelectFolder: savedPath == null,
    keyService: keyService,
  ));
}

void _setupLogging() {
  Logger.root.level = Level.INFO;
  Logger.root.onRecord.listen((r) {
    // ignore: avoid_print
    print('${r.level.name} ${r.loggerName}: ${r.time.toIso8601String()} — ${r.message}');
  });
}

class MyApp extends StatelessWidget {
  final bool startOnSelectFolder;
  final GPGKeyService keyService;

  const MyApp({
    super.key,
    required this.startOnSelectFolder,
    required this.keyService,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pass',
      theme: ThemeData(useMaterial3: true),
      initialRoute: startOnSelectFolder ? '/select-folder' : '/',
      routes: {
        '/':               (_) => PasswordListScreen(keyService: keyService),
        '/select-folder':  (_) => const SelectFolderScreen(),
        '/new':            (_) => const NewPasswordScreen(),
        '/init-gpg':       (_) => const InitGPGScreen(),
        '/gpg-keys':       (_) => GpgKeysScreen(keyService: keyService),
        // '/password/view'
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/password/view' && settings.arguments is String) {
          return MaterialPageRoute(
            builder: (_) => const PasswordViewScreen(),
            settings: RouteSettings(arguments: settings.arguments),
          );
        }
        return null;
      },
    );
  }
}