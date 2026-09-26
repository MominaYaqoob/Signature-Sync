import 'dart:convert';
import 'dart:io';

/// Temporary debug-session logger (session 28faf2). Prints to logcat and
/// POSTs to the host ingest server (needs `adb reverse tcp:7666 tcp:7666`).
void agentLog(
  String hypothesisId,
  String location,
  String message, [
  Map<String, Object?> data = const {},
]) {
  // #region agent log
  final payload = <String, Object?>{
    'sessionId': '28faf2',
    'runId': 'pre-fix',
    'hypothesisId': hypothesisId,
    'location': location,
    'message': message,
    'data': data,
    'timestamp': DateTime.now().millisecondsSinceEpoch,
  };
  final encoded = jsonEncode(payload);
  // Always visible via: adb logcat -s flutter:I SigSyncDebug:I
  // ignore: avoid_print
  print('[SigSyncDebug] $encoded');
  try {
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 2);
    client
        .postUrl(Uri.parse(
            'http://127.0.0.1:7666/ingest/9ba8b523-3d1d-4b01-8c9c-8266985647c7'))
        .then((req) {
      req.headers.set('Content-Type', 'application/json');
      req.headers.set('X-Debug-Session-Id', '28faf2');
      req.write(encoded);
      return req.close();
    }).then((resp) => resp.drain<void>()).catchError((_) {}).whenComplete(() {
      client.close(force: true);
    });
  } catch (_) {}
  // #endregion
}
