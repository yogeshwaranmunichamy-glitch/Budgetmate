import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Displays a standard AdMob banner ad.
///
/// IMPORTANT: adUnitId below is Google's official TEST banner ID — it's safe
/// to build and ship with while developing (shows real ad creatives but
/// never generates real revenue and never risks your AdMob account).
///
/// To start earning real money:
///  1. Create a free account at https://admob.google.com
///  2. Register this app and create a "Banner" ad unit
///  3. Replace the adUnitId string below with the one AdMob gives you
///     (looks like "ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX")
///  4. Also update the AdMob App ID in codemagic.yaml's manifest-patch step
///     (currently set to Google's test App ID)
class AdBanner extends StatefulWidget {
  const AdBanner({super.key});
  @override
  State<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends State<AdBanner> {
  BannerAd? _bannerAd;
  bool _loaded = false;

  // Google's official Android TEST banner ad unit ID — replace with your own.
  static const String _testAdUnitId = 'ca-app-pub-3940256099942544/6300978111';

  @override
  void initState() {
    super.initState();
    _bannerAd = BannerAd(
      adUnitId: _testAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) => setState(() => _loaded = true),
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          debugPrint('BannerAd failed to load: $error');
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || _bannerAd == null) return const SizedBox.shrink();
    return SizedBox(
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    );
  }
}
