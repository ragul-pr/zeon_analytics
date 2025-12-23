# Zeon Analytics Flutter SDK

A lightweight Flutter package to send analytics events to your Zeon Analytics dashboard in realtime.

## Features

- 🔐 Automatic device ID generation and persistence
- 👤 User identification with automatic event mapping
- ⚡ Realtime event sending (no batching)
- 📱 Automatic platform and app version detection

## Installation

Since this is a private package, add it to your `pubspec.yaml` using a git dependency or local path:

### Option 1: Git Dependency (Recommended)

```yaml
dependencies:
  zeon_analytics:
    git:
      url: https://github.com/ragul-pr/zeon_analytics.git
      ref: main
```

### Option 2: Local Path

```yaml
dependencies:
  zeon_analytics:
    path: ../zeon_analytics
```

Then run:

```bash
flutter pub get
```

## Quick Start

### 1. Initialize the SDK

Initialize early in your app, typically in `main.dart`:

```dart
import 'package:zeon_analytics/zeon_analytics.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await ZeonAnalytics.initialize(
    endpoint: 'https://ppozqbenfwgcbzshwuaz.supabase.co/functions/v1/ingest-event',
    apiKey: 'zeon_xxxxxxxx...', // Get this from API Keys page in dashboard
  );
  
  runApp(MyApp());
}
```

> **Important:** Get your API key from the **API Keys** page in your Zeon Analytics dashboard. The `x-api-key` header is required for all requests.

### 2. Track Events

Events are sent immediately in realtime:

```dart
// Simple event
ZeonAnalytics.track('button_clicked');

// Event with properties
ZeonAnalytics.track('purchase_completed', properties: {
  'product_id': 'SKU123',
  'amount': 29.99,
  'currency': 'USD',
});

// Event with screen name
ZeonAnalytics.track('screen_viewed', screenName: 'HomeScreen');
```

### 3. Identify Users (After Login)

When a user logs in, call `identify` to link their user ID with the device:

```dart
// After successful login
ZeonAnalytics.identify(userId: 'user_123');
```

**Important:** This automatically:
- Associates the user ID with all future events
- Sends a request to map all previous anonymous events (device-only) to this user ID

### 4. Handle Logout

```dart
// On logout - clears user ID but keeps device ID
ZeonAnalytics.reset();
```

## API Reference

### `ZeonAnalytics.initialize()`

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `endpoint` | `String` | ✅ | Your Supabase edge function URL |
| `apiKey` | `String` | ✅ | Your Zeon Analytics API key (get from API Keys page) |
| `enableLogging` | `bool` | ❌ | Enable debug logs (default: false) |

### `ZeonAnalytics.track()`

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `eventName` | `String` | ✅ | Name of the event |
| `properties` | `Map<String, dynamic>?` | ❌ | Custom event properties |
| `screenName` | `String?` | ❌ | Screen where event occurred |

**Note:** Events are sent immediately in realtime. No batching or flushing is performed.

### `ZeonAnalytics.identify()`

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `userId` | `String` | ✅ | Your app's user ID |

### `ZeonAnalytics.reset()`

Clears the current user ID. Call on logout.

### `ZeonAnalytics.dispose()`

Cleans up the analytics instance. Call when app is closing.

## Realtime Behavior

This SDK sends events immediately when `track()` is called. There is no batching, queuing, or flushing mechanism. Each event is sent as a separate HTTP request to ensure realtime analytics.

## Backend Requirements

Your Supabase edge function needs to handle:

1. **`device_id` field** in events
2. **`/map-anonymous-events` endpoint** to map device events to user

See the dashboard documentation for edge function updates.

## Example Usage in App

```dart
import 'package:flutter/material.dart';
import 'package:zeon_analytics/zeon_analytics.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await ZeonAnalytics.initialize(
    endpoint: 'https://ppozqbenfwgcbzshwuaz.supabase.co/functions/v1/ingest-event',
    apiKey: 'zeon_xxxxxxxx...', // Get this from API Keys page in dashboard
    enableLogging: true, // For debugging
  );
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Track screen view (sent immediately)
    ZeonAnalytics.track('screen_view', screenName: 'HomeScreen');
    
    return Scaffold(
      appBar: AppBar(title: Text('My App')),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: () {
              // Event sent immediately
              ZeonAnalytics.track('button_clicked', properties: {
                'button_name': 'cta_button',
              });
            },
            child: Text('Track Event'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Simulate login
              await ZeonAnalytics.identify(userId: 'user_123');
            },
            child: Text('Login (Identify)'),
          ),
          ElevatedButton(
            onPressed: () async {
              await ZeonAnalytics.reset();
            },
            child: Text('Logout (Reset)'),
          ),
        ],
      ),
    );
  }
}
```

## License

MIT License

