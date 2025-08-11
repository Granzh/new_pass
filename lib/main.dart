import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'generated/l10n.dart';
import 'ui/screens/password_list_screen.dart';
import 'ui/screens/select_folder_screen.dart';
import 'ui/screens/new_password_screen.dart';
import 'ui/screens/password_view_screen.dart';
import 'ui/screens/init_gpg_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      // ✅ Material 3 тема без конфликтов
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

      // ✅ Точки локализации
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('ru')],

      // ✅ Роутинг: никакого вложенного MaterialApp
      initialRoute: '/',
      routes: {
        '/': (_) => const PasswordListScreen(),
        '/select-folder': (_) => const SelectFolderScreen(),
        '/password/new': (_) => const NewPasswordScreen(),
        '/password/view': (_) => const PasswordViewScreen(),
       // '/init-gpg': (_) => const InitGpgScreen(),
      },
    );
  }
}
