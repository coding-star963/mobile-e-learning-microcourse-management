import 'package:flutter/foundation.dart';

/// Live sync between the web portal and the app.
///
/// The home shell checks the server's change marker every
/// [AppConstants.autoRefreshInterval] and reloads the shared providers when it
/// changes. It then bumps [revision], so screens that hold their own copy of
/// server data (course details, enrollment details) reload right away too.
class LiveSync {
  const LiveSync._();

  static final ValueNotifier<int> revision = ValueNotifier<int>(0);

  /// Called by the home shell after it reloaded fresh data.
  static void bump() => revision.value++;
}
