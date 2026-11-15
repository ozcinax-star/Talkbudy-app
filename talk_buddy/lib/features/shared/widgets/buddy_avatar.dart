import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

enum BuddyMood { idle, listening, talking, thinking, happy }

class BuddyAvatar extends StatefulWidget {
  final BuddyMood mood;
  final double size;

  final double level;

  const BuddyAvatar({
    super.key,
    this.mood = BuddyMood.idle,
    this.size = 180,
    this.level = 0,
  });

  @override
  State<BuddyAvatar> createState() => _BuddyAvatarState();
}

class _BuddyAvatarState extends State<BuddyAvatar>
    with TickerProviderStateMixin {
  late final AnimationController _breath = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..repeat(reverse: true);

  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  late final AnimationController _blink = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 160),
  );

  @override
  void initState() {
    super.initState();
    _scheduleBlink();
  }

  void _scheduleBlink() {
    Future.delayed(Duration(milliseconds: 2200 + math.Random().nextInt(3200)),
        () async {
      if (!mounted) return;
      await _blink.forward();
      await _blink.reverse();
      _scheduleBlink();
    });
  }

  @override
  void dispose() {
    _breath.dispose();
    _pulse.dispose();
    _blink.dispose();
    super.dispose();
  }

  Color get _color => switch (widget.mood) {
        BuddyMood.listening => AppColors.mint,
        BuddyMood.talking => AppColors.brand,
        BuddyMood.thinking => AppColors.grape,
        BuddyMood.happy => AppColors.lemon,
        BuddyMood.idle => AppColors.brand,
      };

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    return SizedBox(
      width: s * 1.6,
      height: s * 1.6,
      child: AnimatedBuilder(
        animation: Listenable.merge([_breath, _pulse, _blink]),
        builder: (context, _) {
          final breath = 1 + _breath.value * 0.045;
          final listening = widget.mood == BuddyMood.listening;

          return Stack(
            alignment: Alignment.center,
            children: [

              if (listening)
                for (var i = 0; i < 3; i++)
                  _Ring(
                    progress: (_pulse.value + i / 3) % 1,
                    color: _color,
                    baseSize: s,
                    boost: widget.level,
                  ),

              Transform.scale(
                scale: breath,
                child: Container(
                  width: s,
                  height: s,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color.lerp(_color, Colors.white, 0.28)!,
                        _color,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _color.withOpacity(0.35),
                        blurRadius: 40,
                        offset: const Offset(0, 14),
                      ),
                    ],
                  ),
                  child: CustomPaint(
                    painter: _FacePainter(
                      mood: widget.mood,
                      blink: _blink.value,
                      talkPhase: _pulse.value,
                    ),
                  ),
                ),
              ),

              if (widget.mood == BuddyMood.thinking)
                Positioned(
                  top: s * 0.06,
                  right: s * 0.12,
                  child: _ThinkingDots(t: _pulse.value, color: _color),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _Ring extends StatelessWidget {
  final double progress;
  final Color color;
  final double baseSize;
  final double boost;

  const _Ring({
    required this.progress,
    required this.color,
    required this.baseSize,
    required this.boost,
  });

  @override
  Widget build(BuildContext context) {
    final scale = 1 + progress * (0.55 + boost * 0.35);
    return Opacity(
      opacity: (1 - progress) * 0.5,
      child: Container(
        width: baseSize * scale,
        height: baseSize * scale,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 3),
        ),
      ),
    );
  }
}

class _FacePainter extends CustomPainter {
  final BuddyMood mood;
  final double blink;
  final double talkPhase;

  _FacePainter({
    required this.mood,
    required this.blink,
    required this.talkPhase,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final eyeY = h * 0.42;
    final eyeDx = w * 0.19;
    final eyeR = w * 0.072;

    final dark = Paint()..color = AppColors.ink;
    final white = Paint()..color = Colors.white;

    for (final sign in [-1, 1]) {
      final cx = w / 2 + sign * eyeDx;
      final openness = (1 - blink).clamp(0.06, 1.0);

      canvas.save();
      canvas.translate(cx, eyeY);
      canvas.scale(1, openness);
      canvas.drawCircle(Offset.zero, eyeR, white);
      canvas.drawCircle(Offset.zero, eyeR * 0.55, dark);

      canvas.drawCircle(
        Offset(-eyeR * 0.22, -eyeR * 0.25),
        eyeR * 0.18,
        white,
      );
      canvas.restore();
    }

    if (mood == BuddyMood.happy || mood == BuddyMood.talking) {
      final cheek = Paint()..color = AppColors.coral.withOpacity(0.35);
      for (final sign in [-1, 1]) {
        canvas.drawCircle(
          Offset(w / 2 + sign * w * 0.30, h * 0.55),
          w * 0.065,
          cheek,
        );
      }
    }

    final mouthY = h * 0.63;
    switch (mood) {
      case BuddyMood.talking:

        final open = (math.sin(talkPhase * math.pi * 6) * 0.5 + 0.5);
        final rect = Rect.fromCenter(
          center: Offset(w / 2, mouthY),
          width: w * 0.22,
          height: w * (0.05 + 0.14 * open),
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, Radius.circular(w * 0.08)),
          dark,
        );
      case BuddyMood.listening:

        canvas.drawCircle(Offset(w / 2, mouthY), w * 0.055, dark);
      case BuddyMood.thinking:

        final p = Paint()
          ..color = AppColors.ink
          ..strokeWidth = w * 0.035
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(
          Offset(w * 0.40, mouthY),
          Offset(w * 0.58, mouthY - h * 0.015),
          p,
        );
      case BuddyMood.idle:
      case BuddyMood.happy:

        final p = Paint()
          ..color = AppColors.ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = w * 0.038
          ..strokeCap = StrokeCap.round;
        final rect = Rect.fromCenter(
          center: Offset(w / 2, mouthY - h * 0.04),
          width: w * 0.30,
          height: h * 0.20,
        );
        canvas.drawArc(rect, 0.25, math.pi - 0.5, false, p);
    }
  }

  @override
  bool shouldRepaint(_FacePainter old) =>
      old.mood != mood || old.blink != blink || old.talkPhase != talkPhase;
}

class _ThinkingDots extends StatelessWidget {
  final double t;
  final Color color;
  const _ThinkingDots({required this.t, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        final phase = (t + i * 0.22) % 1;
        final scale = 0.6 + math.sin(phase * math.pi) * 0.6;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: Transform.scale(
            scale: scale.clamp(0.4, 1.3),
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      }),
    );
  }
}
