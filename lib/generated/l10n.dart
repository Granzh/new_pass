// GENERATED CODE - DO NOT MODIFY BY HAND
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'intl/messages_all.dart';

// **************************************************************************
// Generator: Flutter Intl IDE plugin
// Made by Localizely
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, lines_longer_than_80_chars
// ignore_for_file: join_return_with_assignment, prefer_final_in_for_each
// ignore_for_file: avoid_redundant_argument_values, avoid_escaping_inner_quotes

class S {
  S();

  static S? _current;

  static S get current {
    assert(
      _current != null,
      'No instance of S was loaded. Try to initialize the S delegate before accessing S.current.',
    );
    return _current!;
  }

  static const AppLocalizationDelegate delegate = AppLocalizationDelegate();

  static Future<S> load(Locale locale) {
    final name = (locale.countryCode?.isEmpty ?? false)
        ? locale.languageCode
        : locale.toString();
    final localeName = Intl.canonicalizedLocale(name);
    return initializeMessages(localeName).then((_) {
      Intl.defaultLocale = localeName;
      final instance = S();
      S._current = instance;

      return instance;
    });
  }

  static S of(BuildContext context) {
    final instance = S.maybeOf(context);
    assert(
      instance != null,
      'No instance of S present in the widget tree. Did you add S.delegate in localizationsDelegates?',
    );
    return instance!;
  }

  static S? maybeOf(BuildContext context) {
    return Localizations.of<S>(context, S);
  }

  /// `FlutterPass`
  String get appTitle {
    return Intl.message('FlutterPass', name: 'appTitle', desc: '', args: []);
  }

  /// `Select folder`
  String get selectFolder {
    return Intl.message(
      'Select folder',
      name: 'selectFolder',
      desc: '',
      args: [],
    );
  }

  /// `Selected folder`
  String get selectedFolder {
    return Intl.message(
      'Selected folder',
      name: 'selectedFolder',
      desc: '',
      args: [],
    );
  }

  /// `Generate keys`
  String get generateKeys {
    return Intl.message(
      'Generate keys',
      name: 'generateKeys',
      desc: '',
      args: [],
    );
  }

  /// `Password`
  String get password {
    return Intl.message('Password', name: 'password', desc: '', args: []);
  }

  /// `Continue`
  String get continue_ {
    return Intl.message('Continue', name: 'continue_', desc: '', args: []);
  }

  /// `Notes`
  String get notes {
    return Intl.message('Notes', name: 'notes', desc: '', args: []);
  }

  /// `Copy`
  String get copy {
    return Intl.message('Copy', name: 'copy', desc: '', args: []);
  }

  /// `Delete`
  String get delete {
    return Intl.message('Delete', name: 'delete', desc: '', args: []);
  }

  /// `Save`
  String get save {
    return Intl.message('Save', name: 'save', desc: '', args: []);
  }

  /// `comment`
  String get comment {
    return Intl.message('comment', name: 'comment', desc: '', args: []);
  }

  /// `Cancel`
  String get cancel {
    return Intl.message('Cancel', name: 'cancel', desc: '', args: []);
  }

  /// `Name`
  String get gpgNameController {
    return Intl.message('Name', name: 'gpgNameController', desc: '', args: []);
  }

  /// `Email`
  String get gpgEmailController {
    return Intl.message(
      'Email',
      name: 'gpgEmailController',
      desc: '',
      args: [],
    );
  }

  /// `Passphrase`
  String get gpgPassphraseController {
    return Intl.message(
      'Passphrase',
      name: 'gpgPassphraseController',
      desc: '',
      args: [],
    );
  }

  /// `New Password`
  String get newPassword {
    return Intl.message(
      'New Password',
      name: 'newPassword',
      desc: '',
      args: [],
    );
  }

  /// `Error`
  String get error {
    return Intl.message('Error', name: 'error', desc: '', args: []);
  }

  /// `Name (example: github/account)`
  String get passwordName {
    return Intl.message(
      'Name (example: github/account)',
      name: 'passwordName',
      desc: '',
      args: [],
    );
  }

  /// `Content, first line - password`
  String get passwordContent {
    return Intl.message(
      'Content, first line - password',
      name: 'passwordContent',
      desc: '',
      args: [],
    );
  }

  /// `Your passwords`
  String get yourPasswords {
    return Intl.message(
      'Your passwords',
      name: 'yourPasswords',
      desc: '',
      args: [],
    );
  }

  /// `Delete password?`
  String get deletePassword {
    return Intl.message(
      'Delete password?',
      name: 'deletePassword',
      desc: '',
      args: [],
    );
  }

  /// `This action is irreversible.`
  String get deletePasswordMessage {
    return Intl.message(
      'This action is irreversible.',
      name: 'deletePasswordMessage',
      desc: '',
      args: [],
    );
  }

  /// `Decryption error`
  String get decryptionError {
    return Intl.message(
      'Decryption error',
      name: 'decryptionError',
      desc: '',
      args: [],
    );
  }

  /// `Copied`
  String get copied {
    return Intl.message('Copied', name: 'copied', desc: '', args: []);
  }
}

class AppLocalizationDelegate extends LocalizationsDelegate<S> {
  const AppLocalizationDelegate();

  List<Locale> get supportedLocales {
    return const <Locale>[
      Locale.fromSubtags(languageCode: 'en'),
      Locale.fromSubtags(languageCode: 'ru'),
    ];
  }

  @override
  bool isSupported(Locale locale) => _isSupported(locale);
  @override
  Future<S> load(Locale locale) => S.load(locale);
  @override
  bool shouldReload(AppLocalizationDelegate old) => false;

  bool _isSupported(Locale locale) {
    for (var supportedLocale in supportedLocales) {
      if (supportedLocale.languageCode == locale.languageCode) {
        return true;
      }
    }
    return false;
  }
}
