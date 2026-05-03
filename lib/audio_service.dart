import 'package:flutter/services.dart';

class AudioService {
  static const platform = MethodChannel('music_service');

  static Future<void> play(int index) async {
    await platform.invokeMethod('play', {
      "index": index,
    });
  }

  static Future<void> pause() async {
    await platform.invokeMethod('pause');
  }

  static Future<void> next() async {
    await platform.invokeMethod('next');
  }

  static Future<void> previous() async {
    await platform.invokeMethod('previous');
  }

  static Future<List<String>> getSongs() async {
    final songs = await platform.invokeMethod<List<dynamic>>('getSongs');
    return songs?.map((song) => song.toString()).toList() ?? [];
  }

  static void initListener(Function(String state, int? index) onStateChanged) {
    const EventChannel channel = EventChannel('music_state');

    channel.receiveBroadcastStream().listen((event) {
      if (event is Map) {
        onStateChanged(event['state'].toString(), event['index'] as int?);
      } else {
        onStateChanged(event.toString(), null);
      }
    });
  }
}
