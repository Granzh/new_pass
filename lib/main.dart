import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:new_pass/services/keys/gpg_key_service.dart';
import 'package:new_pass/services/memory/gpg_key_memory.dart';
import 'package:new_pass/services/storage/gpg_key_storage.dart';
import 'package:new_pass/services/sync/google_drive_key_exporter.dart';
import 'package:new_pass/ui/screens/gpg_keys_screen.dart';

import 'generated/l10n.dart';
import 'ui/screens/password_list_screen.dart';
import 'ui/screens/select_folder_screen.dart';
import 'ui/screens/new_password_screen.dart';
import 'ui/screens/password_view_screen.dart';
import 'ui/screens/init_gpg_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final keyMemory = GPGKeyMemory.empty();
  final keyStorage = GPGKeyStorage();
  final driveExporter = GoogleDriveKeyExporter(
    clientId: '<your-client-id>'
  );

  final keyService = GPGKeyService(
      storage: keyStorage,
      memory: keyMemory,
      exporters: [driveExporter]
  );

  runApp(MyApp(keyService: keyService));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.keyService});
  final GPGKeyService keyService;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      themeMode: ThemeMode.system,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF5B7CFA),
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF7F8FA),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        cardTheme: const CardThemeData(
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(20)),
          ),
          surfaceTintColor: Colors.white,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF5B7CFA),
        brightness: Brightness.dark,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
          filled: true,
        ),
        cardTheme: const CardThemeData(
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(20)),
          ),
        ),
      ),

      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('ru')],

      initialRoute: '/',
      routes: {
        '/': (_) => const PasswordListScreen(),
        '/select-folder': (_) => const SelectFolderScreen(),
        '/password/new': (_) => const NewPasswordScreen(),
        '/password/view': (_) => const PasswordViewScreen(),
        '/gpg_keys': (context) => GpgKeysScreen(keyService: keyService)
       // '/init-gpg': (_) => const InitGpgScreen(),
      },
    );
  }
}
