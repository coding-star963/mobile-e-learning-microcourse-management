import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

/// Records opened URLs instead of launching a browser (4.4).
class FakeUrlLauncher extends UrlLauncherPlatform with MockPlatformInterfaceMixin {
  final List<String> launched = [];

  @override
  LinkDelegate? get linkDelegate => null;

  @override
  Future<bool> canLaunch(String url) async => true;

  @override
  Future<bool> supportsMode(PreferredLaunchMode mode) async => true;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    launched.add(url);
    return true;
  }
}

/// A video/audio player that "plays" without a real decoder (4.3).
/// Set [failToLoad] to simulate a broken or unreachable media URL.
class FakeVideoPlayer extends VideoPlayerPlatform with MockPlatformInterfaceMixin {
  FakeVideoPlayer({this.failToLoad = false});

  final bool failToLoad;
  final List<String> calls = [];
  final List<DataSource> sources = [];
  final Map<int, StreamController<VideoEvent>> _events = {};
  int _nextId = 1;

  @override
  Future<void> init() async {}

  @override
  Future<int?> createWithOptions(VideoCreationOptions options) async {
    final id = _nextId++;
    calls.add('create ${options.dataSource.uri}');
    sources.add(options.dataSource);
    final controller = StreamController<VideoEvent>();
    _events[id] = controller;
    if (failToLoad) {
      controller.addError(PlatformException(code: 'VideoError', message: 'media not found'));
    } else {
      controller.add(VideoEvent(
        eventType: VideoEventType.initialized,
        duration: const Duration(minutes: 5),
        size: const Size(1280, 720),
      ));
    }
    return id;
  }

  @override
  Stream<VideoEvent> videoEventsFor(int playerId) => _events[playerId]!.stream;

  @override
  Future<void> play(int playerId) async => calls.add('play');

  @override
  Future<void> pause(int playerId) async => calls.add('pause');

  @override
  Future<void> setLooping(int playerId, bool looping) async {}

  @override
  Future<void> setVolume(int playerId, double volume) async {}

  @override
  Future<void> setPlaybackSpeed(int playerId, double speed) async {}

  @override
  Future<void> seekTo(int playerId, Duration position) async {}

  @override
  Future<Duration> getPosition(int playerId) async => Duration.zero;

  @override
  Future<void> dispose(int playerId) async {
    calls.add('dispose $playerId');
    await _events.remove(playerId)?.close();
  }

  @override
  Widget buildView(int playerId) => const SizedBox.expand();

  @override
  Widget buildViewWithOptions(VideoViewOptions options) => const SizedBox.expand();
}
