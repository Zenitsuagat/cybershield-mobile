import '../models/scan_models.dart';

class PermissionAuditorService {

  // ── Dangerous permission base scores ──────────────────────────────────────
  static const _dangerousPerms = {
    'CAMERA':                  30,
    'RECORD_AUDIO':            30,
    'ACCESS_FINE_LOCATION':    25,
    'ACCESS_COARSE_LOCATION':  15,
    'READ_CONTACTS':           20,
    'READ_CALL_LOG':           25,
    'READ_SMS':                30,
    'SEND_SMS':                20,
    'PROCESS_OUTGOING_CALLS':  25,
    'READ_EXTERNAL_STORAGE':   10,
    'WRITE_EXTERNAL_STORAGE':  10,
    'GET_ACCOUNTS':            15,
    'USE_BIOMETRIC':           20,
    'READ_PHONE_STATE':        15,
    'BODY_SENSORS':            20,
    'ACTIVITY_RECOGNITION':    15,
    'BLUETOOTH_SCAN':          10,
    'BLUETOOTH_CONNECT':       10,
    'INTERNET':                 0,
  };

  // ── Permission display labels ─────────────────────────────────────────────
  static const _permLabels = {
    'CAMERA':                  'Camera',
    'RECORD_AUDIO':            'Microphone',
    'ACCESS_FINE_LOCATION':    'Precise Location',
    'ACCESS_COARSE_LOCATION':  'Approximate Location',
    'READ_CONTACTS':           'Contacts',
    'READ_CALL_LOG':           'Call Log',
    'READ_SMS':                'SMS Read',
    'SEND_SMS':                'SMS Send',
    'PROCESS_OUTGOING_CALLS':  'Call Intercept',
    'READ_EXTERNAL_STORAGE':   'Read Storage',
    'WRITE_EXTERNAL_STORAGE':  'Write Storage',
    'GET_ACCOUNTS':            'Account Access',
    'USE_BIOMETRIC':           'Biometrics',
    'READ_PHONE_STATE':        'Phone State',
    'BODY_SENSORS':            'Body Sensors',
    'ACTIVITY_RECOGNITION':    'Activity Recognition',
    'BLUETOOTH_SCAN':          'Bluetooth Scan',
    'BLUETOOTH_CONNECT':       'Bluetooth Connect',
    'INTERNET':                'Internet',
  };

  // ── App Category definitions ──────────────────────────────────────────────
  // Each category: package keywords → expected permissions (these DON'T add risk)
  static const _appCategories = <String, _AppCategory>{
    'camera': _AppCategory(
      keywords: ['camera', 'photo', 'picture', 'selfie', 'snap', 'cam', 'gcam'],
      expectedPerms: {'CAMERA', 'RECORD_AUDIO', 'READ_EXTERNAL_STORAGE',
        'WRITE_EXTERNAL_STORAGE', 'ACCESS_FINE_LOCATION',
        'READ_MEDIA_IMAGES', 'READ_MEDIA_VIDEO'},
      label: 'Camera App',
    ),
    'maps': _AppCategory(
      keywords: ['maps', 'navigation', 'gps', 'waze', 'here', 'transit',
        'directions', 'location', 'geo'],
      expectedPerms: {'ACCESS_FINE_LOCATION', 'ACCESS_COARSE_LOCATION',
        'ACCESS_BACKGROUND_LOCATION', 'INTERNET',
        'ACTIVITY_RECOGNITION'},
      label: 'Navigation App',
    ),
    'music': _AppCategory(
      keywords: ['music', 'spotify', 'player', 'audio', 'podcast', 'radio',
        'soundcloud', 'youtube', 'media', 'song'],
      expectedPerms: {'RECORD_AUDIO', 'READ_EXTERNAL_STORAGE', 'INTERNET',
        'BLUETOOTH_CONNECT', 'READ_MEDIA_AUDIO'},
      label: 'Media App',
    ),
    'voicerecorder': _AppCategory(
      keywords: ['recorder', 'voice', 'dictaphone', 'memo', 'record'],
      expectedPerms: {'RECORD_AUDIO', 'WRITE_EXTERNAL_STORAGE',
        'READ_EXTERNAL_STORAGE'},
      label: 'Voice Recorder',
    ),
    'messaging': _AppCategory(
      keywords: ['whatsapp', 'telegram', 'signal', 'messenger', 'chat',
        'sms', 'message', 'viber', 'line', 'skype'],
      expectedPerms: {'CAMERA', 'RECORD_AUDIO', 'READ_CONTACTS', 'READ_SMS',
        'SEND_SMS', 'ACCESS_FINE_LOCATION', 'INTERNET',
        'READ_EXTERNAL_STORAGE', 'WRITE_EXTERNAL_STORAGE',
        'PROCESS_OUTGOING_CALLS', 'BLUETOOTH_CONNECT'},
      label: 'Messaging App',
    ),
    'contacts': _AppCategory(
      keywords: ['contacts', 'dialer', 'phone', 'calls', 'truecaller'],
      expectedPerms: {'READ_CONTACTS', 'WRITE_CONTACTS', 'READ_CALL_LOG',
        'PROCESS_OUTGOING_CALLS', 'READ_PHONE_STATE',
        'CALL_PHONE', 'INTERNET'},
      label: 'Phone/Contacts App',
    ),
    'email': _AppCategory(
      keywords: ['gmail', 'email', 'mail', 'outlook', 'inbox', 'proton'],
      expectedPerms: {'READ_CONTACTS', 'INTERNET', 'GET_ACCOUNTS',
        'READ_EXTERNAL_STORAGE', 'CAMERA'},
      label: 'Email App',
    ),
    'social': _AppCategory(
      keywords: ['instagram', 'facebook', 'twitter', 'tiktok', 'snapchat',
        'linkedin', 'pinterest', 'reddit', 'social'],
      expectedPerms: {'CAMERA', 'RECORD_AUDIO', 'READ_CONTACTS', 'INTERNET',
        'ACCESS_FINE_LOCATION', 'READ_EXTERNAL_STORAGE',
        'WRITE_EXTERNAL_STORAGE', 'ACTIVITY_RECOGNITION'},
      label: 'Social Media App',
    ),
    'fitness': _AppCategory(
      keywords: ['fitness', 'health', 'workout', 'steps', 'strava',
        'pedometer', 'sport', 'run', 'gym'],
      expectedPerms: {'BODY_SENSORS', 'ACTIVITY_RECOGNITION',
        'ACCESS_FINE_LOCATION', 'INTERNET'},
      label: 'Fitness App',
    ),
    'browser': _AppCategory(
      keywords: ['chrome', 'firefox', 'browser', 'opera', 'brave',
        'safari', 'edge', 'uc'],
      expectedPerms: {'INTERNET', 'READ_EXTERNAL_STORAGE',
        'WRITE_EXTERNAL_STORAGE', 'ACCESS_FINE_LOCATION',
        'CAMERA', 'RECORD_AUDIO'},
      label: 'Browser',
    ),
    'banking': _AppCategory(
      keywords: ['bank', 'pay', 'wallet', 'finance', 'gpay', 'paytm',
        'phonepe', 'amazon', 'cash'],
      expectedPerms: {'CAMERA', 'USE_BIOMETRIC', 'INTERNET', 'READ_SMS',
        'ACCESS_FINE_LOCATION', 'READ_PHONE_STATE'},
      label: 'Finance App',
    ),
    'scanner': _AppCategory(
      keywords: ['scan', 'qr', 'barcode', 'document', 'ocr', 'pdf'],
      expectedPerms: {'CAMERA', 'READ_EXTERNAL_STORAGE',
        'WRITE_EXTERNAL_STORAGE'},
      label: 'Scanner App',
    ),
  };

  // ── Trusted system/Google packages ────────────────────────────────────────
  static const _trustedPackagePrefixes = [
    'com.google.',
    'com.android.',
    'android.',
    'com.samsung.',
    'com.oneplus.',
    'com.miui.',
    'com.xiaomi.',
    'com.huawei.',
    'com.oppo.',
    'com.realme.',
    'com.vivo.',
    'com.motorola.',
    'com.lge.',
    'com.htc.',
    'com.sony.',
    'com.asus.',
    'com.sec.',
  ];

  String permLabel(String raw) {
    final key = raw
        .replaceAll('android.permission.', '')
        .replaceAll('com.android.voicemail.', '');
    return _permLabels[key] ??
        key
            .replaceAll('_', ' ')
            .toLowerCase()
            .split(' ')
            .map((w) => w.isNotEmpty ? w[0].toUpperCase() + w.substring(1) : '')
            .join(' ');
  }

  // ── Detect app category from package name + app name ─────────────────────
  _AppCategory? _detectCategory(String packageName, String appName) {
    final searchStr = '${packageName.toLowerCase()} ${appName.toLowerCase()}';
    for (final entry in _appCategories.entries) {
      for (final keyword in entry.value.keywords) {
        if (searchStr.contains(keyword)) return entry.value;
      }
    }
    return null;
  }

  // ── Check if package is a trusted system app ──────────────────────────────
  bool _isTrustedPackage(String packageName) {
    return _trustedPackagePrefixes.any((p) => packageName.startsWith(p));
  }

  // ── Main analysis ─────────────────────────────────────────────────────────
  AppRiskInfo analyzeApp({
    required String packageName,
    required String appName,
    required List<String> permissions,
  }) {
    final perms = permissions
        .map((p) => p.replaceAll('android.permission.', '').toUpperCase())
        .toList();

    final hasInternet = perms.contains('INTERNET');
    final hasCamera   = perms.contains('CAMERA');
    final hasMic      = perms.contains('RECORD_AUDIO');
    final hasLocation = perms.contains('ACCESS_FINE_LOCATION') ||
        perms.contains('ACCESS_COARSE_LOCATION');
    final hasSms      = perms.contains('READ_SMS');
    final hasContacts = perms.contains('READ_CONTACTS');
    final hasCallLog  = perms.contains('READ_CALL_LOG');

    // ── Detect category & trusted status ─────────────────────────────────
    final category       = _detectCategory(packageName, appName);
    final isTrustedPkg   = _isTrustedPackage(packageName);
    final expectedPerms  = category?.expectedPerms ?? <String>{};

    // ── Score only UNEXPECTED dangerous permissions ───────────────────────
    int score = 0;
    final riskyPerms   = <String>[];
    final explanations = <String>[];

    for (final p in perms) {
      final pts = _dangerousPerms[p] ?? 0;
      if (pts <= 0) continue;

      // Skip if this permission is expected for the app's category
      if (expectedPerms.contains(p)) continue;

      // Trusted system apps get a 50% score reduction
      final adjustedPts = isTrustedPkg ? (pts * 0.5).round() : pts;
      score += adjustedPts;
      riskyPerms.add(permLabel(p));
    }

    // ── Combo multipliers (only for unexpected combos) ────────────────────
    final camExpected = expectedPerms.contains('CAMERA');
    final micExpected = expectedPerms.contains('RECORD_AUDIO');
    final locExpected = expectedPerms.contains('ACCESS_FINE_LOCATION') ||
        expectedPerms.contains('ACCESS_COARSE_LOCATION');
    final smsExpected = expectedPerms.contains('READ_SMS');
    final conExpected = expectedPerms.contains('READ_CONTACTS');
    final calExpected = expectedPerms.contains('READ_CALL_LOG');

    if (hasInternet) {
      if (hasCamera && !camExpected) {
        score += 20;
        explanations.add('Camera + Internet → can silently upload photos/video');
      }
      if (hasMic && !micExpected) {
        score += 20;
        explanations.add('Microphone + Internet → can stream audio remotely');
      }
      if (hasLocation && !locExpected) {
        score += 15;
        explanations.add('Location + Internet → real-time location tracking possible');
      }
      if (hasSms && !smsExpected) {
        score += 20;
        explanations.add('SMS Access + Internet → can exfiltrate OTP codes');
      }
      if (hasContacts && !conExpected) {
        score += 10;
        explanations.add('Contacts + Internet → address book can be uploaded');
      }
      if (hasCallLog && !calExpected) {
        score += 15;
        explanations.add('Call Log + Internet → call history exposure risk');
      }
    }

    // Trusted packages get overall score capped lower
    if (isTrustedPkg) score = (score * 0.6).round();
    score = score.clamp(0, 100);

    // ── Determine trust label ─────────────────────────────────────────────
    final TrustLabel trustLabel;
    if (isTrustedPkg) {
      trustLabel = TrustLabel.trusted;
    } else if (perms.isEmpty ||
        perms.every((p) => (_dangerousPerms[p] ?? 0) == 0)) {
      trustLabel = TrustLabel.minimal;
    } else if (score >= 55) {
      trustLabel = TrustLabel.suspicious;
    } else {
      trustLabel = TrustLabel.watch;
    }

    // ── Risk level ────────────────────────────────────────────────────────
    final riskLevel = score >= 65 ? 'high' : score >= 35 ? 'medium' : 'low';

    // ── Explanation ───────────────────────────────────────────────────────
    String explanation;
    if (explanations.isNotEmpty) {
      explanation = explanations.first;
    } else if (category != null && riskyPerms.isEmpty) {
      explanation =
      '${category.label} — permissions match expected usage';
    } else if (isTrustedPkg) {
      explanation = 'System/trusted app — risk adjusted accordingly';
    } else if (riskyPerms.isNotEmpty) {
      explanation = 'Requests ${riskyPerms.take(3).join(', ')} permissions';
    } else {
      explanation = 'No dangerous permissions detected';
    }

    return AppRiskInfo(
      packageName:          packageName,
      appName:              appName,
      permissions:          permissions.map(permLabel).toList(),
      riskScore:            score,
      riskLevel:            riskLevel,
      explanation:          explanation,
      riskyPermissions:     riskyPerms,
      trustLabel:           trustLabel,
      hasExpectedPermissions: category != null,
    );
  }
}

// ── Internal category model ───────────────────────────────────────────────────
class _AppCategory {
  final List<String> keywords;
  final Set<String> expectedPerms;
  final String label;
  const _AppCategory({
    required this.keywords,
    required this.expectedPerms,
    required this.label,
  });
}

// ── Demo apps ─────────────────────────────────────────────────────────────────
final demoApps = [
  {
    'package': 'com.google.android.camera',
    'name':    'Camera',
    'perms':   ['CAMERA', 'RECORD_AUDIO', 'ACCESS_FINE_LOCATION',
      'WRITE_EXTERNAL_STORAGE'],
  },
  {
    'package': 'com.flashlight.suspicious',
    'name':    'FlashLight Pro',
    'perms':   ['CAMERA', 'INTERNET', 'READ_CONTACTS', 'ACCESS_FINE_LOCATION'],
  },
  {
    'package': 'com.weather.basic',
    'name':    'Weather Now',
    'perms':   ['ACCESS_COARSE_LOCATION', 'INTERNET'],
  },
  {
    'package': 'com.voicerecorder.free',
    'name':    'Voice Recorder Free',
    'perms':   ['RECORD_AUDIO', 'INTERNET', 'WRITE_EXTERNAL_STORAGE',
      'READ_CONTACTS'],
  },
  {
    'package': 'com.google.android.maps',
    'name':    'Maps & Navigation',
    'perms':   ['ACCESS_FINE_LOCATION', 'INTERNET', 'CAMERA'],
  },
  {
    'package': 'com.notes.simple',
    'name':    'Simple Notes',
    'perms':   ['WRITE_EXTERNAL_STORAGE'],
  },
  {
    'package': 'com.sms.cleaner',
    'name':    'SMS Manager',
    'perms':   ['READ_SMS', 'SEND_SMS', 'INTERNET', 'READ_CONTACTS',
      'READ_CALL_LOG'],
  },
  {
    'package': 'com.calculator.basic',
    'name':    'Calculator',
    'perms':   [],
  },
  {
    'package': 'com.keyboard.free',
    'name':    'Custom Keyboard',
    'perms':   ['INTERNET', 'READ_EXTERNAL_STORAGE', 'GET_ACCOUNTS'],
  },
  {
    'package': 'com.whatsapp',
    'name':    'WhatsApp',
    'perms':   ['CAMERA', 'RECORD_AUDIO', 'READ_CONTACTS', 'READ_SMS',
      'INTERNET', 'ACCESS_FINE_LOCATION'],
  },
];