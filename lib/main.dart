import 'package:flutter/material.dart';
import 'package:new_pass/services/folder_storage_service.dart';
import 'package:new_pass/services/gpg_key_service.dart';
import 'package:new_pass/ui/init_gpg_screen.dart';
import 'package:new_pass/ui/new_password_screen.dart';
import 'package:new_pass/ui/password_list_screen.dart';
import 'package:new_pass/ui/password_view_screen.dart';
import 'package:new_pass/ui/select_folder_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final folderService = FolderStorageService();
  final gpgService = GPGStorageService();

  final folderPath = await folderService.getPath();
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
    );
  }
}