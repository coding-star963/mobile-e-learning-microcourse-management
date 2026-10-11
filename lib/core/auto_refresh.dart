import 'dart:async';

import 'package:flutter/widgets.dart';

import 'constants.dart';

/// Calls [onAutoRefresh] every [AppConstants.autoRefreshInterval] while the app
/// is on screen, and right away when it comes back to the foreground, so
/// changes made on the web portal show up on the phone automatically.
mixin AutoRefresh<T extends StatefulWidget> on State<T> {
  Timer? _timer;
  AppLifecycleListener? _lifecycle;
  bool _refreshing = false;

  /// Silently reloads this screen's data (no spinners, keeps current data on failure).
  Future<void> onAutoRefresh();

  @override
  void initState() {
    super.initState();
    _start();
    _lifecycle = AppLifecycleListener(
      onShow: () {
        _tick();
        _start();
      },
      onHide: _stop,
    );
  }

  void _start() {
    _timer?.cancel();
    _timer = Timer.periodic(AppConstants.autoRefreshInterval, (_) => _tick());
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _tick() async {
    if (!mounted || _refreshing) return;
    _refreshing = true;
    try {
      await onAutoRefresh();
    } catch (_) {
      // A missed refresh is retried on the next tick.
    } finally {
      _refreshing = false;
    }
  }

  @override
  void dispose() {
    _stop();
    _lifecycle?.dispose();
    super.dispose();
  }
}
