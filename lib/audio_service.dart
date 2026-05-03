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

  static Future<void> seekTo(int position) async {
    await platform.invokeMethod('seekTo', {
      "position": position,
    });
  }

  static void initListener(
    Function(String state, int? index, int position, int duration)
        onStateChanged,
  ) {
    const EventChannel channel = EventChannel('music_state');

    channel.receiveBroadcastStream().listen((event) {
      if (event is Map) {
        onStateChanged(
          event['state'].toString(),
          event['index'] as int?,
          event['position'] as int? ?? 0,
          event['duration'] as int? ?? 0,
        );
      } else {
        onStateChanged(event.toString(), null, 0, 0);
      }
    });
  }
}
