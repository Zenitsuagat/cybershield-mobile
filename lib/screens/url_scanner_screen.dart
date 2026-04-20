import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme.dart';
import '../models/scan_models.dart';
import '../services/url_scanner_service.dart';
import '../widgets/common_widgets.dart';

class UrlScannerScreen extends StatefulWidget {
  final void Function(UrlScanResult)? onScanComplete;

  const UrlScannerScreen({super.key, this.onScanComplete});

  @override
  State<UrlScannerScreen> createState() => _UrlScannerScreenState();
}

class _UrlScannerScreenState extends State<UrlScannerScreen> {
  final _controller = TextEditingController();
  final _scanner    = UrlScannerService();
  UrlScanResult? _result;
  bool _scanning = false;
  String? _error;

  Future<void> _scan([String? url]) async {
    final target = url ?? _controller.text.trim();
    if (target.isEmpty) return;
    if (url != null) _controller.text = url;

    setState(() {
      _scanning = true;
      _result   = null;
      _error    = null;
    });

    try {
      final result = await _scanner.scan(target);
      setState(() {
        _result   = result;
        _scanning = false;
      });
      widget.onScanComplete?.call(result);
    } catch (e) {
      setState(() {
        _error    = 'Scan failed: ${e.toString()}';
        _scanning = false;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('URL SCANNER'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context, _result),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildInputCard(),
            const SizedBox(height: 16),
            _buildDemoSection(),
            const SizedBox(height: 16),
            if (_scanning) const ScanningIndicator(message: 'Analyzing URL...'),
            if (_error != null) _buildError(),
            if (_result != null) ...[
              _buildResultCard(),
              const SizedBox(height: 16),
              _buildReasonsCard(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInputCard() {
    return GlowCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Enter URL to Check',
            icon: Icons.travel_explore_rounded,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            style: const TextStyle(color: kTextPrimary, fontSize: 13),
            decoration: const InputDecoration(
              hintText: 'https://example.com or paste any URL...',
              prefixIcon: Icon(Icons.link, color: kAccentCyan, size: 18),
            ),
            keyboardType: TextInputType.url,
            onSubmitted: (_) => _scan(),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _scanning ? null : () => _scan(),
              icon: const Icon(Icons.search, size: 18),
              label: const Text('SCAN URL'),
              style: ElevatedButton.styleFrom(
                backgroundColor: kAccentCyan,
                foregroundColor: kBgDark,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDemoSection() {
    return GlowCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Demo URLs — Tap to Test',
            icon: Icons.science_rounded,
          ),
          const SizedBox(height: 10),
          ...demoUrls.map((url) => _DemoUrlTile(url: url, onTap: _scan)),
        ],
      ),
    );
  }

  Widget _buildError() {
    return GlowCard(
      glowColor: kAccentRed,
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: kAccentRed),
          const SizedBox(width: 10),
          Expanded(
            child: Text(_error!, style: const TextStyle(color: kAccentRed, fontSize: 13)),
          ),
        ],
      ),
    ).animate().shake();
  }

  Widget _buildResultCard() {
    final r = _result!;
    final color = riskColor(r.riskLevel);

    return GlowCard(
      glowColor: color,
      child: Column(
        children: [
          Row(
            children: [
              ScoreRing(score: r.threatScore, size: 90, label: 'THREAT'),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RiskBadge(r.riskLevel),
                    const SizedBox(height: 8),
                    Text(
                      r.statusLabel,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: color,
                        fontFamily: 'Orbitron',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          r.apiChecked ? Icons.cloud_done_rounded : Icons.memory_rounded,
                          size: 12,
                          color: r.apiChecked ? kAccentGreen : kAccentAmber,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          r.apiChecked
                              ? 'Safe Browsing API + heuristics'
                              : 'Heuristic analysis only (no API key)',
                          style: TextStyle(
                            fontSize: 11,
                            color: r.apiChecked ? kAccentGreen : kAccentAmber,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: kBorderColor),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.link, size: 14, color: kTextSecond),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  r.url,
                  style: const TextStyle(fontSize: 11, color: kTextSecond),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.95, 0.95));
  }

  Widget _buildReasonsCard() {
    final r = _result!;
    final isClean = r.status == 'safe';

    return GlowCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Analysis Details',
            icon: Icons.analytics_rounded,
          ),
          const SizedBox(height: 12),
          ...r.reasons.map((reason) => ReasonTile(
            reason,
            isPositive: isClean,
          )),
          const SizedBox(height: 8),
          const Divider(color: kBorderColor),
          const SizedBox(height: 8),
          _buildScoreBreakdown(r),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildScoreBreakdown(UrlScanResult r) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'THREAT SCORE BREAKDOWN',
          style: const TextStyle(
            fontSize: 10, color: kTextSecond, letterSpacing: 1.2, fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: r.threatScore / 100,
            minHeight: 10,
            backgroundColor: kBorderColor,
            valueColor: AlwaysStoppedAnimation(riskColor(r.riskLevel)),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('0 (Safe)', style: TextStyle(fontSize: 10, color: kTextSecond)),
            Text(
              '${r.threatScore}/100',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: riskColor(r.riskLevel),
              ),
            ),
            const Text('100 (Danger)', style: TextStyle(fontSize: 10, color: kTextSecond)),
          ],
        ),
      ],
    );
  }
}

class _DemoUrlTile extends StatelessWidget {
  final String url;
  final void Function(String) onTap;

  const _DemoUrlTile({required this.url, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onTap(url),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 4),
        child: Row(
          children: [
            const Icon(Icons.link_rounded, size: 14, color: kAccentCyan),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                url,
                style: const TextStyle(fontSize: 12, color: kTextSecond),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.chevron_right, size: 14, color: kTextSecond),
          ],
        ),
      ),
    );
  }
}