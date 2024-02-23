import 'dart:async';
import 'dart:io';

import '../ironsource_mediation.dart';

export '../ironsource_mediation.dart' show IronSourceAdUnit, IronSourceAdInfo, IronSourceRewardedVideoPlacement, IronSourceError;

part 'units/rewarded_video.dart';

enum LevelPlayEvent { available, unavailable, clicked, opened, closed, rewarded, failed }
typedef LevelPlayEventListener = void Function(LevelPlayEvent type, IronSourceAdInfo? adInfo, {IronSourceRewardedVideoPlacement? placement, IronSourceError error});

class LevelPlayManager {
  final MilkLevelPlayRewardedVideoController rewardedVideo = MilkLevelPlayRewardedVideoController._();

  Future<void> init({required String appKey, String? userId, List<IronSourceAdUnit>? adUnits, MilkLevelPlayRewardedVideoDelegate? rewardedVideoDelegate, bool requestAtt = false}) async {
    var completer = Completer();
    IronSource.init(appKey: appKey, adUnits: adUnits)
        .then((_) => { completer.complete() })
        .catchError((err) => { completer.completeError(err) });

    if(userId != null) IronSource.setUserId(userId);
    IronSource.setLevelPlayRewardedVideoListener(rewardedVideo);
    if(rewardedVideoDelegate != null) rewardedVideo.setDelegate(rewardedVideoDelegate);

    if(requestAtt) await requestATT();
    await Future.wait([
      rewardedVideo.init()
    ]);

    return completer.future;
  }

  void printIntegration() async {
    await IronSource.validateIntegration();
  }

  Future<void> requestATT() async {
    if(!Platform.isIOS) return;
    if(await ATTrackingManager.requestTrackingAuthorization() == ATTStatus.NotDetermined) {
      await ATTrackingManager.requestTrackingAuthorization();
    }
  }

  Future<void> openRewardedVideo({
    String? placementName,
    void Function(IronSourceRewardedVideoPlacement placement)? onAdRewarded,
    void Function(IronSourceRewardedVideoPlacement placement)? onAdClicked,
  }) {
    return rewardedVideo.open(
      placementName: placementName,
      onAdRewarded: onAdRewarded,
      onAdClicked: onAdClicked
    );
  }

  LevelPlayManager._();
  static LevelPlayManager? _instance;
  static LevelPlayManager get instance => _instance ??= LevelPlayManager._();
}