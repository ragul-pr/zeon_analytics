import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:uuid/uuid.dart';

import 'models/event.dart';

class ZeonAnalytics {
  static ZeonAnalytics? _instance;

  final String endpoint;
  final String apiKey;
  final bool enableLogging;

  String? _userId;
  String? _deviceId;
  String? _platform;
  String? _appVersion;

  static const String _deviceIdKey = 'zeon_analytics_device_id';
  static const String _userIdKey = 'zeon_analytics_user_id';

  ZeonAnalytics._({
    required this.endpoint,
    required this.apiKey,
    this.enableLogging = false,
  });

  static Future<void> initialize({
    required String endpoint,
    required String apiKey,
    bool enableLogging = false,
  }) async {
    _instance = ZeonAnalytics._(
      endpoint: endpoint,
      apiKey: apiKey,
      enableLogging: enableLogging,
    );

    await _instance!._init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();

    // Get or create device ID
    _deviceId = prefs.getString(_deviceIdKey);
    if (_deviceId == null) {
      _deviceId = const Uuid().v4();
      await prefs.setString(_deviceIdKey, _deviceId!);
    }

    // Restore user ID if exists
    _userId = prefs.getString(_userIdKey);

    // Get platform info
    _platform = Platform.operatingSystem;

    // Get app version
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      _appVersion = packageInfo.version;
    } catch (e) {
      _appVersion = 'unknown';
    }

    _log('Initialized with deviceId: $_deviceId, userId: $_userId');
  }

  static void track(
    String eventName, {
    Map<String, dynamic>? properties,
    String? screenName,
  }) {
    _instance?._track(eventName,
        properties: properties, screenName: screenName);
  }

  Future<void> _track(
    String eventName, {
    Map<String, dynamic>? properties,
    String? screenName,
  }) async {
    final event = AnalyticsEvent(
      eventName: eventName,
      deviceId: _deviceId,
      userId: _userId,
      properties: properties ?? {},
      screenName: screenName,
      platform: _platform,
      appVersion: _appVersion,
      timestamp: DateTime.now().toUtc().toIso8601String(),
    );

    _log('Tracking: $eventName');

    // Send event immediately (realtime)
    await _sendEvent(event);
  }

  Future<void> _sendEvent(AnalyticsEvent event) async {
    try {
      final headers = {
        'Content-Type': 'application/json',
        'x-api-key': apiKey,
      };

      final response = await http.post(
        Uri.parse(endpoint),
        headers: headers,
        body: jsonEncode(event.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _log('Event sent successfully: ${event.eventName}');
      } else {
        _log('Failed to send event: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      _log('Error sending event: $e');
    }
  }

  static Future<void> identify({required String userId}) async {
    await _instance?._identify(userId);
  }

  Future<void> _identify(String userId) async {
    final previousUserId = _userId;
    _userId = userId;

    // Persist user ID
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userIdKey, userId);

    _log('Identified user: $userId');

    // Track identification event
    await _track('user_identified', properties: {
      'previous_user_id': previousUserId,
    });

    // Request backend to map anonymous events to this user
    if (previousUserId == null && _deviceId != null) {
      await _mapAnonymousEvents(userId);
    }
  }

  Future<void> _mapAnonymousEvents(String userId) async {
    try {
      final headers = {
        'Content-Type': 'application/json',
        'x-api-key': apiKey,
      };

      final mapEndpoint =
          endpoint.replaceAll('/ingest-event', '/map-anonymous-events');

      final response = await http.post(
        Uri.parse(mapEndpoint),
        headers: headers,
        body: jsonEncode({
          'device_id': _deviceId,
          'user_id': userId,
        }),
      );

      if (response.statusCode == 200) {
        _log('Successfully mapped anonymous events to user: $userId');
      } else {
        _log('Failed to map anonymous events: ${response.body}');
      }
    } catch (e) {
      _log('Error mapping anonymous events: $e');
    }
  }

  static Future<void> reset() async {
    await _instance?._reset();
  }

  Future<void> _reset() async {
    _userId = null;

    // Clear persisted user ID
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userIdKey);

    _log('Reset user');
  }

  void _log(String message) {
    if (enableLogging) {
      debugPrint('[ZeonAnalytics] $message');
    }
  }

  static void dispose() {
    _instance = null;
  }
}
