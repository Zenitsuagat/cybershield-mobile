import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme.dart';
import '../models/scan_models.dart';
import '../widgets/common_widgets.dart';
import 'url_scanner_screen.dart';
import 'permission_auditor_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  UrlScanResult? _lastScan;
  int _riskyAppsCount = 0;

  // Overall security score derived from last scan + risky apps
  int get _overallScore {
    int score = 100;
    if (_lastScan != null) {
      score -= (_lastScan!.threatScore * 0.5).round();
    }
    score -= (_riskyAppsCount * 5).clamp(0, 30);
    return score.clamp(0, 100);
  }

  String get _overallRisk {
    final s = _overallScore;
    if (s >= 75) return 'low';
    if (s >= 45) return 'medium';
    return 'high';
  }

  void _onScanComplete(UrlScanResult result) {
    setState(() => _lastScan = result);
  }

  void _onAuditComplete(int riskyCount) {
    setState(() => _riskyAppsCount = riskyCount);
  }

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
              width: 32,
              height: 32,
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
                fontFamily: 'Orbitron',
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: kAccentCyan,
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

  Widget _buildScoreCard() {
    final color = riskColor(_overallRisk);
    return GlowCard(
      glowColor: color,
      child: Row(
        children: [
          ScoreRing(score: _overallScore, size: 100, label: 'SCORE'),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Security Score',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  _overallScore >= 75
                      ? 'You\'re well protected'
                      : _overallScore >= 45
                      ? 'Some risks detected'
                      : 'Attention required',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                const SizedBox(height: 8),
                RiskBadge(_overallRisk),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.2);
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.apps_rounded,
            label: 'Risky Apps',
            value: '$_riskyAppsCount',
            color: _riskyAppsCount > 0 ? kAccentAmber : kAccentGreen,
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
            value: _overallRisk == 'low' ? 'SAFE' : 'CHECK',
            color: riskColor(_overallRisk),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 200.ms, duration: 500.ms);
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: kTextSecond,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildActionCards() {
    return Column(
      children: [
        _ActionCard(
          icon: Icons.travel_explore_rounded,
          title: 'Phishing URL Detector',
          subtitle: 'Check any URL for phishing, malware, and suspicious patterns',
          color: kAccentCyan,
          onTap: () async {
            final result = await Navigator.push<UrlScanResult>(
              context,
              MaterialPageRoute(
                builder: (_) => UrlScannerScreen(onScanComplete: _onScanComplete),
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
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PermissionAuditorScreen(
                  onAuditComplete: _onAuditComplete,
                ),
              ),
            );
          },
        ),
      ],
    ).animate().fadeIn(delay: 300.ms, duration: 500.ms);
  }

  Widget _buildLastScanCard() {
    final scan = _lastScan!;
    final color = riskColor(scan.riskLevel);
    return GlowCard(
      glowColor: color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(riskIcon(scan.riskLevel), color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  scan.url,
                  style: const TextStyle(fontSize: 12, color: kTextSecond),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              RiskBadge(scan.riskLevel),
            ],
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: scan.threatScore / 100,
            backgroundColor: kBorderColor,
            valueColor: AlwaysStoppedAnimation(color),
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 6),
          Text(
            'Threat Score: ${scan.threatScore}/100',
            style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms);
  }

  Widget _buildTipsCard() {
    const tips = [
      '🔍 Always verify URLs before entering credentials',
      '📱 Review app permissions after every install',
      '🔒 Use HTTPS sites — avoid plain HTTP',
      '👁 Be suspicious of urgent or alarming messages',
    ];
    return GlowCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Security Tips',
            icon: Icons.tips_and_updates_rounded,
          ),
          const SizedBox(height: 12),
          ...tips.map((t) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(t,
                style: const TextStyle(fontSize: 13, color: kTextSecond, height: 1.5)),
          )),
        ],
      ),
    ).animate().fadeIn(delay: 500.ms);
  }

  void _showAbout() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: kBgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('About CyberShield',
            style: TextStyle(color: kAccentCyan, fontFamily: 'Orbitron', fontSize: 14)),
        content: const Text(
          'CyberShield Mobile helps you detect phishing URLs and audit app permissions to protect your privacy.\n\nVersion 1.0.0\nBuilt with Flutter',
          style: TextStyle(color: kTextSecond, fontSize: 13, height: 1.6),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: kAccentCyan)),
          ),
        ],
      ),
    );
  }
}

// ─── Mini Stat Card ───────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: color,
              )),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(fontSize: 10, color: kTextSecond)),
        ],
      ),
    );
  }
}

// ─── Action Card ─────────────────────────────────────────────────────────────
class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
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
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
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
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: kTextPrimary)),
                    const SizedBox(height: 3),
                    Text(subtitle,
                        style:
                        const TextStyle(fontSize: 12, color: kTextSecond)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: color, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}