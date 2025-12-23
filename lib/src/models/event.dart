class AnalyticsEvent {
  final String eventName;
  final String? deviceId;
  final String? userId;
  final Map<String, dynamic> properties;
  final String? screenName;
  final String? platform;
  final String? appVersion;
  final String timestamp;

  AnalyticsEvent({
    required this.eventName,
    this.deviceId,
    this.userId,
    this.properties = const {},
    this.screenName,
    this.platform,
    this.appVersion,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'event_name': eventName,
      'device_id': deviceId,
      'user_id': userId,
      'properties': properties,
      'screen_name': screenName,
      'platform': platform,
      'app_version': appVersion,
      'timestamp': timestamp,
    };
  }
}
