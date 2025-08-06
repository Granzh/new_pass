import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:new_pass/services/storage/gpg_key_storage.dart';
import 'package:new_pass/services/password_directory_prefs.dart';
import 'package:new_pass/services/password_manager_service.dart';
import 'package:new_pass/ui/screens/init_gpg_screen.dart';
import 'package:new_pass/ui/screens/new_password_screen.dart';
import 'package:new_pass/ui/screens/password_list_screen.dart';
import 'package:new_pass/ui/screens/password_view_screen.dart';
import 'package:new_pass/ui/screens/select_folder_screen.dart';

import 'di/locator.dart';
import 'generated/l10n.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final gpgService = GPGKeyStorage();

  final folderPath = await PasswordDirectoryPrefs.load();
  final keys = await gpgService.loadKeys();

  // определим, куда перекинуть при старте
  final String initialRoute;
  if (folderPath == null) {
    initialRoute = '/select-folder';
  } else if (keys['private'] == null || keys['public'] == null || keys['passphrase'] == null) {
    initialRoute = '/init-gpg';
  } else {
    initialRoute = '/home';
  }

  // final manager = locator<PasswordManagerService>();

  runApp(MyApp(initialRoute: initialRoute));
}

class MyApp extends StatelessWidget {
  final String initialRoute;
  const MyApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FlutterPass',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      initialRoute: initialRoute,
      routes: {
        '/select-folder': (context) => const SelectFolderScreen(),
        '/init-gpg': (context) => const InitGPGScreen(),
        '/home': (context) => const PasswordListScreen(),
        '/password/view': (context) => const PasswordViewScreen(),
        '/password/new': (context) => const NewPasswordScreen(),
      },
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('ru'),
      ],
      localeResolutionCallback: (locale, supportedLocales) {
        return supportedLocales.contains(locale)
            ? locale
            : supportedLocales.first;
      },
    );
  }
}