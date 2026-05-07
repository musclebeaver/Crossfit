import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  static String get bannerAdUnitId {
    if (kReleaseMode) {
      // 실제 배포 시에는 여기에 실제 광고 단위 ID를 넣어야 합니다.
      if (Platform.isAndroid) {
        return 'ca-app-pub-3940256099942544/6300978111'; // 테스트용
      } else if (Platform.isIOS) {
        return 'ca-app-pub-3940256099942544/2934735716'; // 테스트용
      }
    }
    
    // 개발/테스트용 ID들
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/6300978111';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/2934735716';
    } else {
      throw UnsupportedError("Unsupported platform");
    }
  }

  static String get rewardedAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/5224354917';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/1712485313';
    } else {
      throw UnsupportedError("Unsupported platform");
    }
  }

  static Future<void> init() async {
    if (kIsWeb) return; // 웹은 지원하지 않으므로 무시
    await MobileAds.instance.initialize();
  }

  static Future<void> showRewardedAd({
    required Function() onRewardEarned,
    Function()? onAdFailedToLoad,
  }) async {
    if (kIsWeb) {
      onRewardEarned();
      return;
    }

    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              if (onAdFailedToLoad != null) onAdFailedToLoad();
            },
          );

          ad.show(onUserEarnedReward: (ad, reward) {
            onRewardEarned();
          });
        },
        onAdFailedToLoad: (err) {
          debugPrint('RewardedAd failed to load: $err');
          if (onAdFailedToLoad != null) onAdFailedToLoad();
        },
      ),
    );
  }
}
