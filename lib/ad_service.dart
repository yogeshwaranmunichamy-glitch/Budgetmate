import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Shows a full-screen interstitial ad only at a natural pause point —
/// right after the user generates a monthly/weekly spending summary —
/// never on a timer, and never while they're mid-task entering transactions.
///
/// Frequency capped two ways so it never nags:
///  - never shown on the very first summary a user looks at in a session
///  - at most once every [minGapMinutes] minutes after that
class AdService {
  AdService._();
  static final AdService instance = AdService._();

  InterstitialAd? _interstitialAd;
  bool _adReady = false;
  int _reportGenerateCount = 0;

  static const int minGapMinutes = 30;
  static const String _lastShownKey = 'bm_last_interstitial_shown';

  // Google's official TEST interstitial ad unit ID — replace with your own
  // from admob.google.com before going live (banner unit is in ad_banner.dart,
  // though the banner is no longer wired into the UI by default).
  static const String _testAdUnitId = 'ca-app-pub-3940256099942544/1033173712';

  /// Call once at app startup so an ad is ready by the time it's needed.
  void preload() {
    InterstitialAd.load(
      adUnitId: _testAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _adReady = true;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _adReady = false;
              preload(); // get the next one ready in the background
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _adReady = false;
              preload();
            },
          );
        },
        onAdFailedToLoad: (_) => _adReady = false,
      ),
    );
  }

  /// Call this right after a report/summary finishes generating.
  /// Silently does nothing if it's too soon to show one again, or if it's
  /// the user's first summary this session — so it never feels like a wall.
  Future<void> maybeShowAfterReport() async {
    _reportGenerateCount++;
    if (_reportGenerateCount <= 1) return;

    final prefs = await SharedPreferences.getInstance();
    final last = prefs.getInt(_lastShownKey) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - last < minGapMinutes * 60 * 1000) return;

    if (_adReady && _interstitialAd != null) {
      await prefs.setInt(_lastShownKey, now);
      _interstitialAd!.show();
    } else {
      preload();
    }
  }
}
