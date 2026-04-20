import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/scan_models.dart';

class UrlScannerService {
  // ── Add your Google Safe Browsing API key here ─────────────────────────────
  // Get free at: https://console.cloud.google.com → Enable "Safe Browsing API"
  static const String _apiKey = 'AIzaSyBNkuvVbuLspOCMFGpex-Iqwei1tLFcmaA';
  static const String _safeBrowsingEndpoint =
      'https://safebrowsing.googleapis.com/v4/threatMatches:find';

  // ── Suspicious keywords common in phishing URLs ────────────────────────────
  static const _suspiciousKeywords = [
    'login', 'verify', 'secure', 'update', 'confirm', 'bank', 'paypal',
    'account', 'signin', 'password', 'credential', 'wallet', 'recover',
    'alert', 'urgent', 'suspended', 'validate', 'unlock', 'billing',
    'support', 'help', 'service', 'official', 'auth', 'token', 'reset',
    'click', 'free', 'winner', 'prize', 'claim', 'expire', 'limited',
  ];

  // ── Well-known legitimate domains ─────────────────────────────────────────
  static const _popularDomains = [
    'google', 'facebook', 'apple', 'amazon', 'microsoft', 'paypal',
    'netflix', 'instagram', 'twitter', 'linkedin', 'dropbox', 'gmail',
    'yahoo', 'ebay', 'chase', 'wellsfargo', 'bankofamerica', 'youtube',
    'whatsapp', 'telegram', 'github', 'stackoverflow', 'reddit', 'tiktok',
    'snapchat', 'adobe', 'spotify', 'airbnb', 'uber', 'coinbase',
  ];

  // ── Homoglyph map: digits/chars attackers swap for real letters ────────────
  static const _homoglyphs = {
    '0': 'o', '1': 'l', '3': 'e', '4': 'a', '5': 's',
    '6': 'g', '7': 't', '8': 'b', '9': 'g', '@': 'a',
  };

  // ── Suspicious TLDs often used in phishing ─────────────────────────────────
  static const _suspiciousTlds = [
    'xyz', 'top', 'club', 'online', 'site', 'tk', 'ml', 'ga', 'cf',
    'gq', 'info', 'biz', 'pw', 'cc', 'live', 'stream', 'download',
    'click', 'link', 'win', 'loan', 'work', 'party', 'racing',
  ];

  // ── Legitimate domains that should never flag suspicious TLD check ─────────
  static const _trustedDomains = [
    'google.com', 'github.com', 'youtube.com', 'facebook.com',
    'microsoft.com', 'apple.com', 'amazon.com', 'twitter.com',
    'linkedin.com', 'stackoverflow.com', 'reddit.com', 'wikipedia.org',
  ];

  static final _ipPattern =
  RegExp(r'https?://(\d{1,3}\.){3}\d{1,3}', caseSensitive: false);

  // ── Normalize homoglyphs in a string ──────────────────────────────────────
  String _normalizeHomoglyphs(String s) {
    var r = s.toLowerCase();
    _homoglyphs.forEach((fake, real) => r = r.replaceAll(fake, real));
    return r;
  }

  bool _hasHomoglyphs(String domain) =>
      _homoglyphs.keys.any((c) => domain.contains(c));

  // ── Main scan ──────────────────────────────────────────────────────────────
  Future<UrlScanResult> scan(String rawUrl) async {
    final url = rawUrl.trim();
    if (url.isEmpty) throw Exception('URL is empty');

    final normalized = url.startsWith('http') ? url : 'https://$url';
    int score = 0;
    final reasons = <String>[];

    final uri = Uri.tryParse(normalized);
    final host = uri?.host.toLowerCase() ?? '';
    final lowerUrl = normalized.toLowerCase();

    // ── Check if it's a known trusted domain first ─────────────────────────
    final isTrusted = _trustedDomains.any((d) => host == d || host.endsWith('.$d'));

    // 1. Raw IP address
    if (_ipPattern.hasMatch(normalized)) {
      score += 45;
      reasons.add('URL uses a raw IP address instead of a domain name');
    }

    if (uri != null && host.isNotEmpty) {
      final parts   = host.split('.');
      final tld     = parts.length >= 1 ? parts.last : '';
      final domain  = parts.length >= 2 ? parts[parts.length - 2] : host;
      final fullDomain = parts.length >= 2 ? '${parts[parts.length - 2]}.$tld' : host;

      // 2. Homoglyph substitution — go0gle, paypa1, app1e, faceb00k
      if (_hasHomoglyphs(domain)) {
        final normalized2 = _normalizeHomoglyphs(domain);
        if (_popularDomains.contains(normalized2)) {
          score += 60;
          reasons.add(
            'Domain "$domain" uses character substitution to fake '
                '"$normalized2.com" — classic phishing trick (0→o, 1→l)',
          );
        } else {
          score += 20;
          reasons.add('Domain "$domain" contains digit substitutions — suspicious');
        }
      }

      // 3. Levenshtein lookalike (micosoft, gooogle, faceboook)
      bool lookalikefound = false;
      for (final popular in _popularDomains) {
        if (domain != popular && _isSimilar(domain, popular)) {
          score += 40;
          reasons.add('Domain "$domain" looks similar to "$popular.com" — possible typosquat');
          lookalikefound = true;
          break;
        }
      }

      // 4. Brand in URL but not as real domain (e.g. paypal.account-verify.com)
      if (!isTrusted) {
        for (final popular in _popularDomains) {
          if (lowerUrl.contains(popular) && domain != popular &&
              _normalizeHomoglyphs(domain) != popular && !lookalikefound) {
            score += 25;
            reasons.add(
              '"$popular" appears in the URL but the actual domain is "$fullDomain"'
                  ' — deceptive structure used in phishing',
            );
            break;
          }
        }
      }

      // 5. Suspicious TLD
      if (!isTrusted && _suspiciousTlds.contains(tld)) {
        score += 20;
        reasons.add('Uses high-risk TLD ".$tld" — commonly used in free/throwaway phishing domains');
      }

      // 6. Excessive subdomains (e.g. login.verify.paypal.fake.com)
      if (parts.length > 4) {
        score += 20;
        reasons.add('${parts.length} subdomain levels — attackers use deep subdomains to hide real domain');
      } else if (parts.length == 4) {
        score += 10;
        reasons.add('Multiple subdomains detected — may be hiding the real domain');
      }

      // 7. @ symbol in URL
      if (normalized.contains('@')) {
        score += 40;
        reasons.add('URL contains "@" — browser ignores everything before it, classic phishing trick');
      }

      // 8. HTTP (no HTTPS)
      if (normalized.startsWith('http://') && !isTrusted) {
        score += 15;
        reasons.add('No SSL/HTTPS — data sent unencrypted, often seen in fake sites');
      }

      // 9. Multiple hyphens in domain
      final hyphenCount = domain.split('-').length - 1;
      if (hyphenCount >= 2) {
        score += 15;
        reasons.add('Domain "$domain" has $hyphenCount hyphens — pattern common in fake sites');
      } else if (hyphenCount == 1 && !isTrusted) {
        score += 5;
      }

      // 10. Suspicious keywords in URL
      if (!isTrusted) {
        final foundKeywords = _suspiciousKeywords.where((k) => lowerUrl.contains(k)).toList();
        if (foundKeywords.length >= 3) {
          score += 25;
          reasons.add('Multiple suspicious keywords: ${foundKeywords.take(3).map((k) => '"$k"').join(', ')}');
        } else if (foundKeywords.isNotEmpty) {
          score += 10 + (foundKeywords.length * 5);
          for (final k in foundKeywords.take(2)) {
            reasons.add('Contains suspicious keyword: "$k"');
          }
        }
      }

      // 11. Very long URL (obfuscation)
      if (normalized.length > 150) {
        score += 15;
        reasons.add('Abnormally long URL (${normalized.length} chars) — obfuscation technique');
      } else if (uri.path.length > 80) {
        score += 10;
        reasons.add('Long URL path — may be hiding a redirect');
      }

      // 12. Encoded characters (URL encoding to hide malicious content)
      if (normalized.contains('%') && normalized.split('%').length > 4) {
        score += 15;
        reasons.add('Excessive URL encoding — often used to bypass filters');
      }

      // 13. Double slash in path (redirect trick)
      if (uri.path.contains('//')) {
        score += 10;
        reasons.add('Double slash in URL path — common in redirect attacks');
      }

      // 14. Domain is just an IP disguised with a name
      if (RegExp(r'^\d+-\d+-\d+-\d+').hasMatch(domain)) {
        score += 30;
        reasons.add('Domain appears to be a disguised IP address');
      }

      // 15. Newly registered domain indicators (short meaningless domains)
      if (domain.length <= 4 && !_popularDomains.contains(domain) && !isTrusted) {
        score += 10;
        reasons.add('Very short domain name — may be a newly registered throwaway domain');
      }
    }

    // 16. Google Safe Browsing API
    bool apiChecked = false;
    if (_apiKey != 'YOUR_GOOGLE_SAFE_BROWSING_API_KEY') {
      try {
        final hit = await _checkSafeBrowsing(normalized);
        if (hit) {
          score += 60;
          reasons.insert(0, '🚨 Confirmed malicious by Google Safe Browsing database');
        }
        apiChecked = true;
      } catch (_) {}
    }

    score = score.clamp(0, 100);

    if (reasons.isEmpty) {
      reasons.add('No suspicious patterns detected — URL appears clean');
    }

    final status = score >= 60 ? 'dangerous' : score >= 30 ? 'suspicious' : 'safe';

    return UrlScanResult(
      url: normalized,
      threatScore: score,
      status: status,
      reasons: reasons,
      apiChecked: apiChecked,
    );
  }

  // ── Google Safe Browsing API call ─────────────────────────────────────────
  Future<bool> _checkSafeBrowsing(String url) async {
    final body = jsonEncode({
      'client': {'clientId': 'cybershield_app', 'clientVersion': '1.0.0'},
      'threatInfo': {
        'threatTypes': [
          'MALWARE', 'SOCIAL_ENGINEERING',
          'UNWANTED_SOFTWARE', 'POTENTIALLY_HARMFUL_APPLICATION'
        ],
        'platformTypes':    ['ANY_PLATFORM'],
        'threatEntryTypes': ['URL'],
        'threatEntries':    [{'url': url}],
      }
    });
    final response = await http
        .post(
      Uri.parse('$_safeBrowsingEndpoint?key=$_apiKey'),
      headers: {'Content-Type': 'application/json'},
      body: body,
    )
        .timeout(const Duration(seconds: 8));
    if (response.statusCode == 200) {
      return (jsonDecode(response.body) as Map<String, dynamic>).containsKey('matches');
    }
    return false;
  }

  // ── Levenshtein distance ──────────────────────────────────────────────────
  bool _isSimilar(String a, String b) {
    if ((a.length - b.length).abs() > 3) return false;
    return _levenshtein(a, b) <= 2 && a != b;
  }

  int _levenshtein(String a, String b) {
    final dp = List.generate(
        a.length + 1, (i) => List.generate(b.length + 1, (j) => 0));
    for (var i = 0; i <= a.length; i++) dp[i][0] = i;
    for (var j = 0; j <= b.length; j++) dp[0][j] = j;
    for (var i = 1; i <= a.length; i++) {
      for (var j = 1; j <= b.length; j++) {
        dp[i][j] = a[i - 1] == b[j - 1]
            ? dp[i - 1][j - 1]
            : 1 + [dp[i - 1][j], dp[i][j - 1], dp[i - 1][j - 1]]
            .reduce((x, y) => x < y ? x : y);
      }
    }
    return dp[a.length][b.length];
  }
}

// ── Demo URLs covering all attack types ──────────────────────────────────────
final demoUrls = [
  'http://192.168.1.1/login/verify-account',        // IP-based
  'https://paypa1-secure-login.com/verify',          // Homoglyph + keyword
  'https://go0gle.com',                              // Homoglyph
  'https://app1e-id-verify.com/unlock',              // Homoglyph + keyword
  'https://secure-paypal-account.verify.xyz',        // Brand in URL + bad TLD
  'https://google.com',                              // Legitimate
  'https://github.com',                              // Legitimate
  'http://secure-bankofamerica-login.suspicious.net/signin', // Brand + keywords
];