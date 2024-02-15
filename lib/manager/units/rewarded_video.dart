part of '../level_play_manager.dart';

const _kUnknownAuctionId = "unknown";
class MilkLevelPlayRewardedVideoController extends LevelPlayRewardedVideoListener {
  final Map<String, _RewardedVideoInstance> _instances = {};
  MilkLevelPlayRewardedVideoDelegate _delegate = const MilkLevelPlayRewardedVideoDelegate.empty();

  String? _currentAuctionId;
  bool _isOpened = false;

  MilkLevelPlayRewardedVideoController._();

  Future<void> init() async {
    IronSource.shouldTrackNetworkState(true);
  }

  void setDelegate(MilkLevelPlayRewardedVideoDelegate? delegate) {
    _delegate = delegate ?? const MilkLevelPlayRewardedVideoDelegate.empty();
  }

  Future<void> open({
    String? placementName,
    void Function(IronSourceRewardedVideoPlacement placement)? onAdRewarded,
    void Function(IronSourceRewardedVideoPlacement placement)? onAdClicked,
  }) async {
    if(!isAvailable) {
      if(await IronSource.isRewardedVideoAvailable()) {
        _currentAuctionId = _kUnknownAuctionId;
        _instances.putIfAbsent(_kUnknownAuctionId, () => _RewardedVideoInstance(null));
      } else{
        throw IronSourceError(errorCode: 99001);
      }
    }

    var instance = _instances[_currentAuctionId]!;
    instance.setListeners(onAdRewarded: onAdRewarded, onAdClicked: onAdClicked);
    IronSource.showRewardedVideo(placementName: placementName);

    return instance.completer.future;
  }

  @override
  void onAdAvailable(IronSourceAdInfo adInfo) {
    _currentAuctionId = adInfo.auctionId??"";
    _instances.putIfAbsent(_currentAuctionId!, () => _RewardedVideoInstance(adInfo));
    _delegate.onAdAvailable?.call(adInfo);
  }

  @override
  void onAdUnavailable() {
    _currentAuctionId = null;
    _delegate.onAdUnavailable?.call();
  }

  @override
  void onAdOpened(IronSourceAdInfo adInfo) {
    _isOpened = true;
    if(_currentAuctionId == _kUnknownAuctionId) {
      _currentAuctionId = adInfo.auctionId??"";
      _instances.putIfAbsent(_currentAuctionId!, () => _instances[_kUnknownAuctionId]!);
      _instances.remove(_kUnknownAuctionId);
    }
    _delegate.onAdOpened?.call(adInfo);
  }

  @override
  void onAdClosed(IronSourceAdInfo adInfo) {
    _isOpened = false;
    _instances[adInfo.auctionId??""]?.completer.complete();
    _instances.remove(adInfo.auctionId??"");
    _delegate.onAdClosed?.call(adInfo);
  }

  @override
  void onAdShowFailed(IronSourceError error, IronSourceAdInfo adInfo) {
    _instances[adInfo.auctionId??""]?.completer.completeError(error);
    _instances.remove(adInfo.auctionId??"");
    _delegate.onAdShowFailed?.call(error, adInfo);
    IronSource.loadRewardedVideo();
  }

  @override
  void onAdClicked(IronSourceRewardedVideoPlacement placement, IronSourceAdInfo adInfo) {
    _instances[adInfo.auctionId??""]?.onAdClicked(placement);
    _delegate.onAdClicked?.call(placement, adInfo);
  }

  @override
  void onAdRewarded(IronSourceRewardedVideoPlacement placement, IronSourceAdInfo adInfo) {
    _instances[adInfo.auctionId??""]?.onAdRewarded(placement);
    _delegate.onAdRewarded?.call(placement, adInfo);
  }

  bool get isAvailable => _currentAuctionId != null;
  bool get isOpened => _isOpened;
}

class _RewardedVideoInstance {
  final IronSourceAdInfo? adInfo;
  final Completer completer = Completer();
  void Function(IronSourceRewardedVideoPlacement placement)? _onAdRewarded;
  void Function(IronSourceRewardedVideoPlacement placement)? _onAdClicked;

  _RewardedVideoInstance(this.adInfo);

  void setListeners({
    void Function(IronSourceRewardedVideoPlacement placement)? onAdRewarded,
    void Function(IronSourceRewardedVideoPlacement placement)? onAdClicked,
  }) {
    _onAdRewarded = onAdRewarded;
    _onAdClicked = onAdClicked;
  }

  void onAdRewarded(IronSourceRewardedVideoPlacement placement) {
    _onAdRewarded?.call(placement);
  }

  void onAdClicked(IronSourceRewardedVideoPlacement placement) {
    _onAdClicked?.call(placement);
  }
}

class MilkLevelPlayRewardedVideoDelegate {
  final void Function(IronSourceAdInfo adInfo)? onAdAvailable;
  final void Function()? onAdUnavailable;
  final void Function(IronSourceAdInfo adInfo)? onAdOpened;
  final void Function(IronSourceAdInfo adInfo)? onAdClosed;
  final void Function(IronSourceError error, IronSourceAdInfo adInfo)? onAdShowFailed;
  final void Function(IronSourceRewardedVideoPlacement placement, IronSourceAdInfo adInfo)? onAdClicked;
  final void Function(IronSourceRewardedVideoPlacement placement, IronSourceAdInfo adInfo)? onAdRewarded;

  MilkLevelPlayRewardedVideoDelegate({this.onAdAvailable, this.onAdUnavailable, this.onAdOpened, this.onAdClosed, this.onAdShowFailed, this.onAdClicked, this.onAdRewarded});
  const MilkLevelPlayRewardedVideoDelegate.empty()
    : onAdAvailable = null,
      onAdUnavailable = null,
      onAdOpened = null,
      onAdClosed = null,
      onAdShowFailed = null,
      onAdClicked = null,
      onAdRewarded = null;
}