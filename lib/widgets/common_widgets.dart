import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme.dart';

// ─── Animated Score Ring ──────────────────────────────────────────────────────
class ScoreRing extends StatelessWidget {
  final int score;
  final double size;
  final String? label;
  // Override auto color — pass stateColor from home dashboard so that
  // low security score shows red, not green
  final Color? colorOverride;

  const ScoreRing({
    super.key,
    required this.score,
    this.size = 120,
    this.label,
    this.colorOverride,
  });

  Color get _color {
    if (colorOverride != null) return colorOverride!;
    // Default: higher = more dangerous (URL threat score)
    if (score >= 70) return kAccentRed;
    if (score >= 35) return kAccentAmber;
    return kAccentGreen;
  }

  @override
  Widget build(BuildContext context) {
    final strokeW = size * 0.09;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Custom painter ring — no clipping issues
          CustomPaint(
            size: Size(size, size),
            painter: _RingPainter(
              progress: score / 100,
              color: _color,
              strokeWidth: strokeW,
              bgColor: kBorderColor,
            ),
          ),
          // Centered text — guaranteed inside ring
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$score',
                style: TextStyle(
                  fontSize: size * 0.26,
                  fontWeight: FontWeight.w800,
                  color: _color,
                  height: 1,
                ),
              ),
              if (label != null)
                Text(
                  label!,
                  style: TextStyle(
                    fontSize: size * 0.1,
                    color: kTextSecond,
                    letterSpacing: 0.5,
                  ),
                ),
            ],
          ),
        ],
      ),
    ).animate().scale(duration: 600.ms, curve: Curves.elasticOut);
  }
}

// ─── Ring Painter ─────────────────────────────────────────────────────────────
class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color bgColor;
  final double strokeWidth;

  _RingPainter({
    required this.progress,
    required this.color,
    required this.bgColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    const startAngle = -1.5708; // -90 degrees (top)
    const fullAngle = 6.2832;   // 360 degrees

    // Background ring
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle, fullAngle, false,
      Paint()
        ..color = bgColor
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    if (progress <= 0) return;

    // Foreground ring with gradient
    final sweepAngle = fullAngle * progress.clamp(0.0, 1.0);
    final rect = Rect.fromCircle(center: center, radius: radius);

    final gradPaint = Paint()
      ..shader = SweepGradient(
        startAngle: startAngle,
        endAngle:   startAngle + sweepAngle,
        colors: [color.withOpacity(0.6), color],
      ).createShader(rect)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, startAngle, sweepAngle, false, gradPaint);
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color;
}

// ─── Risk Badge ───────────────────────────────────────────────────────────────
class RiskBadge extends StatelessWidget {
  final String level;
  const RiskBadge(this.level, {super.key});

  @override
  Widget build(BuildContext context) {
    final color = riskColor(level);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(riskIcon(level), size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            level.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Section Header ───────────────────────────────────────────────────────────
class SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  const SectionHeader({super.key, required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: kAccentCyan),
        const SizedBox(width: 8),
        Text(title, style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }
}

// ─── Glowing Card ─────────────────────────────────────────────────────────────
class GlowCard extends StatelessWidget {
  final Widget child;
  final Color? glowColor;
  final EdgeInsets? padding;

  const GlowCard({
    super.key,
    required this.child,
    this.glowColor,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kBgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (glowColor ?? kBorderColor).withOpacity(0.4),
        ),
        boxShadow: glowColor != null
            ? [
          BoxShadow(
            color: glowColor!.withOpacity(0.08),
            blurRadius: 20,
            spreadRadius: 2,
          )
        ]
            : null,
      ),
      child: child,
    );
  }
}

// ─── Threat Reason Tile ───────────────────────────────────────────────────────
class ReasonTile extends StatelessWidget {
  final String reason;
  final bool isPositive;

  const ReasonTile(this.reason, {super.key, this.isPositive = false});

  @override
  Widget build(BuildContext context) {
    final color = isPositive ? kAccentGreen : kAccentAmber;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isPositive ? Icons.check_circle_outline : Icons.error_outline,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              reason,
              style: TextStyle(fontSize: 13, color: kTextSecond, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Permission Chip ─────────────────────────────────────────────────────────
class PermChip extends StatelessWidget {
  final String label;
  final bool isDangerous;

  const PermChip(this.label, {super.key, this.isDangerous = false});

  @override
  Widget build(BuildContext context) {
    final color = isDangerous ? kAccentAmber : kTextSecond;
    return Container(
      margin: const EdgeInsets.only(right: 6, bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500),
      ),
    );
  }
}

// ─── Scanning Pulse Animation ─────────────────────────────────────────────────
class ScanningIndicator extends StatelessWidget {
  final String message;
  const ScanningIndicator({super.key, this.message = 'Scanning...'});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 24),
        SizedBox(
          width: 48,
          height: 48,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation(kAccentCyan),
          ),
        )
            .animate(onPlay: (c) => c.repeat())
            .shimmer(color: kAccentCyan, duration: 1.5.seconds),
        const SizedBox(height: 12),
        Text(message, style: TextStyle(color: kAccentCyan, fontSize: 13)),
        const SizedBox(height: 24),
      ],
    );
  }
}