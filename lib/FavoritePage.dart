import 'package:flutter/material.dart';
import 'Database_helper.dart'; // ✅ remplacer SharedPreferences
import 'DescriptionSongPage.dart';

class FavoritePage extends StatefulWidget {
  final List<String> favoriteSongs;
  const FavoritePage({super.key, required this.favoriteSongs});

  @override
  State<FavoritePage> createState() => _FavoritePageState();
}

class _FavoritePageState extends State<FavoritePage> {
  String? selectedSong;

  // ✅ SQLITE DELETE 
  Future<void> removeFavorite(String song) async {
    await DatabaseHelper.instance.removeFavorite(song);

    setState(() {
      widget.favoriteSongs.remove(song);
      if (selectedSong == song) selectedSong = null;
    });
  }

  String getDescription(String song) {
    switch (song) {
      case "song1.wav":
        return "This is the description of Song 1. A calm and relaxing music. "
            "Perfect for meditation, reading, or just to relax your mind. "
            "Lorem ipsum dolor sit amet, consectetur adipiscing elit. "
            "Phasellus sit amet justo non lectus fermentum consequat. "
            "Sed euismod, lorem vel consectetur luctus, sem sapien ullamcorper enim, "
            "sed efficitur dolor augue nec lorem.";
      case "song2.wav":
        return "This is the description of Song 2. Energetic and powerful vibes. "
            "Great for workouts, morning energy boosts, or motivating your day. "
            "Lorem ipsum dolor sit amet, consectetur adipiscing elit. "
            "Phasellus sit amet justo non lectus fermentum consequat. "
            "Sed euismod, lorem vel consectetur luctus, sem sapien ullamcorper enim, "
            "sed efficitur dolor augue nec lorem.";
      default:
        return "No description available.";
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Favorite Songs"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 2,
      ),
      body: widget.favoriteSongs.isEmpty
          ? const Center(
              child: Text(
                "No favorite songs yet ❤️",
                style: TextStyle(fontSize: 18),
              ),
            )
          : isLandscape
              ? Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: ListView.builder(
                        itemCount: widget.favoriteSongs.length,
                        itemBuilder: (context, index) {
                          final song = widget.favoriteSongs[index];
                          return ListTile(
                            leading: const Icon(Icons.music_note),
                            title: Text(song),
                            selected: song == selectedSong,
                            onTap: () {
                              setState(() {
                                selectedSong = song;
                              });
                            },
                            onLongPress: () {
                              showDialog(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text("Supprimer"),
                                  content: Text("Supprimer $song ?"),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context),
                                      child: const Text("Annuler"),
                                    ),
                                    TextButton(
                                      onPressed: () async {
                                        await removeFavorite(song);
                                        Navigator.pop(context);
                                      },
                                      child: const Text("Supprimer"),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: selectedSong == null
                          ? const SizedBox()
                          : Container(
                              color: Colors.grey.shade100,
                              padding: const EdgeInsets.all(16),
                              child: Card(
                                elevation: 4,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                color: Colors.white,
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: SingleChildScrollView(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          selectedSong!,
                                          style: const TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          getDescription(selectedSong!),
                                          style: const TextStyle(
                                            fontSize: 18,
                                            height: 1.5,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                    ),
                  ],
                )
              : ListView.builder(
                  itemCount: widget.favoriteSongs.length,
                  itemBuilder: (context, index) {
                    final song = widget.favoriteSongs[index];
                    return ListTile(
                      leading: const Icon(Icons.music_note),
                      title: Text(song),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                DescriptionSongPage(song: song),
                          ),
                        );
                      },
                      onLongPress: () {
                        showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text("Supprimer"),
                            content: Text("Supprimer $song ?"),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text("Annuler"),
                              ),
                              TextButton(
                                onPressed: () async {
                                  await removeFavorite(song);
                                  Navigator.pop(context);
                                },
                                child: const Text("Supprimer"),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
    );
  }
}