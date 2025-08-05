import 'package:flutter/material.dart';
import 'package:new_pass/services/gpg_key_service.dart';
import 'package:openpgp/openpgp.dart';

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

  final gpgStorage = GPGStorageService();

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
    return Scaffold(
      appBar: AppBar(title: const Text('Generate Keys')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _passphraseController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Passphrase'),
            ),

            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: loading ? null : _generateKeys,
              child: loading ? const CircularProgressIndicator() : const Text('Generate'),
            )
          ],
        ),
      ),
    );
  }
}