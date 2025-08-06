import 'package:flutter/material.dart';
import 'package:openpgp/openpgp.dart';
import 'package:new_pass/generated/l10n.dart';

import '../../services/storage/gpg_key_storage.dart';

class InitGPGScreen extends StatefulWidget {
  const InitGPGScreen({super.key});

  @override
  State<InitGPGScreen> createState() => _InitGPGScreenState();
}

class _InitGPGScreenState extends State<InitGPGScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passphraseController = TextEditingController();
  bool loading = false;

  final gpgStorage = GPGKeyStorage();

  Future<void> _generateKeys() async {
    setState(() => loading = true);
    try {
      final keyOptions = KeyOptions();
      keyOptions.algorithm = Algorithm.RSA;
      keyOptions.hash = Hash.SHA256;
      keyOptions.rsaBits = 2048;

      final options = Options();
      options.name = _nameController.text;
      options.email = _emailController.text;
      options.passphrase = _passphraseController.text;
      options.keyOptions = keyOptions;

      final keyPair = await OpenPGP.generate(options: options);

      await gpgStorage.saveKeys(
        keyPair.privateKey,
        keyPair.publicKey,
        _passphraseController.text,
      );

      if (context.mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Error Generating'),
          content: Text(e.toString()),
        ),
      );
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.appTitle)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: l10n.gpgNameController),
            ),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: l10n.gpgEmailController),
            ),
            TextField(
              controller: _passphraseController,
              obscureText: true,
              decoration: InputDecoration(labelText: l10n.gpgPassphraseController),
            ),

            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: loading ? null : _generateKeys,
              child: loading ? const CircularProgressIndicator() : Text(l10n.generateKeys),
            )
          ],
        ),
      ),
    );
  }
}