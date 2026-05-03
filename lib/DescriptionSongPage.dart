import 'package:flutter/material.dart';

class DescriptionSongPage extends StatelessWidget {
  final String song;
  const DescriptionSongPage({super.key, required this.song});

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
    return Scaffold(
      appBar: AppBar(
        title: Text(song),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 2,
      ),
      body: Container(
        color: Colors.grey.shade100,
        padding: const EdgeInsets.all(24),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    getDescription(song),
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
    );
  }
}
