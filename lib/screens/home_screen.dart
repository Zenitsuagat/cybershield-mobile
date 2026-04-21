import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme.dart';
import '../models/scan_models.dart';
import '../widgets/common_widgets.dart';
import 'url_scanner_screen.dart';
import 'permission_auditor_screen.dart';

// ── Security state enum ───────────────────────────────────────────────────────
enum _SecurityState {
  notScanned,   // nothing done yet → score = 0, grey
  incomplete,   // only one tool used → amber prompt
  protected,    // both done, no high risks → green
  reviewNeeded, // both done, medium risks only → amber
  atRisk,       // any HIGH risk app OR dangerous URL → red
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  UrlScanResult? _lastScan;
  int  _highRiskApps   = 0;
  int  _mediumRiskApps = 0;
  bool _auditDone      = false;

  // ── State derivation ───────────────────────────────────────────────────────
  bool get _urlScanned  => _lastScan != null;
  bool get _bothDone    => _urlScanned && _auditDone;

  _SecurityState get _state {
    // Nothing done yet
    if (!_urlScanned && !_auditDone) return _SecurityState.notScanned;

    // Only one tool used
    if (!_bothDone) return _SecurityState.incomplete;

    // Both done — evaluate real risk
    final urlDangerous  = _lastScan!.status == 'dangerous';
    final urlSuspicious = _lastScan!.status == 'suspicious';

    if (_highRiskApps > 0 || urlDangerous) return _SecurityState.atRisk;
    if (_mediumRiskApps > 0 || urlSuspicious) return _SecurityState.reviewNeeded;
    return _SecurityState.protected;
  }

  // ── Score: only meaningful after both tools used ──────────────────────────
  int get _score {
    switch (_state) {
      case _SecurityState.notScanned:
      case _SecurityState.incomplete:
        return 0; // shown as "—" not as a number

      case _SecurityState.atRisk:
      // Score sits in 10–35 range
      // More high-risk apps = lower score, but never below 10
        final highPenalty   = (_highRiskApps * 2).clamp(0, 20);
        final urlPenalty    = _lastScan!.status == 'dangerous' ? 5 : 0;
        final raw           = 35 - highPenalty - urlPenalty;
        return raw.clamp(10, 35);

      case _SecurityState.reviewNeeded:
      // Score sits in 36–65 range
        final medPenalty    = (_mediumRiskApps * 1.5).round().clamp(0, 25);
        final urlPenalty    = _lastScan!.status == 'suspicious' ? 4 : 0;
        final raw           = 65 - medPenalty - urlPenalty;
        return raw.clamp(36, 65);

      case _SecurityState.protected:
      // Score sits in 66–100 range
        final urlPenalty    = (_lastScan?.threatScore ?? 0) ~/ 10;
        final raw           = 100 - urlPenalty;
        return raw.clamp(66, 100);
    }
  }

  // ── Label + color per state ────────────────────────────────────────────────
  String get _statusLabel {
    switch (_state) {
      case _SecurityState.notScanned:   return 'NOT SCANNED';
      case _SecurityState.incomplete:   return 'INCOMPLETE';
      case _SecurityState.atRisk:       return 'AT RISK';
      case _SecurityState.reviewNeeded: return 'REVIEW NEEDED';
      case _SecurityState.protected:    return 'PROTECTED';
    }
  }

  String get _statusMessage {
    switch (_state) {
      case _SecurityState.notScanned:
        return 'Run both tools below to get your security score';
      case _SecurityState.incomplete:
        return _urlScanned
            ? 'Run the Permission Auditor to complete your scan'
            : 'Scan a URL to complete your security check';
      case _SecurityState.atRisk:
        return _highRiskApps > 0
            ? '$_highRiskApps app${_highRiskApps > 1 ? "s" : ""} with dangerous permissions detected'
            : 'A dangerous URL was detected in your recent scan';
      case _SecurityState.reviewNeeded:
        return '$_mediumRiskApps app${_mediumRiskApps > 1 ? "s" : ""} need your attention';
      case _SecurityState.protected:
        return 'No significant threats detected — stay vigilant';
    }
  }

  Color get _stateColor {
    switch (_state) {
      case _SecurityState.notScanned:   return kTextSecond;
      case _SecurityState.incomplete:   return kAccentAmber;
      case _SecurityState.atRisk:       return kAccentRed;
      case _SecurityState.reviewNeeded: return kAccentAmber;
      case _SecurityState.protected:    return kAccentGreen;
    }
  }

  IconData get _stateIcon {
    switch (_state) {
      case _SecurityState.notScanned:   return Icons.radar_rounded;
      case _SecurityState.incomplete:   return Icons.pending_rounded;
      case _SecurityState.atRisk:       return Icons.dangerous_rounded;
      case _SecurityState.reviewNeeded: return Icons.warning_amber_rounded;
      case _SecurityState.protected:    return Icons.verified_user_rounded;
    }
  }

  void _onScanComplete(UrlScanResult result) =>
      setState(() => _lastScan = result);

  void _onAuditComplete(int highCount, int mediumCount) => setState(() {
    _highRiskApps   = highCount;
    _mediumRiskApps = mediumCount;
    _auditDone      = true;
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildScoreCard(),
                const SizedBox(height: 16),
                _buildStatsRow(),
                if (_state == _SecurityState.notScanned ||
                    _state == _SecurityState.incomplete) ...[
                  const SizedBox(height: 16),
                  _buildScanPromptCard(),
                ],
                const SizedBox(height: 24),
                _buildSectionTitle('Quick Actions'),
                const SizedBox(height: 12),
                _buildActionCards(),
                const SizedBox(height: 24),
                if (_lastScan != null) ...[
                  _buildSectionTitle('Last URL Scan'),
                  const SizedBox(height: 12),
                  _buildLastScanCard(),
                  const SizedBox(height: 24),
                ],
                _buildTipsCard(),
                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // ── App Bar ───────────────────────────────────────────────────────────────
  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 80,
      floating: true,
      pinned: true,
      backgroundColor: kBgDark,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        title: Row(
          children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: kAccentCyan.withOpacity(0.15),
                border: Border.all(color: kAccentCyan.withOpacity(0.4)),
              ),
              child: const Icon(Icons.shield, size: 16, color: kAccentCyan),
            ),
            const SizedBox(width: 10),
            const Text(
              'CYBERSHIELD',
              style: TextStyle(
                fontFamily: 'Orbitron', fontSize: 15,
                fontWeight: FontWeight.w700, color: kAccentCyan,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.info_outline, color: kTextSecond),
          onPressed: _showAbout,
        ),
      ],
    );
  }

  // ── Score Card ────────────────────────────────────────────────────────────
  Widget _buildScoreCard() {
    final color   = _stateColor;
    final isReady = _bothDone;

    return GlowCard(
      glowColor: color,
      child: Row(children: [
        // Score ring — only show number when both tools done
        isReady
            ? ScoreRing(score: _score, size: 100, label: 'SCORE', colorOverride: _stateColor)
            : _buildEmptyRing(color),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Security Score',
                  style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 4),
              Text(
                _statusMessage,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: color,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 8),
              // State badge
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withOpacity(0.5)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(_stateIcon, size: 12, color: color),
                  const SizedBox(width: 4),
                  Text(
                    _statusLabel,
                    style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w700,
                      color: color, letterSpacing: 0.8,
                    ),
                  ),
                ]),
              ),
            ],
          ),
        ),
      ]),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.2);
  }

  // ── Empty ring shown before any scan ─────────────────────────────────────
  Widget _buildEmptyRing(Color color) {
    return SizedBox(
      width: 100, height: 100,
      child: Stack(alignment: Alignment.center, children: [
        CustomPaint(
          size: const Size(100, 100),
          painter: _EmptyRingPainter(color: kBorderColor),
        ),
        Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(_stateIcon, size: 28, color: color),
          const SizedBox(height: 2),
          Text('—',
              style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.w800,
                color: color, height: 1,
              )),
        ]),
      ]),
    );
  }

  // ── Stats Row ─────────────────────────────────────────────────────────────
  Widget _buildStatsRow() {
    return Row(children: [
      Expanded(
        child: _StatCard(
          icon: Icons.apps_rounded,
          label: 'Risky Apps',
          value: _auditDone ? '$_highRiskApps high' : '—',
          color: _highRiskApps > 0
              ? kAccentRed
              : _auditDone
              ? kAccentGreen
              : kTextSecond,
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: _StatCard(
          icon: Icons.link_rounded,
          label: 'Last URL',
          value: _lastScan?.statusLabel ?? '—',
          color: _lastScan == null
              ? kTextSecond
              : riskColor(_lastScan!.riskLevel),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: _StatCard(
          icon: Icons.security_rounded,
          label: 'Status',
          value: _statusLabel,
          color: _stateColor,
        ),
      ),
    ]).animate().fadeIn(delay: 200.ms, duration: 500.ms);
  }

  // ── Scan prompt card (shown when not fully scanned) ───────────────────────
  Widget _buildScanPromptCard() {
    final bool needsUrl   = !_urlScanned;
    final bool needsAudit = !_auditDone;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kAccentAmber.withOpacity(0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kAccentAmber.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.info_outline_rounded,
                size: 15, color: kAccentAmber),
            const SizedBox(width: 8),
            const Text('Complete your security check',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: kAccentAmber)),
          ]),
          const SizedBox(height: 10),
          if (needsUrl)
            _promptStep('1', 'Scan a URL in the Phishing Detector',
                done: false),
          if (needsAudit)
            _promptStep('2', 'Run the App Permission Auditor',
                done: false),
          if (!needsUrl)
            _promptStep('1', 'URL scan complete ✓', done: true),
          if (!needsAudit)
            _promptStep('2', 'Permission audit complete ✓', done: true),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms);
  }

  Widget _promptStep(String num, String text, {required bool done}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(children: [
        Container(
          width: 20, height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: done
                ? kAccentGreen.withOpacity(0.2)
                : kAccentAmber.withOpacity(0.2),
            border: Border.all(
                color: done ? kAccentGreen : kAccentAmber, width: 1),
          ),
          child: Center(
            child: done
                ? const Icon(Icons.check, size: 12, color: kAccentGreen)
                : Text(num,
                style: const TextStyle(
                    fontSize: 10,
                    color: kAccentAmber,
                    fontWeight: FontWeight.w700)),
          ),
        ),
        const SizedBox(width: 8),
        Text(text,
            style: TextStyle(
                fontSize: 12,
                color: done ? kAccentGreen : kTextSecond)),
      ]),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        fontSize: 11, fontWeight: FontWeight.w700,
        color: kTextSecond, letterSpacing: 1.5,
      ),
    );
  }

  // ── Action Cards ──────────────────────────────────────────────────────────
  Widget _buildActionCards() {
    return Column(children: [
      _ActionCard(
        icon: Icons.travel_explore_rounded,
        title: 'Phishing URL Detector',
        subtitle: 'Check any URL for phishing, malware & suspicious patterns',
        color: kAccentCyan,
        done: _urlScanned,
        onTap: () async {
          final result = await Navigator.push<UrlScanResult>(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  UrlScannerScreen(onScanComplete: _onScanComplete),
            ),
          );
          if (result != null) _onScanComplete(result);
        },
      ),
      const SizedBox(height: 12),
      _ActionCard(
        icon: Icons.security_rounded,
        title: 'App Permission Auditor',
        subtitle: 'Scan installed apps for dangerous permission combinations',
        color: kAccentGreen,
        done: _auditDone,
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PermissionAuditorScreen(
                onAuditComplete: (high, medium) =>
                    _onAuditComplete(high, medium),
              ),
            ),
          );
        },
      ),
    ]).animate().fadeIn(delay: 300.ms, duration: 500.ms);
  }

  // ── Last Scan Card ────────────────────────────────────────────────────────
  Widget _buildLastScanCard() {
    final scan  = _lastScan!;
    final color = riskColor(scan.riskLevel);
    return GlowCard(
      glowColor: color,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(riskIcon(scan.riskLevel), color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(scan.url,
                style: const TextStyle(fontSize: 12, color: kTextSecond),
                overflow: TextOverflow.ellipsis, maxLines: 1),
          ),
          RiskBadge(scan.riskLevel),
        ]),
        const SizedBox(height: 10),
        LinearProgressIndicator(
          value: scan.threatScore / 100,
          backgroundColor: kBorderColor,
          valueColor: AlwaysStoppedAnimation(color),
          borderRadius: BorderRadius.circular(4),
        ),
        const SizedBox(height: 6),
        Text('Threat Score: ${scan.threatScore}/100',
            style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w600)),
      ]),
    ).animate().fadeIn(delay: 400.ms);
  }

  // ── Tips Card ─────────────────────────────────────────────────────────────
  Widget _buildTipsCard() {
    const tips = [
      '🔍 Always verify URLs before entering credentials',
      '📱 Review app permissions after every install',
      '🔒 Use HTTPS sites — avoid plain HTTP',
      '👁 Be suspicious of urgent or alarming messages',
    ];
    return GlowCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SectionHeader(
            title: 'Security Tips',
            icon: Icons.tips_and_updates_rounded),
        const SizedBox(height: 12),
        ...tips.map((t) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(t,
              style: const TextStyle(
                  fontSize: 13, color: kTextSecond, height: 1.5)),
        )),
      ]),
    ).animate().fadeIn(delay: 500.ms);
  }

  void _showAbout() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: kBgCard,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('About CyberShield',
            style: TextStyle(
                color: kAccentCyan,
                fontFamily: 'Orbitron',
                fontSize: 14)),
        content: const Text(
          'CyberShield Mobile helps you detect phishing URLs and audit app permissions to protect your privacy.\n\nVersion 1.0.0\nBuilt with Flutter',
          style: TextStyle(
              color: kTextSecond, fontSize: 13, height: 1.6),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close',
                style: TextStyle(color: kAccentCyan)),
          ),
        ],
      ),
    );
  }
}

// ── Empty ring painter ────────────────────────────────────────────────────────
class _EmptyRingPainter extends CustomPainter {
  final Color color;
  const _EmptyRingPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 6;
    canvas.drawCircle(
      c, r,
      Paint()
        ..color = color
        ..strokeWidth = 8
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(_EmptyRingPainter old) => old.color != color;
}

// ── Stat Card ─────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon, required this.label,
    required this.value, required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kBgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorderColor),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(height: 8),
        Text(value,
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700, color: color)),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(fontSize: 10, color: kTextSecond)),
      ]),
    );
  }
}

// ── Action Card ───────────────────────────────────────────────────────────────
class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final bool done;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon, required this.title, required this.subtitle,
    required this.color, required this.done, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: kBgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: done
                  ? color.withOpacity(0.5)
                  : color.withOpacity(0.3),
              width: done ? 1.5 : 1,
            ),
          ),
          child: Row(children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600,
                          color: kTextPrimary)),
                  const SizedBox(height: 3),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 12, color: kTextSecond)),
                ],
              ),
            ),
            if (done)
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withOpacity(0.15),
                ),
                child: Icon(Icons.check_rounded, color: color, size: 16),
              )
            else
              Icon(Icons.chevron_right, color: color, size: 20),
          ]),
        ),
      ),
    );
  }
}