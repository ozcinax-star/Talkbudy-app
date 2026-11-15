import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';

Future<void> showParentGate(BuildContext context) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (_) => const _ParentGateDialog(),
  );
  if (ok == true && context.mounted) context.go('/parent');
}

class _ParentGateDialog extends StatefulWidget {
  const _ParentGateDialog();

  @override
  State<_ParentGateDialog> createState() => _ParentGateDialogState();
}

class _ParentGateDialogState extends State<_ParentGateDialog> {
  late final int _a;
  late final int _b;
  final _ctrl = TextEditingController();
  String? _error;

  @override
  void initState() {
    super.initState();
    final r = Random();
    _a = 6 + r.nextInt(7);
    _b = 6 + r.nextInt(7);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (int.tryParse(_ctrl.text.trim()) == _a * _b) {
      Navigator.of(context).pop(true);
    } else {
      setState(() => _error = 'Yanlış, tekrar deneyin');
      _ctrl.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      title: const Text('Ebeveyn Girişi'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Devam etmek için soruyu yanıtlayın.'),
          const SizedBox(height: 18),
          Center(
            child: Text(
              '$_a × $_b = ?',
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _ctrl,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            textAlign: TextAlign.center,
            autofocus: true,
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(hintText: 'Cevap', errorText: _error),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Vazgeç'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Devam')),
      ],
    );
  }
}
