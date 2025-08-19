import 'package:flutter/material.dart';

import '../../services/advanced_gpg_key_service.dart';

class AdvancedKeyWizardScreen extends StatefulWidget {
  const AdvancedKeyWizardScreen({
    super.key,
    required this.service,
  });

  final AdvancedGpgKeyService service;

  @override
  State<AdvancedKeyWizardScreen> createState() => _AdvancedKeyWizardScreenState();
}

class _AdvancedKeyWizardScreenState extends State<AdvancedKeyWizardScreen> {
  final _formKey = GlobalKey<FormState>();

  // base
  KeyAlgorithm _algo = KeyAlgorithm.ecc;
  int _rsaBits = 4096;
  EccCurve _curve = EccCurve.ed25519;
  EccCurve _encSubCurve = EccCurve.cv25519;

  // uid
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _commentCtrl = TextEditingController();

  // usage
  bool _canSign = true;
  bool _canEncrypt = true;
  bool _canAuth = false;

  // subkeys
  bool _separateEncSubkey = true;

  // expiry
  bool _noExpiry = true;
  DateTime? _expiresAt;

  // protection
  final _passCtrl = TextEditingController();
  final _pass2Ctrl = TextEditingController();
  bool _obscure = true;

  bool _busy = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _commentCtrl.dispose();
    _passCtrl.dispose();
    _pass2Ctrl.dispose();
    super.dispose();
  }

  Future<void> _pickExpiry(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: DateTime(now.year + 10),
      initialDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _expiresAt = DateTime(picked.year, picked.month, picked.day);
        _noExpiry = false;
      });
    }
  }

  String get _previewUid {
    final name = _nameCtrl.text.trim();
    final comment = _commentCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final parts = <String>[];
    if (name.isNotEmpty) parts.add(name);
    if (comment.isNotEmpty) parts.add('($comment)');
    if (email.isNotEmpty) parts.add('<$email>');
    return parts.isEmpty ? 'User ID preview' : parts.join(' ');
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      final p = AdvancedKeyParams(
        algorithm: _algo,
        rsaBits: _algo == KeyAlgorithm.rsa ? _rsaBits : null,
        curve: _algo == KeyAlgorithm.ecc ? _curve : null,
        encryptionSubkeyCurve: _algo == KeyAlgorithm.ecc ? _encSubCurve : null,
        name: _nameCtrl.text,
        email: _emailCtrl.text,
        comment: _commentCtrl.text.isEmpty ? null : _commentCtrl.text,
        canSign: _canSign,
        canEncrypt: _canEncrypt,
        canAuthenticate: _canAuth,
        makeSeparateEncryptionSubkey: _separateEncSubkey,
        passphrase: _passCtrl.text,
        expiresAt: _noExpiry ? null : _expiresAt,
      );

      final bundle = await widget.service.generateKey(p);

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Key generated: ${bundle.fingerprint.substring(0, 16)}…')),
      );
      Navigator.of(context).pop(bundle); // вернёмся и отдадим результат
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('New GPG key'),
      ),
      body: AbsorbPointer(
        absorbing: _busy,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // ALGORITHM
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Algorithm', style: theme.textTheme.titleMedium),
                        const SizedBox(height: 8),
                        SegmentedButton<KeyAlgorithm>(
                          segments: const [
                            ButtonSegment(value: KeyAlgorithm.ecc, label: Text('ECC')),
                            ButtonSegment(value: KeyAlgorithm.rsa, label: Text('RSA')),
                          ],
                          selected: {_algo},
                          onSelectionChanged: (s) => setState(() => _algo = s.first),
                        ),
                        const SizedBox(height: 12),
                        if (_algo == KeyAlgorithm.rsa)
                          DropdownButtonFormField<int>(
                            value: _rsaBits,
                            items: const [
                              DropdownMenuItem(value: 2048, child: Text('RSA 2048')),
                              DropdownMenuItem(value: 3072, child: Text('RSA 3072')),
                              DropdownMenuItem(value: 4096, child: Text('RSA 4096 (recommended)')),
                            ],
                            onChanged: (v) => setState(() => _rsaBits = v ?? 4096),
                            decoration: const InputDecoration(labelText: 'Key size'),
                          )
                        else ...[
                          DropdownButtonFormField<EccCurve>(
                            value: _curve,
                            items: const [
                              DropdownMenuItem(value: EccCurve.ed25519, child: Text('ed25519 (signing)')),
                              DropdownMenuItem(value: EccCurve.secp256k1, child: Text('secp256k1')),
                              DropdownMenuItem(value: EccCurve.p256, child: Text('NIST P‑256')),
                              DropdownMenuItem(value: EccCurve.p384, child: Text('NIST P‑384')),
                              DropdownMenuItem(value: EccCurve.p521, child: Text('NIST P‑521')),
                            ],
                            onChanged: (v) => setState(() => _curve = v ?? EccCurve.ed25519),
                            decoration: const InputDecoration(labelText: 'Primary curve'),
                          ),
                          const SizedBox(height: 8),
                          SwitchListTile(
                            value: _separateEncSubkey,
                            onChanged: (v) => setState(() => _separateEncSubkey = v),
                            title: const Text('Add separate encryption subkey'),
                            subtitle: const Text('Recommended: cv25519 for encryption'),
                          ),
                          if (_separateEncSubkey)
                            DropdownButtonFormField<EccCurve>(
                              value: _encSubCurve,
                              items: const [
                                DropdownMenuItem(value: EccCurve.cv25519, child: Text('cv25519 (recommended)')),
                                DropdownMenuItem(value: EccCurve.p256, child: Text('NIST P‑256')),
                                DropdownMenuItem(value: EccCurve.p384, child: Text('NIST P‑384')),
                                DropdownMenuItem(value: EccCurve.p521, child: Text('NIST P‑521')),
                              ],
                              onChanged: (v) => setState(() => _encSubCurve = v ?? EccCurve.cv25519),
                              decoration: const InputDecoration(labelText: 'Encryption subkey curve'),
                            ),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // USER ID
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('User ID', style: theme.textTheme.titleMedium),
                        TextFormField(
                          controller: _nameCtrl,
                          decoration: const InputDecoration(labelText: 'Name *'),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _emailCtrl,
                          decoration: const InputDecoration(labelText: 'Email *'),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _commentCtrl,
                          decoration: const InputDecoration(labelText: 'Comment (optional)'),
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Chip(
                            label: Text(_previewUid),
                            avatar: const Icon(Icons.badge_outlined),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // USAGE & EXPIRY
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Usage', style: theme.textTheme.titleMedium),
                        CheckboxListTile(
                          value: _canSign,
                          onChanged: (v) => setState(() => _canSign = v ?? true),
                          title: const Text('Sign'),
                        ),
                        CheckboxListTile(
                          value: _canEncrypt,
                          onChanged: (v) => setState(() => _canEncrypt = v ?? true),
                          title: const Text('Encrypt'),
                        ),
                        CheckboxListTile(
                          value: _canAuth,
                          onChanged: (v) => setState(() => _canAuth = v ?? false),
                          title: const Text('Authenticate (SSH / auth)'),
                        ),
                        const Divider(),
                        SwitchListTile(
                          value: _noExpiry,
                          onChanged: (v) => setState(() {
                            _noExpiry = v;
                            if (v) _expiresAt = null;
                          }),
                          title: const Text('No expiration'),
                        ),
                        if (!_noExpiry)
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _expiresAt == null
                                      ? 'Not set'
                                      : 'Expires: ${_expiresAt!.toLocal().toString().split(' ').first}',
                                ),
                              ),
                              TextButton.icon(
                                onPressed: () => _pickExpiry(context),
                                icon: const Icon(Icons.event_outlined),
                                label: const Text('Pick date'),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // PASSPHRASE
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Protection', style: theme.textTheme.titleMedium),
                        TextFormField(
                          controller: _passCtrl,
                          decoration: InputDecoration(
                            labelText: 'Passphrase *',
                            suffixIcon: IconButton(
                              icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                              onPressed: () => setState(() => _obscure = !_obscure),
                            ),
                          ),
                          obscureText: _obscure,
                          validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _pass2Ctrl,
                          decoration: const InputDecoration(labelText: 'Repeat passphrase *'),
                          obscureText: _obscure,
                          validator: (v) => (v != _passCtrl.text) ? 'Passphrases do not match' : null,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _busy ? null : _submit,
                    icon: _busy ? const SizedBox(
                      width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2),
                    ) : const Icon(Icons.vpn_key),
                    label: Text(_busy ? 'Generating…' : 'Generate key'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
