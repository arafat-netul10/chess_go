import 'package:flutter/material.dart';

/// Abstraction for future AdMob monetization when publishing to Google Play Store
class AdService {
  static bool adsEnabled = false;

  /// Call after a match finishes to show interstitial ad (if enabled)
  static Future<void> showPostMatchInterstitial(BuildContext context) async {
    if (!adsEnabled) return;
    // When google_mobile_ads is added for Play Store release,
    // invoke InterstitialAd.show() here.
  }
}

/// Placeholder widget that seamlessly embeds a bottom banner ad slot
/// or collapses to 0 height when ads are disabled.
class ChessBannerAdSlot extends StatelessWidget {
  const ChessBannerAdSlot({super.key});

  @override
  Widget build(BuildContext context) {
    if (!AdService.adsEnabled) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 50,
      width: double.infinity,
      color: Colors.black26,
      alignment: Alignment.center,
      child: const Text(
        'AdMob Banner',
        style: TextStyle(color: Colors.white38, fontSize: 12),
      ),
    );
  }
}
