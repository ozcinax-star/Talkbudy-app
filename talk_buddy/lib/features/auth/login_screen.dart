import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../data/repositories/learn_providers.dart';
import '../../data/services/profile_service.dart';
import '../shared/widgets/buddy_avatar.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final acc = ref.watch(accountProvider);
    final ctrl = ref.read(accountProvider.notifier);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFEEF0FF), Color(0xFFF7F8FC)],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, c) {
              final compact = c.maxHeight < 700;
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: ListView(
                    shrinkWrap: true,
                    padding: const EdgeInsets.fromLTRB(22, 12, 22, 20),
                    children: [
                      Center(
                        child: BuddyAvatar(
                          mood: BuddyMood.happy,
                          size: compact ? 84 : 106,
                        ),
                      ),
                      const Center(
                        child: Text(
                          'Talk Buddy',
                          style: TextStyle(
                            fontSize: 31,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      const Center(
                        child: Text(
                          'Çünkü her çocuk anlaşılmayı hak eder.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.inkSoft,
                          ),
                        ),
                      ),
                      SizedBox(height: compact ? 20 : 30),

                      _RoleTile(
                        role: AccountRole.child,
                        subtitle: acc.activeChild == null
                            ? 'Buddy ile öğrenmeye başla'
                            : '${acc.activeChild!.avatar}  '
                                '${acc.activeChild!.name} olarak devam et',
                        color: AppColors.brand,
                        onTap: () {
                          ctrl.setRole(AccountRole.child);
                          context.go('/child');
                        },
                        onLongPress: acc.children.length > 1
                            ? () => _pickChild(context, ref)
                            : null,
                      ),
                      const SizedBox(height: 10),
                      _RoleTile(
                        role: AccountRole.parent,
                        subtitle: 'Gelişimi takip et, raporları gör',
                        color: AppColors.mint,
                        locked: acc.parentPinSet,
                        onTap: () => _enter(context, ref, AccountRole.parent),
                      ),
                      const SizedBox(height: 10),
                      _RoleTile(
                        role: AccountRole.teacher,
                        subtitle: 'Sınıfını yönet, öğrencileri izle',
                        color: AppColors.grape,
                        locked: acc.teacherPinSet,
                        onTap: () => _enter(context, ref, AccountRole.teacher),
                      ),

                      const SizedBox(height: 18),
                      Center(
                        child: TextButton.icon(
                          onPressed: () => context.push('/settings'),
                          icon: const Icon(Icons.settings_outlined, size: 18),
                          label: const Text('Ayarlar'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.inkSoft,
                          ),
                        ),
                      ),
                      const Center(
                        child: Text(
                          'Beta 0.9.0 · Talk Buddy bir tanı aracı değildir.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            height: 1.5,
                            color: AppColors.inkSoft,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _enter(
    BuildContext context,
    WidgetRef ref,
    AccountRole role,
  ) async {
    final ctrl = ref.read(accountProvider.notifier);
    final target = role == AccountRole.teacher ? '/teacher' : '/parent';

    if (!ctrl.hasPin(role)) {
      final set = await showDialog<bool>(
        context: context,
        builder: (_) => PinDialog(role: role, mode: PinMode.create),
      );
      if (set != true || !context.mounted) return;
      ctrl.setRole(role);
      context.go(target);
      return;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => PinDialog(role: role, mode: PinMode.verify),
    );
    if (ok != true || !context.mounted) return;
    ctrl.setRole(role);
    context.go(target);
  }

  Future<void> _pickChild(BuildContext context, WidgetRef ref) async {
    final acc = ref.read(accountProvider);
    final chosen = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 18, 20, 10),
              child: Text(
                'Kim çalışacak?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
            ),
            ...acc.children.map(
              (c) => ListTile(
                leading: Text(c.avatar, style: const TextStyle(fontSize: 26)),
                title: Text(
                  c.name,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(c.ageLabel),
                trailing: c.id == acc.activeChild?.id
                    ? const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.brand,
                      )
                    : null,
                onTap: () => Navigator.pop(ctx, c.id),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );

    if (chosen != null) {
      await ref.read(accountProvider.notifier).selectChild(chosen);
    }
  }
}

class _RoleTile extends StatelessWidget {
  final AccountRole role;
  final String subtitle;
  final Color color;
  final bool locked;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _RoleTile({
    required this.role,
    required this.subtitle,
    required this.color,
    required this.onTap,
    this.locked = false,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            boxShadow: kCardShadow,
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Text(role.emoji, style: const TextStyle(fontSize: 25)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          role.label,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (locked) ...[
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.lock_rounded,
                            size: 14,
                            color: AppColors.inkSoft,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.inkSoft,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_rounded,
                color: AppColors.inkSoft,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum PinMode { create, verify, change }

class PinDialog extends ConsumerStatefulWidget {
  final AccountRole role;
  final PinMode mode;

  const PinDialog({super.key, required this.role, required this.mode});

  @override
  ConsumerState<PinDialog> createState() => _PinDialogState();
}

class _PinDialogState extends ConsumerState<PinDialog> {
  final _first = TextEditingController();
  final _second = TextEditingController();
  String? _error;
  int _tries = 0;

  @override
  void dispose() {
    _first.dispose();
    _second.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final ctrl = ref.read(accountProvider.notifier);
    final pin = _first.text.trim();

    if (pin.length != 4) {
      setState(() => _error = 'PIN 4 haneli olmalı');
      return;
    }

    if (widget.mode == PinMode.verify) {
      if (ctrl.verifyPin(widget.role, pin)) {
        if (mounted) Navigator.pop(context, true);
      } else {
        _tries++;
        setState(() {
          _error = _tries >= 3
              ? 'PIN yanlış. Ayarlardan sıfırlayabilirsiniz.'
              : 'PIN yanlış, tekrar deneyin';
        });
        _first.clear();
      }
      return;
    }

    if (_second.text.trim() != pin) {
      setState(() => _error = 'İki PIN aynı değil');
      return;
    }

    await ctrl.setPin(widget.role, pin);
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final creating = widget.mode != PinMode.verify;

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      title: Text(
        creating
            ? '${widget.role.label} PIN oluştur'
            : '${widget.role.label} girişi',
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            creating
                ? '4 haneli bir PIN belirleyin. Bu PIN yalnızca bu cihazda '
                    'saklanır ve çocuğun panele girmesini engeller.'
                : 'Devam etmek için 4 haneli PIN\'inizi girin.',
            style: const TextStyle(fontSize: 13.5, height: 1.45),
          ),
          const SizedBox(height: 18),
          _PinField(
            controller: _first,
            hint: creating ? 'Yeni PIN' : 'PIN',
            autofocus: true,
            onSubmit: creating ? null : _submit,
          ),
          if (creating) ...[
            const SizedBox(height: 12),
            _PinField(
              controller: _second,
              hint: 'PIN tekrar',
              onSubmit: _submit,
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(
              _error!,
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.danger,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Vazgeç'),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(creating ? 'Kaydet' : 'Giriş'),
        ),
      ],
    );
  }
}

class _PinField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool autofocus;
  final VoidCallback? onSubmit;

  const _PinField({
    required this.controller,
    required this.hint,
    this.autofocus = false,
    this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: autofocus,
      keyboardType: TextInputType.number,
      obscureText: true,
      maxLength: 4,
      textAlign: TextAlign.center,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: const TextStyle(fontSize: 22, letterSpacing: 10),
      onSubmitted: onSubmit == null ? null : (_) => onSubmit!(),
      decoration: InputDecoration(
        hintText: hint,
        counterText: '',
        hintStyle: const TextStyle(fontSize: 14, letterSpacing: 0),
      ),
    );
  }
}
