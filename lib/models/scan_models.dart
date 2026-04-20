class UrlScanResult {
  final String url;
  final int threatScore;
  final String status;
  final List<String> reasons;
  final bool apiChecked;
  final DateTime scannedAt;

  UrlScanResult({
    required this.url,
    required this.threatScore,
    required this.status,
    required this.reasons,
    required this.apiChecked,
    DateTime? scannedAt,
  }) : scannedAt = scannedAt ?? DateTime.now();

  String get statusLabel {
    switch (status) {
      case 'dangerous':  return 'DANGEROUS';
      case 'suspicious': return 'SUSPICIOUS';
      default:           return 'SAFE';
    }
  }

  String get riskLevel {
    if (threatScore >= 70) return 'high';
    if (threatScore >= 35) return 'medium';
    return 'low';
  }
}

// ── Trust Label enum ──────────────────────────────────────────────────────────
enum TrustLabel {
  trusted,    // Known system/Google app with expected permissions
  minimal,    // Very few or no permissions — very safe
  watch,      // Some risky combos but not alarming
  suspicious; // Unknown app + dangerous combos

  String get display {
    switch (this) {
      case TrustLabel.trusted:    return 'TRUSTED';
      case TrustLabel.minimal:    return 'MINIMAL';
      case TrustLabel.watch:      return 'WATCH';
      case TrustLabel.suspicious: return 'SUSPICIOUS';
    }
  }

  String get emoji {
    switch (this) {
      case TrustLabel.trusted:    return '✅';
      case TrustLabel.minimal:    return '📦';
      case TrustLabel.watch:      return '⚠️';
      case TrustLabel.suspicious: return '🚨';
    }
  }

  String get description {
    switch (this) {
      case TrustLabel.trusted:
        return 'Well-known app with expected permissions for its category';
      case TrustLabel.minimal:
        return 'Requests very few permissions — low risk profile';
      case TrustLabel.watch:
        return 'Has some risky permissions — worth reviewing';
      case TrustLabel.suspicious:
        return 'Unknown app with dangerous permission combinations';
    }
  }
}

class AppRiskInfo {
  final String packageName;
  final String appName;
  final List<String> permissions;
  final int riskScore;
  final String riskLevel;
  final String explanation;
  final List<String> riskyPermissions;
  final TrustLabel trustLabel;        // ← NEW
  final bool hasExpectedPermissions;  // ← NEW: true = perms match app category

  AppRiskInfo({
    required this.packageName,
    required this.appName,
    required this.permissions,
    required this.riskScore,
    required this.riskLevel,
    required this.explanation,
    required this.riskyPermissions,
    required this.trustLabel,
    required this.hasExpectedPermissions,
  });
}