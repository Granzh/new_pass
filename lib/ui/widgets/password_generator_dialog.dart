import 'package:flutter/material.dart';

import '../../generated/l10n.dart';
import '../../utils/password_generator.dart';

class PasswordGeneratorDialog extends StatefulWidget {
  const PasswordGeneratorDialog({super.key});

  @override
  State<PasswordGeneratorDialog> createState() => _PasswordGeneratorDialogState();
}

class _PasswordGeneratorDialogState extends State<PasswordGeneratorDialog> {
  final _lengthController = TextEditingController(text: '16');
  bool _includeLower = true;
  bool _includeUpper = true;
  bool _includeDigits = true;
  bool _includeSymbols = true;

  String? _generated;

  void _generate() {
    final length = int.tryParse(_lengthController.text) ?? 16;

    final password = PasswordGenerator.generate(
      length: length,
      includeLower: _includeLower,
      includeUpper: _includeUpper,
      includeDigits: _includeDigits,
      includeSymbols: _includeSymbols,
    );

    setState(() => _generated = password);
  }

  void _apply() {
    Navigator.pop(context, _generated);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    return AlertDialog(
      title: Text(l10n.passwordGeneratorTitle),
        content: SingleChildScrollView(
          child: Column(
            children: [
              Row(
                children: [
                  Text(l10n.length),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 60,
                    child: TextField(
                      controller: _lengthController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(isDense: true),
                    ),
                  ),
                ],
              ),
              CheckboxListTile(
                title: Text(l10n.lowercase),
                value: _includeLower,
                onChanged: (v) => setState(() => _includeLower = v ?? true),
              ),
              CheckboxListTile(
                title: Text(l10n.uppercase),
                value: _includeUpper,
                onChanged: (v) => setState(() => _includeUpper = v ?? true),
              ),
              CheckboxListTile(
                title: Text(l10n.digits),
                value: _includeDigits,
                onChanged: (v) => setState(() => _includeDigits = v ?? true),
              ),
              CheckboxListTile(
                title: Text(l10n.symbols),
                value: _includeSymbols,
                onChanged: (v) => setState(() => _includeSymbols = v ?? true),
              ),
              const SizedBox(height: 12),
              if (_generated != null) SelectableText(_generated!),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: Text(l10n.generatePassword),
                onPressed: _generate,
              ),
            ],
          ),
        ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
        ElevatedButton(
          onPressed: _generated != null ? _apply : null,
          child: Text(l10n.use),
        ),
      ],
    );
  }
}