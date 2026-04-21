import '../models/scan_models.dart';

class PermissionAuditorService {

  // ── Only permissions that appear in Android Settings as user-toggleable ────
  // Removed: USE_BIOMETRIC, POST_NOTIFICATIONS, INTERNET (not toggleable),
  //          BLUETOOTH_* (shown as "Nearby devices" group, low risk for scoring)
  static const _dangerousPerms = {
    // Camera group
    'CAMERA':                        30,

    // Microphone group
    'RECORD_AUDIO':                  30,

    // Location group
    'ACCESS_FINE_LOCATION':          25,
    'ACCESS_COARSE_LOCATION':        15,
    'ACCESS_BACKGROUND_LOCATION':    20,

    // Contacts group
    'READ_CONTACTS':                 20,

    // Call log group
    'READ_CALL_LOG':                 25,
    'PROCESS_OUTGOING_CALLS':        25,

    // SMS group
    'READ_SMS':                      30,
    'SEND_SMS':                      20,
    'RECEIVE_SMS':                   20,

    // Phone group
    'READ_PHONE_STATE':              15,
    'CALL_PHONE':                    20,

    // Storage — legacy Android 9–12
    'READ_EXTERNAL_STORAGE':         10,
    'WRITE_EXTERNAL_STORAGE':        10,

    // Storage — modern Android 13+
    'READ_MEDIA_IMAGES':             10,
    'READ_MEDIA_VIDEO':              10,
    'READ_MEDIA_AUDIO':              10,

    // Sensors
    'BODY_SENSORS':                  20,
    'BODY_SENSORS_BACKGROUND':       25,
    'ACTIVITY_RECOGNITION':          15,

    // Nearby devices (lower risk, user can see in Settings)
    'BLUETOOTH_SCAN':                 8,
    'BLUETOOTH_CONNECT':              8,
    'BLUETOOTH_ADVERTISE':            8,

    // Accounts
    'GET_ACCOUNTS':                  15,

    // Internet: neutral for scoring but used as combo multiplier
    'INTERNET':                       0,
  };

  // ── Human-readable labels ─────────────────────────────────────────────────
  static const _permLabels = {
    'CAMERA':                    'Camera',
    'RECORD_AUDIO':              'Microphone',
    'ACCESS_FINE_LOCATION':      'Precise Location',
    'ACCESS_COARSE_LOCATION':    'Approx. Location',
    'ACCESS_BACKGROUND_LOCATION':'Background Location',
    'READ_CONTACTS':             'Contacts',
    'READ_CALL_LOG':             'Call Log',
    'PROCESS_OUTGOING_CALLS':    'Outgoing Calls',
    'READ_SMS':                  'Read SMS',
    'SEND_SMS':                  'Send SMS',
    'RECEIVE_SMS':               'Receive SMS',
    'READ_PHONE_STATE':          'Phone State',
    'CALL_PHONE':                'Make Calls',
    'READ_EXTERNAL_STORAGE':     'Read Storage',
    'WRITE_EXTERNAL_STORAGE':    'Write Storage',
    'READ_MEDIA_IMAGES':         'Photos Access',
    'READ_MEDIA_VIDEO':          'Video Access',
    'READ_MEDIA_AUDIO':          'Audio Access',
    'BODY_SENSORS':              'Body Sensors',
    'BODY_SENSORS_BACKGROUND':   'Background Sensors',
    'ACTIVITY_RECOGNITION':      'Activity Recognition',
    'BLUETOOTH_SCAN':            'Nearby Devices (Scan)',
    'BLUETOOTH_CONNECT':         'Nearby Devices (Connect)',
    'BLUETOOTH_ADVERTISE':       'Nearby Devices (Advertise)',
    'GET_ACCOUNTS':              'Account Access',
    'INTERNET':                  'Internet',
    'UWB_RANGING':               'UWB Ranging',
  };

  // ── App categories with EXPECTED permissions (don't penalise these) ────────
  static const _appCategories = <String, _AppCategory>{
    'camera': _AppCategory(
      keywords: ['camera', 'photo', 'picture', 'selfie', 'snap', 'cam',
        'gcam', 'opencamera'],
      expectedPerms: {
        'CAMERA', 'RECORD_AUDIO',
        'ACCESS_FINE_LOCATION', 'ACCESS_COARSE_LOCATION',
        'READ_EXTERNAL_STORAGE', 'WRITE_EXTERNAL_STORAGE',
        'READ_MEDIA_IMAGES', 'READ_MEDIA_VIDEO', 'READ_MEDIA_AUDIO',
        'INTERNET',
      },
      label: 'Camera App',
    ),
    'maps': _AppCategory(
      keywords: ['maps', 'navigation', 'gps', 'waze', 'here', 'transit',
        'directions', 'geo', 'mapmyindia', 'ola', 'uber'],
      expectedPerms: {
        'ACCESS_FINE_LOCATION', 'ACCESS_COARSE_LOCATION',
        'ACCESS_BACKGROUND_LOCATION', 'INTERNET',
        'ACTIVITY_RECOGNITION', 'READ_EXTERNAL_STORAGE',
      },
      label: 'Navigation App',
    ),
    'music': _AppCategory(
      keywords: ['music', 'spotify', 'player', 'podcast', 'radio',
        'soundcloud', 'youtube', 'media', 'gaana', 'jiosaavn',
        'wynk', 'audiomack'],
      expectedPerms: {
        'RECORD_AUDIO', 'READ_EXTERNAL_STORAGE', 'INTERNET',
        'BLUETOOTH_CONNECT', 'BLUETOOTH_SCAN',
        'READ_MEDIA_AUDIO', 'READ_MEDIA_IMAGES',
        'ACTIVITY_RECOGNITION',
      },
      label: 'Media App',
    ),
    'voicerecorder': _AppCategory(
      keywords: ['recorder', 'voice', 'dictaphone', 'memo', 'record',
        'transcribe'],
      expectedPerms: {
        'RECORD_AUDIO', 'WRITE_EXTERNAL_STORAGE',
        'READ_EXTERNAL_STORAGE', 'READ_MEDIA_AUDIO',
      },
      label: 'Voice Recorder',
    ),
    'messaging': _AppCategory(
      keywords: ['whatsapp', 'telegram', 'signal', 'messenger', 'chat',
        'viber', 'line', 'skype', 'imo', 'snapchat', 'discord',
        'message', 'sms', 'mms'],
      expectedPerms: {
        'CAMERA', 'RECORD_AUDIO', 'READ_CONTACTS',
        'READ_SMS', 'SEND_SMS', 'RECEIVE_SMS',
        'ACCESS_FINE_LOCATION', 'ACCESS_COARSE_LOCATION',
        'INTERNET', 'READ_EXTERNAL_STORAGE', 'WRITE_EXTERNAL_STORAGE',
        'READ_MEDIA_IMAGES', 'READ_MEDIA_VIDEO', 'READ_MEDIA_AUDIO',
        'PROCESS_OUTGOING_CALLS', 'BLUETOOTH_CONNECT',
        'READ_PHONE_STATE',
      },
      label: 'Messaging App',
    ),
    'phone': _AppCategory(
      keywords: ['dialer', 'phone', 'calls', 'truecaller', 'contacts',
        'caller', 'incall'],
      expectedPerms: {
        'READ_CONTACTS', 'READ_CALL_LOG', 'PROCESS_OUTGOING_CALLS',
        'READ_PHONE_STATE', 'CALL_PHONE', 'INTERNET',
        'READ_SMS', 'RECEIVE_SMS',
      },
      label: 'Phone/Dialer App',
    ),
    'email': _AppCategory(
      keywords: ['gmail', 'email', 'mail', 'outlook', 'inbox',
        'proton', 'yahoo', 'thunderbird'],
      expectedPerms: {
        'READ_CONTACTS', 'INTERNET', 'GET_ACCOUNTS',
        'READ_EXTERNAL_STORAGE', 'READ_MEDIA_IMAGES',
        'CAMERA',
      },
      label: 'Email App',
    ),
    'social': _AppCategory(
      keywords: ['instagram', 'facebook', 'twitter', 'tiktok', 'linkedin',
        'pinterest', 'reddit', 'social', 'share', 'moj',
        'josh', 'reels'],
      expectedPerms: {
        'CAMERA', 'RECORD_AUDIO', 'READ_CONTACTS', 'INTERNET',
        'ACCESS_FINE_LOCATION', 'ACCESS_COARSE_LOCATION',
        'READ_EXTERNAL_STORAGE', 'WRITE_EXTERNAL_STORAGE',
        'READ_MEDIA_IMAGES', 'READ_MEDIA_VIDEO',
        'ACTIVITY_RECOGNITION', 'BLUETOOTH_CONNECT',
      },
      label: 'Social Media App',
    ),
    'fitness': _AppCategory(
      keywords: ['fitness', 'health', 'workout', 'steps', 'strava',
        'pedometer', 'sport', 'run', 'gym', 'yoga', 'garmin',
        'fitbit', 'healthify'],
      expectedPerms: {
        'BODY_SENSORS', 'BODY_SENSORS_BACKGROUND',
        'ACTIVITY_RECOGNITION', 'ACCESS_FINE_LOCATION', 'INTERNET',
        'BLUETOOTH_SCAN', 'BLUETOOTH_CONNECT',
      },
      label: 'Fitness App',
    ),
    'browser': _AppCategory(
      keywords: ['chrome', 'firefox', 'browser', 'opera', 'brave',
        'edge', 'uc', 'dolphin', 'kiwi', 'via'],
      expectedPerms: {
        'INTERNET', 'READ_EXTERNAL_STORAGE', 'WRITE_EXTERNAL_STORAGE',
        'ACCESS_FINE_LOCATION', 'ACCESS_COARSE_LOCATION',
        'CAMERA', 'RECORD_AUDIO', 'READ_MEDIA_IMAGES',
      },
      label: 'Browser',
    ),
    'banking': _AppCategory(
      keywords: ['bank', 'gpay', 'paytm', 'phonepe', 'bhim', 'upi',
        'wallet', 'finance', 'pay', 'cash', 'cred',
        'mobikwik', 'freecharge'],
      expectedPerms: {
        'CAMERA', 'INTERNET', 'READ_SMS', 'RECEIVE_SMS',
        'ACCESS_FINE_LOCATION', 'ACCESS_COARSE_LOCATION',
        'READ_PHONE_STATE', 'GET_ACCOUNTS', 'READ_CONTACTS',
        'READ_MEDIA_IMAGES',
      },
      label: 'Finance/Payment App',
    ),
    'scanner': _AppCategory(
      keywords: ['scan', 'qr', 'barcode', 'document', 'ocr', 'pdf',
        'adobe', 'camscanner'],
      expectedPerms: {
        'CAMERA', 'READ_EXTERNAL_STORAGE', 'WRITE_EXTERNAL_STORAGE',
        'READ_MEDIA_IMAGES', 'INTERNET',
      },
      label: 'Scanner App',
    ),
    'video': _AppCategory(
      keywords: ['video', 'vlc', 'mx', 'player', 'stream', 'netflix',
        'hotstar', 'prime', 'jio', 'zee5', 'sonyliv'],
      expectedPerms: {
        'INTERNET', 'READ_EXTERNAL_STORAGE', 'READ_MEDIA_VIDEO',
        'READ_MEDIA_AUDIO', 'BLUETOOTH_CONNECT',
        'ACTIVITY_RECOGNITION',
      },
      label: 'Video/Streaming App',
    ),
    'shopping': _AppCategory(
      keywords: ['amazon', 'flipkart', 'myntra', 'shop', 'store',
        'meesho', 'nykaa', 'ajio', 'zomato', 'swiggy'],
      expectedPerms: {
        'CAMERA', 'INTERNET', 'ACCESS_FINE_LOCATION',
        'ACCESS_COARSE_LOCATION', 'READ_CONTACTS',
        'READ_MEDIA_IMAGES', 'BLUETOOTH_CONNECT',
      },
      label: 'Shopping App',
    ),
  };

  // ── Known trusted package prefixes ────────────────────────────────────────
  static const _trustedPrefixes = [
    'com.google.', 'com.android.', 'android.',
    'com.samsung.', 'com.sec.', 'com.oneplus.',
    'com.miui.', 'com.xiaomi.', 'com.huawei.',
    'com.oppo.', 'com.realme.', 'com.vivo.',
    'com.motorola.', 'com.lge.', 'com.sony.',
    'com.asus.', 'com.htc.', 'com.microsoft.',
  ];

  String permLabel(String raw) {
    final key = raw
        .replaceAll('android.permission.', '')
        .toUpperCase();
    return _permLabels[key] ??
        key
            .replaceAll('_', ' ')
            .toLowerCase()
            .split(' ')
            .map((w) => w.isNotEmpty
            ? w[0].toUpperCase() + w.substring(1)
            : '')
            .join(' ');
  }

  _AppCategory? _detectCategory(String pkg, String name) {
    final search = '${pkg.toLowerCase()} ${name.toLowerCase()}';
    for (final entry in _appCategories.entries) {
      for (final kw in entry.value.keywords) {
        if (search.contains(kw)) return entry.value;
      }
    }
    return null;
  }

  bool _isTrusted(String pkg) =>
      _trustedPrefixes.any((p) => pkg.startsWith(p));

  // ── Main analysis ─────────────────────────────────────────────────────────
  AppRiskInfo analyzeApp({
    required String packageName,
    required String appName,
    required List<String> permissions,
  }) {
    // Normalise to uppercase, strip prefix
    final perms = permissions
        .map((p) => p
        .replaceAll('android.permission.', '')
        .toUpperCase())
        .toList();

    final hasInternet = perms.contains('INTERNET');
    final hasCamera   = perms.contains('CAMERA');
    final hasMic      = perms.contains('RECORD_AUDIO');
    final hasLocation = perms.contains('ACCESS_FINE_LOCATION') ||
        perms.contains('ACCESS_COARSE_LOCATION') ||
        perms.contains('ACCESS_BACKGROUND_LOCATION');
    final hasSms      = perms.contains('READ_SMS') ||
        perms.contains('RECEIVE_SMS');
    final hasContacts = perms.contains('READ_CONTACTS');
    final hasCallLog  = perms.contains('READ_CALL_LOG');

    final category    = _detectCategory(packageName, appName);
    final isTrusted   = _isTrusted(packageName);
    final expected    = category?.expectedPerms ?? <String>{};

    int score = 0;
    final riskyPerms   = <String>[];
    final explanations = <String>[];

    // ── Score only UNEXPECTED dangerous permissions ───────────────────────
    for (final p in perms) {
      final pts = _dangerousPerms[p] ?? 0;
      if (pts <= 0) continue;
      if (expected.contains(p)) continue; // expected → not risky

      final adjusted = isTrusted ? (pts * 0.5).round() : pts;
      score += adjusted;
      riskyPerms.add(permLabel(p));
    }

    // ── Combo multipliers (only for UNEXPECTED combos) ────────────────────
    if (hasInternet) {
      if (hasCamera   && !expected.contains('CAMERA')) {
        score += 20;
        explanations.add('Camera + Internet → can silently upload photos/video');
      }
      if (hasMic      && !expected.contains('RECORD_AUDIO')) {
        score += 20;
        explanations.add('Microphone + Internet → can stream audio remotely');
      }
      if (hasLocation && !expected.contains('ACCESS_FINE_LOCATION') &&
          !expected.contains('ACCESS_COARSE_LOCATION')) {
        score += 15;
        explanations.add('Location + Internet → real-time tracking possible');
      }
      if (hasSms      && !expected.contains('READ_SMS')) {
        score += 20;
        explanations.add('SMS + Internet → can exfiltrate OTP codes');
      }
      if (hasContacts && !expected.contains('READ_CONTACTS')) {
        score += 10;
        explanations.add('Contacts + Internet → address book can be uploaded');
      }
      if (hasCallLog  && !expected.contains('READ_CALL_LOG')) {
        score += 15;
        explanations.add('Call Log + Internet → call history exposure risk');
      }
    }

    if (isTrusted) score = (score * 0.6).round();
    score = score.clamp(0, 100);

    // ── Trust label ───────────────────────────────────────────────────────
    final TrustLabel trustLabel;
    if (isTrusted) {
      trustLabel = TrustLabel.trusted;
    } else if (perms.isEmpty ||
        perms.every((p) => (_dangerousPerms[p] ?? 0) == 0)) {
      trustLabel = TrustLabel.minimal;
    } else if (score >= 55) {
      trustLabel = TrustLabel.suspicious;
    } else {
      trustLabel = TrustLabel.watch;
    }

    final riskLevel =
    score >= 65 ? 'high' : score >= 35 ? 'medium' : 'low';

    // ── Explanation ───────────────────────────────────────────────────────
    String explanation;
    if (explanations.isNotEmpty) {
      explanation = explanations.first;
    } else if (category != null && riskyPerms.isEmpty) {
      explanation = '${category.label} — all permissions match expected usage';
    } else if (isTrusted) {
      explanation = 'System/trusted app — risk adjusted accordingly';
    } else if (riskyPerms.isNotEmpty) {
      explanation =
      'Has unexpected: ${riskyPerms.take(2).join(', ')}';
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
      'READ_MEDIA_IMAGES', 'READ_MEDIA_VIDEO', 'INTERNET'],
  },
  {
    'package': 'com.flashlight.suspicious',
    'name':    'FlashLight Pro',
    'perms':   ['CAMERA', 'INTERNET', 'READ_CONTACTS',
      'ACCESS_FINE_LOCATION'],
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
    'package': 'com.google.android.apps.maps',
    'name':    'Maps',
    'perms':   ['ACCESS_FINE_LOCATION', 'ACCESS_COARSE_LOCATION',
      'INTERNET', 'CAMERA', 'RECORD_AUDIO',
      'READ_EXTERNAL_STORAGE'],
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
    'perms':   ['CAMERA', 'RECORD_AUDIO', 'READ_CONTACTS',
      'READ_SMS', 'INTERNET', 'ACCESS_FINE_LOCATION',
      'READ_MEDIA_IMAGES', 'READ_MEDIA_VIDEO'],
  },
];