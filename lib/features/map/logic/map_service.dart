import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:memories_project/features/memories/widget/memory/full_screen_image_view.dart';
import 'package:memories_project/features/memories/widget/video/video_thumbnail_widget.dart';
import 'package:memories_project/features/memories/widget/video/video_viewer.dart';

import '../../memories/models/memory.dart';


class MapService {

  // Grouper les souvenirs par ville
  static Map<String, List<Memory>> groupMemoriesByCity(List<Memory> memories) {
    Map<String, List<Memory>> memoriesByCity = {};

    for (var memory in memories) {
      if (memory.ville != null && memory.ville!.isNotEmpty) {
        if (!memoriesByCity.containsKey(memory.ville)) {
          memoriesByCity[memory.ville!] = [];
        }
        memoriesByCity[memory.ville!]!.add(memory);
      }
    }

    return memoriesByCity;
  }

  // Créer des marqueurs à partir des souvenirs
  static Future<Set<Marker>> createMarkersFromMemories(List<Memory> memories, BuildContext context) async {
    Set<Marker> markers = {};
    final String apiKey = dotenv.env['NINJA_API_KEY'] ?? '';

    // Grouper les souvenirs par ville
    Map<String, List<Memory>> memoriesByCity = groupMemoriesByCity(memories);

    for (var entry in memoriesByCity.entries) {
      String city = entry.key;
      List<Memory> citySouvenirs = entry.value;

      try {
        final url = Uri.parse('https://api.api-ninjas.com/v1/geocoding?city=${Uri.encodeComponent(city)}');
        final response = await http.get(
          url,
          headers: {'X-Api-Key': apiKey},
        );

        if (response.statusCode == 200) {
          final List<dynamic> data = json.decode(response.body);
          if (data.isNotEmpty) {
            final LatLng position = LatLng(data[0]['latitude'], data[0]['longitude']);
            markers.add(Marker(
              markerId: MarkerId(city),
              position: position,
              infoWindow: InfoWindow(
                title: city,
                snippet: '${citySouvenirs.length} souvenir(s)',
              ),
              onTap: () {
                _showMemoryDialog(context, citySouvenirs); // Passez les souvenirs de la ville
              },
            ));
          }
        }
      } catch (e) {
        debugPrint("Erreur lors de la récupération des coordonnées pour $city: $e");
      }
    }

    return markers;
  }

  static void _showMemoryDialog(BuildContext context, List<Memory> memories) {
    int currentPage = 0;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.9,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.45,
                      child: PageView.builder(
                        itemCount: memories.length,
                        onPageChanged: (index) {
                          setState(() {
                            currentPage = index;
                          });
                        },
                        itemBuilder: (context, index) {
                          return Column(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    if (memories[index].type == 'image') {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => FullScreenImageView(url: memories[index].url),
                                        ),
                                      );
                                    } else {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => VideoViewer(memories[index].url),
                                        ),
                                      );
                                    }
                                  },
                                  child: Transform.scale(
                                    scale: 0.9,
                                    child: memories[index].type == 'video'
                                      ? AspectRatio(
                                          aspectRatio: 4 / 3,
                                          child: VideoThumbnailWidget(memories[index].url),
                                        )
                                      : Image.network(
                                      memories[index].url,
                                          fit: BoxFit.contain,
                                          loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                                            if (loadingProgress == null) return child;
                                            return Center(
                                              child: CircularProgressIndicator(
                                                value: loadingProgress.expectedTotalBytes != null
                                                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                                    : null,
                                              ),
                                            );
                                          },
                                        ),
                                  ),
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                _formatDate(memories[index].date),
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        memories.length,
                        (index) => Container(
                          width: 8,
                          height: 8,
                          margin: EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: currentPage == index ? const Color.fromARGB(255, 138, 87, 220) : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text("Fermer"),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  static String _formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
  }

}