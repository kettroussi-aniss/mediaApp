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

  static void initListener(Function(String state) onStateChanged) {
    const EventChannel channel = EventChannel('music_state');

    channel.receiveBroadcastStream().listen((event) {
      onStateChanged(event.toString());
    });
  }
}