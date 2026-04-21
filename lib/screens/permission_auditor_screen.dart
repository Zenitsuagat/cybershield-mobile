import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme.dart';
import '../models/scan_models.dart';
import '../services/permission_auditor_service.dart';
import '../widgets/common_widgets.dart';

class PermissionAuditorScreen extends StatefulWidget {
  final void Function(int highCount, int mediumCount)? onAuditComplete;
  const PermissionAuditorScreen({super.key, this.onAuditComplete});

  @override
  State<PermissionAuditorScreen> createState() =>
      _PermissionAuditorScreenState();
}

class _PermissionAuditorScreenState extends State<PermissionAuditorScreen> {
  final _auditor          = PermissionAuditorService();
  List<AppRiskInfo> _apps = [];
  bool _loading           = false;
  bool _scanned           = false;
  String _filterLevel     = 'All';
  String _sortBy          = 'Risk';
  bool _usingRealData     = false;

  static const _channel = MethodChannel('cybershield/installed_apps');

  List<AppRiskInfo> get _filteredApps {
    var list = _apps.where((a) {
      if (_filterLevel == 'All')    return true;
      if (_filterLevel == 'High')   return a.riskLevel == 'high';
      if (_filterLevel == 'Medium') return a.riskLevel == 'medium';
      if (_filterLevel == 'Low')    return a.riskLevel == 'low';
      return true;
    }).toList();
    list.sort((a, b) {
      if (_sortBy == 'Risk') return b.riskScore.compareTo(a.riskScore);
      if (_sortBy == 'Name') return a.appName.compareTo(b.appName);
      return 0;
    });
    return list;
  }

  int get _highCount   => _apps.where((a) => a.riskLevel == 'high').length;
  int get _mediumCount => _apps.where((a) => a.riskLevel == 'medium').length;
  int get _lowCount    => _apps.where((a) => a.riskLevel == 'low').length;

  int get _privacyScore {
    if (_apps.isEmpty) return 100;
    final total = _apps.fold(0, (sum, a) => sum + a.riskScore);
    return (100 - total / _apps.length).clamp(0, 100).toInt();
  }

  Future<void> _runAudit() async {
    setState(() { _loading = true; _scanned = false; _apps = []; });
    await Future.delayed(const Duration(milliseconds: 500));

    List<AppRiskInfo> results = [];
    bool realData = false;

    try {
      final List<dynamic> raw =
      await _channel.invokeMethod('getInstalledApps');
      for (final app in raw) {
        final map   = Map<String, dynamic>.from(app as Map);
        final perms = List<String>.from(map['permissions'] ?? []);
        results.add(_auditor.analyzeApp(
          packageName: map['package_name'] as String? ?? '',
          appName:     map['app_name']     as String? ?? 'Unknown',
          permissions: perms,
        ));
      }
      if (results.isNotEmpty) realData = true;
    } catch (e) {
      debugPrint('Channel error: $e');
    }

    if (results.isEmpty) {
      results = demoApps.map((app) => _auditor.analyzeApp(
        packageName: app['package'] as String,
        appName:     app['name']    as String,
        permissions: List<String>.from(app['perms'] as List),
      )).toList();
      realData = false;
    }

    setState(() {
      _apps          = results;
      _loading       = false;
      _scanned       = true;
      _usingRealData = realData;
    });

    widget.onAuditComplete?.call(_highCount, _mediumCount);
  }

  // ── Open Android app settings for a specific package ─────────────────────
  Future<void> _openAppSettings(String packageName) async {
    try {
      await _channel.invokeMethod('openAppSettings', {'package': packageName});
    } catch (_) {
      // Fallback: show snackbar if channel not updated yet
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Go to Settings → Apps → find the app → Permissions'),
            backgroundColor: kBgCard,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PERMISSION AUDITOR'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_scanned)
            IconButton(
              icon: const Icon(Icons.refresh, color: kAccentCyan),
              onPressed: _runAudit,
            ),
        ],
      ),
      body: Column(children: [
        if (!_scanned && !_loading) _buildStartCard(),
        if (_loading) const Expanded(child: Center(
          child: ScanningIndicator(message: 'Reading granted permissions...'),
        )),
        if (_scanned) ...[
          _buildDataBanner(),
          Expanded(
            child: SingleChildScrollView(
              child: Column(children: [
                _buildPrivacyScoreCard(),
                _buildVsSettingsCard(),
                _buildSummaryBar(),
                _buildFilterBar(),
                _buildAppList(),
                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ]),
    );
  }

  // ── Data source banner ────────────────────────────────────────────────────
  Widget _buildDataBanner() {
    final color = _usingRealData ? kAccentGreen : kAccentAmber;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(children: [
        Icon(_usingRealData ? Icons.verified_rounded : Icons.science_rounded,
            size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            _usingRealData
                ? '✅ Showing GRANTED permissions (${_apps.length} apps scanned)'
                : '🎭 Demo mode — showing sample data',
            style: TextStyle(
                fontSize: 12, color: color, fontWeight: FontWeight.w500),
          ),
        ),
      ]),
    );
  }

  // ── Privacy score card ────────────────────────────────────────────────────
  Widget _buildPrivacyScoreCard() {
    final score = _privacyScore;
    final color = riskColor(score < 45 ? 'high' : score < 70 ? 'medium' : 'low');
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kBgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.35)),
        boxShadow: [BoxShadow(color: color.withOpacity(0.07), blurRadius: 20)],
      ),
      child: Row(children: [
        ScoreRing(score: score, size: 90, label: 'PRIVACY', colorOverride: color),
        const SizedBox(width: 20),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Overall Privacy Score',
                  style: TextStyle(fontSize: 13, color: kTextSecond)),
              const SizedBox(height: 6),
              Text(
                score >= 70
                    ? 'Well Protected'
                    : score >= 45
                    ? 'Some Risks Found'
                    : 'High Risk Device',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700, color: color),
              ),
              const SizedBox(height: 8),
              Text('$_highCount high · $_mediumCount medium · $_lowCount low',
                  style: const TextStyle(fontSize: 12, color: kTextSecond)),
            ])),
      ]),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1);
  }

  // ── VS settings comparison ────────────────────────────────────────────────
  Widget _buildVsSettingsCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kBgCardAlt,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kAccentCyan.withOpacity(0.25)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.auto_awesome, size: 15, color: kAccentCyan),
          SizedBox(width: 8),
          Text('Why CyberShield > Android Settings',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                  color: kAccentCyan)),
        ]),
        const SizedBox(height: 10),
        _vsRow('Shows permissions', 'Shows permissions + risk score'),
        _vsRow('No threat analysis', 'Detects dangerous combos'),
        _vsRow('No ranking', 'Ranks apps by privacy risk'),
        _vsRow('No explanation', 'Explains WHY it\'s risky'),
        _vsRow('No quick action', '↗ Double-tap → open app settings instantly'),
      ]),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _vsRow(String left, String right) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(children: [
        Expanded(child: Row(children: [
          const Icon(Icons.close, size: 12, color: kAccentRed),
          const SizedBox(width: 6),
          Expanded(child: Text(left,
              style: const TextStyle(fontSize: 11, color: kTextSecond))),
        ])),
        const SizedBox(width: 8),
        Expanded(child: Row(children: [
          const Icon(Icons.check_circle, size: 12, color: kAccentGreen),
          const SizedBox(width: 6),
          Expanded(child: Text(right,
              style: const TextStyle(
                  fontSize: 11, color: kTextPrimary,
                  fontWeight: FontWeight.w600))),
        ])),
      ]),
    );
  }

  // ── Summary bar ───────────────────────────────────────────────────────────
  Widget _buildSummaryBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kBgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorderColor),
      ),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('${_apps.length} Apps Scanned',
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700,
                  color: kTextPrimary)),
          Text('${_highCount + _mediumCount} risks found',
              style: TextStyle(
                  fontSize: 13,
                  color: _highCount > 0 ? kAccentRed : kAccentAmber,
                  fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 14),
        Row(children: [
          _SummaryChip(count: _highCount,   label: 'High',   color: kAccentRed),
          const SizedBox(width: 8),
          _SummaryChip(count: _mediumCount, label: 'Medium', color: kAccentAmber),
          const SizedBox(width: 8),
          _SummaryChip(count: _lowCount,    label: 'Low',    color: kAccentGreen),
        ]),
      ]),
    ).animate().fadeIn(delay: 300.ms);
  }

  // ── Filter bar ────────────────────────────────────────────────────────────
  Widget _buildFilterBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['All', 'High', 'Medium', 'Low'].map((f) {
                final selected = _filterLevel == f;
                return GestureDetector(
                  onTap: () => setState(() => _filterLevel = f),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: selected
                          ? kAccentCyan.withOpacity(0.15)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: selected ? kAccentCyan : kBorderColor),
                    ),
                    child: Text(f,
                        style: TextStyle(
                            fontSize: 12,
                            color: selected ? kAccentCyan : kTextSecond,
                            fontWeight: selected
                                ? FontWeight.w600
                                : FontWeight.normal)),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(width: 8),
        DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: _sortBy,
            dropdownColor: kBgCard,
            style: const TextStyle(fontSize: 12, color: kTextSecond),
            items: ['Risk', 'Name']
                .map((s) =>
                DropdownMenuItem(value: s, child: Text('Sort: $s')))
                .toList(),
            onChanged: (v) => setState(() => _sortBy = v!),
          ),
        ),
      ]),
    );
  }

  // ── App list ──────────────────────────────────────────────────────────────
  Widget _buildAppList() {
    final apps = _filteredApps;
    if (apps.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Text('No apps match this filter',
              style: const TextStyle(color: kTextSecond)),
        ),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      itemCount: apps.length,
      itemBuilder: (context, i) => _AppRiskCard(
        app: apps[i],
        isRealData: _usingRealData,
        onOpenSettings: () => _openAppSettings(apps[i].packageName),
      )
          .animate()
          .fadeIn(delay: Duration(milliseconds: i * 40))
          .slideX(begin: 0.08),
    );
  }

  // ── Start card ────────────────────────────────────────────────────────────
  Widget _buildStartCard() {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96, height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: kAccentGreen.withOpacity(0.1),
                border:
                Border.all(color: kAccentGreen.withOpacity(0.3), width: 2),
              ),
              child: const Icon(Icons.security_rounded,
                  size: 44, color: kAccentGreen),
            )
                .animate(onPlay: (c) => c.repeat())
                .shimmer(color: kAccentGreen, duration: 2.seconds),
            const SizedBox(height: 24),
            const Text('App Permission Auditor',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: kTextPrimary),
                textAlign: TextAlign.center),
            const SizedBox(height: 10),
            const Text(
              'Scans GRANTED permissions, detects dangerous combos, and lets you fix risks instantly with a double-tap.',
              style:
              TextStyle(fontSize: 14, color: kTextSecond, height: 1.6),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ...[
              (Icons.camera_alt_rounded,  'Camera + Internet = Can upload silently'),
              (Icons.mic_rounded,          'Microphone + Internet = Can stream audio'),
              (Icons.location_on_rounded, 'Location + Internet = Real-time tracking'),
              (Icons.touch_app_rounded,   'Double-tap any app → open its settings'),
            ].map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(children: [
                Icon(e.$1, size: 16, color: kAccentAmber),
                const SizedBox(width: 10),
                Text(e.$2,
                    style: const TextStyle(
                        fontSize: 13, color: kTextSecond)),
              ]),
            )),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _runAudit,
                icon: const Icon(Icons.search, size: 20),
                label: const Text('SCAN GRANTED PERMISSIONS'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kAccentGreen,
                  foregroundColor: kBgDark,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  textStyle: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      letterSpacing: 1),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Summary Chip ─────────────────────────────────────────────────────────────
class _SummaryChip extends StatelessWidget {
  final int count;
  final String label;
  final Color color;
  const _SummaryChip(
      {required this.count, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(children: [
        Text('$count',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: color)),
        Text(label,
            style:
            TextStyle(fontSize: 11, color: color.withOpacity(0.8))),
      ]),
    ),
  );
}

// ─── Trust Label Badge ────────────────────────────────────────────────────────
class _TrustBadge extends StatelessWidget {
  final TrustLabel label;
  const _TrustBadge(this.label);

  Color get _color {
    switch (label) {
      case TrustLabel.trusted:    return kAccentGreen;
      case TrustLabel.minimal:    return kAccentCyan;
      case TrustLabel.watch:      return kAccentAmber;
      case TrustLabel.suspicious: return kAccentRed;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.13),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _color.withOpacity(0.4)),
      ),
      child: Text(
        '${label.emoji} ${label.display}',
        style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: _color,
            letterSpacing: 0.5),
      ),
    );
  }
}

// ─── App Risk Card ────────────────────────────────────────────────────────────
class _AppRiskCard extends StatefulWidget {
  final AppRiskInfo app;
  final bool isRealData;
  final VoidCallback onOpenSettings;

  const _AppRiskCard({
    required this.app,
    required this.isRealData,
    required this.onOpenSettings,
  });

  @override
  State<_AppRiskCard> createState() => _AppRiskCardState();
}

class _AppRiskCardState extends State<_AppRiskCard> {
  bool _expanded = false;
  bool _tapping  = false; // visual feedback on double-tap

  void _handleDoubleTap() {
    setState(() => _tapping = true);
    Future.delayed(const Duration(milliseconds: 200),
            () => setState(() => _tapping = false));
    widget.onOpenSettings();
  }

  @override
  Widget build(BuildContext context) {
    final app   = widget.app;
    final color = riskColor(app.riskLevel);

    return GestureDetector(
      onTap:       () => setState(() => _expanded = !_expanded),
      onDoubleTap: _handleDoubleTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: _tapping ? kAccentCyan.withOpacity(0.1) : kBgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _tapping
                ? kAccentCyan.withOpacity(0.6)
                : app.riskLevel == 'high'
                ? kAccentRed.withOpacity(0.35)
                : kBorderColor,
            width: _tapping ? 1.5 : 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header row ──────────────────────────────────────────────
                Row(children: [
                  _AppIcon(name: app.appName, color: color),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(app.appName,
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: kTextPrimary)),
                          const SizedBox(height: 2),
                          Text(app.packageName,
                              style: const TextStyle(
                                  fontSize: 10, color: kTextSecond),
                              overflow: TextOverflow.ellipsis),
                        ]),
                  ),
                  const SizedBox(width: 8),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    RiskBadge(app.riskLevel),
                    const SizedBox(height: 4),
                    Text('${app.riskScore}/100',
                        style: TextStyle(
                            fontSize: 11,
                            color: color,
                            fontWeight: FontWeight.w600)),
                  ]),
                  const SizedBox(width: 6),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 18,
                    color: kTextSecond,
                  ),
                ]),

                // ── Trust label row ──────────────────────────────────────────
                const SizedBox(height: 8),
                Row(children: [
                  _TrustBadge(app.trustLabel),
                  const SizedBox(width: 8),
                  if (app.hasExpectedPermissions)
                    Container(
                      padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: kAccentCyan.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: kAccentCyan.withOpacity(0.2)),
                      ),
                      child: const Text('Category matched',
                          style: TextStyle(
                              fontSize: 10,
                              color: kAccentCyan,
                              fontWeight: FontWeight.w500)),
                    ),
                ]),

                // ── Score bar ────────────────────────────────────────────────
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: app.riskScore / 100,
                    minHeight: 5,
                    backgroundColor: kBorderColor,
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ),
                const SizedBox(height: 8),
                Text(app.explanation,
                    style: const TextStyle(
                        fontSize: 12, color: kTextSecond, height: 1.4)),

                // ── Double tap hint ──────────────────────────────────────────
                const SizedBox(height: 6),
                Row(children: [
                  const Icon(Icons.touch_app_rounded,
                      size: 12, color: kTextSecond),
                  const SizedBox(width: 4),
                  const Text('Double-tap to manage permissions in Settings',
                      style: TextStyle(fontSize: 10, color: kTextSecond)),
                ]),

                // ── Expanded section ─────────────────────────────────────────
                if (_expanded) ...[
                  const SizedBox(height: 12),
                  const Divider(color: kBorderColor, height: 1),
                  const SizedBox(height: 12),

                  // Trust label explanation
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: kBgCardAlt,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: kBorderColor),
                    ),
                    child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _TrustBadge(app.trustLabel),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(app.trustLabel.description,
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: kTextSecond,
                                    height: 1.4)),
                          ),
                        ]),
                  ),

                  // Granted permissions label
                  if (widget.isRealData) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: kAccentGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: kAccentGreen.withOpacity(0.3)),
                      ),
                      child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle,
                                size: 13, color: kAccentGreen),
                            SizedBox(width: 6),
                            Text('Showing permissions you GRANTED',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: kAccentGreen,
                                    fontWeight: FontWeight.w600)),
                          ]),
                    ),
                  ],

                  if (app.riskyPermissions.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    const Text('⚠️ UNEXPECTED DANGEROUS PERMISSIONS',
                        style: TextStyle(
                            fontSize: 10,
                            color: kAccentAmber,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8)),
                    const SizedBox(height: 8),
                    Wrap(
                        children: app.riskyPermissions
                            .map((p) => PermChip(p, isDangerous: true))
                            .toList()),
                  ],

                  if (app.permissions.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      widget.isRealData
                          ? '✅ ALL GRANTED PERMISSIONS'
                          : 'ALL PERMISSIONS',
                      style: const TextStyle(
                          fontSize: 10,
                          color: kTextSecond,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      children: app.permissions
                          .map((p) => PermChip(p,
                          isDangerous:
                          app.riskyPermissions.contains(p)))
                          .toList(),
                    ),
                  ],

                  if (app.permissions.isEmpty)
                    const Row(children: [
                      Icon(Icons.verified_user,
                          size: 15, color: kAccentGreen),
                      SizedBox(width: 6),
                      Text('No dangerous permissions granted — safe',
                          style: TextStyle(
                              fontSize: 12, color: kAccentGreen)),
                    ]),

                  // Open settings button
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: widget.onOpenSettings,
                      icon: const Icon(Icons.settings_rounded, size: 15),
                      label: const Text('Open App Permission Settings'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: kAccentCyan,
                        side: BorderSide(
                            color: kAccentCyan.withOpacity(0.4)),
                        padding:
                        const EdgeInsets.symmetric(vertical: 10),
                        textStyle: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ]),
        ),
      ),
    );
  }
}

class _AppIcon extends StatelessWidget {
  final String name;
  final Color color;
  const _AppIcon({required this.name, required this.color});

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Container(
      width: 40, height: 40,
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Center(
          child: Text(initial,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: color))),
    );
  }
}