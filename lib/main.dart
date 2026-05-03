import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'Database_helper.dart';
import 'FavoritePage.dart';
import 'audio_service.dart';

final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();

void main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  await requestNotificationPermission();

  runApp(const MyApp());
}

Future<void> requestNotificationPermission() async {
  await [
    Permission.notification,
    Permission.audio,
    Permission.storage,
  ].request();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FlutterNativeSplash.remove();
    });

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorObservers: [routeObserver],
      home: const MusicPlayerScreen(),
    );
  }
}

class MusicPlayerScreen extends StatefulWidget {
  const MusicPlayerScreen({super.key});

  @override
  State<MusicPlayerScreen> createState() => _MusicPlayerScreenState();
}

class _MusicPlayerScreenState extends State<MusicPlayerScreen>
    with WidgetsBindingObserver, RouteAware {
  bool isPlaying = false;
  bool visibleAfterFirstPlay = false;

  late List<bool> isFavoriteList;

  List<String> songs = [
    "song1.wav",
    "song2.wav",
  ];

  int currentIndex = 0;

  @override
  void initState() {
    super.initState();

    isFavoriteList = List.filled(songs.length, false);
    loadFavorites();
    loadDeviceSongs();

    AudioService.initListener((state, index) {
      setState(() {
        if (index != null && index >= 0 && index < songs.length) {
          currentIndex = index;
        }

        if (state == "PLAY") {
          isPlaying = true;
          visibleAfterFirstPlay = true;
        } else if (state == "PAUSE") {
          isPlaying = false;
        }
      });
    });
  }

  Future<void> loadDeviceSongs() async {
    final deviceSongs = await AudioService.getSongs();
    if (!mounted || deviceSongs.isEmpty) return;

    setState(() {
      songs = deviceSongs;
      currentIndex = 0;
      isFavoriteList = List.filled(songs.length, false);
    });

    await loadFavorites();
  }

  Future<void> loadFavorites() async {
    List<String> saved = await DatabaseHelper.instance.getFavorites();

    for (int i = 0; i < songs.length; i++) {
      isFavoriteList[i] = saved.contains(songs[i]);
    }

    setState(() {});
  }

  Future<void> saveFavorites() async {
    final currentFavs = await DatabaseHelper.instance.getFavorites();

    for (var song in currentFavs) {
      await DatabaseHelper.instance.removeFavorite(song);
    }

    for (var song in getFavoriteSongs()) {
      await DatabaseHelper.instance.addFavorite(song);
    }
  }

  @override
  void dispose() {
    saveFavorites();
    routeObserver.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // =========================
  // PLAY / PAUSE FIXED
  // =========================
  void togglePlay() async {
    if (isPlaying) {
      await AudioService.pause();
    } else {
      await AudioService.play(currentIndex); // 🔥 FIX ICI
    }

    setState(() {
      isPlaying = !isPlaying;
      visibleAfterFirstPlay = true;
    });
  }

  // =========================
  // NEXT SONG FIXED
  // =========================
  void nextSong() async {
    setState(() {
      currentIndex = (currentIndex + 1) % songs.length;
    });

    await AudioService.play(currentIndex); // 🔥 FIX ICI

    setState(() {
      isPlaying = true;
    });
  }

  // =========================
  // PREV SONG FIXED
  // =========================
  void prevSong() async {
    setState(() {
      currentIndex = (currentIndex - 1 + songs.length) % songs.length;
    });

    await AudioService.play(currentIndex); // 🔥 FIX ICI

    setState(() {
      isPlaying = true;
    });
  }

  List<String> getFavoriteSongs() {
    List<String> fav = [];
    for (int i = 0; i < songs.length; i++) {
      if (isFavoriteList[i]) {
        fav.add(songs[i]);
      }
    }
    return fav;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 40),
              child: AnimatedScale(
                scale: isPlaying ? 1.0 : 0.9,
                duration: const Duration(milliseconds: 500),
                child: Image.asset(
                  'assets/images/d3607ca97159a3a102f9397cfc13b50b.jpg',
                  height: 400,
                ),
              ),
            ),
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (visibleAfterFirstPlay)
                      IconButton(
                        iconSize: 50,
                        icon: const Icon(Icons.fast_rewind),
                        onPressed: prevSong,
                      ),
                    const SizedBox(width: 8),
                    IconButton(
                      iconSize: 75,
                      icon: Icon(
                        isPlaying ? Icons.pause : Icons.play_arrow,
                      ),
                      onPressed: togglePlay,
                    ),
                    const SizedBox(width: 8),
                    if (visibleAfterFirstPlay)
                      IconButton(
                        iconSize: 50,
                        icon: const Icon(Icons.fast_forward),
                        onPressed: nextSong,
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                if (visibleAfterFirstPlay)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onLongPress: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FavoritePage(
                                favoriteSongs: getFavoriteSongs(),
                              ),
                            ),
                          );
                        },
                        child: IconButton(
                          iconSize: 30,
                          icon: Icon(
                            isFavoriteList[currentIndex]
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: Colors.red,
                          ),
                          onPressed: () async {
                            setState(() {
                              isFavoriteList[currentIndex] =
                                  !isFavoriteList[currentIndex];
                            });

                            await saveFavorites();
                          },
                        ),
                      ),
                      Text(
                        songs[currentIndex],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
