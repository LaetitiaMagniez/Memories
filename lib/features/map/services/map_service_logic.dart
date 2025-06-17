import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:memories_project/features/memories/services/memories_grouping_service.dart';
import 'dart:convert';
import '../../memories/models/memory.dart';
import 'package:memories_project/features/memories/widget/memory/full_screen_image_view.dart';
import 'package:memories_project/features/memories/widget/video/video_thumbnail_widget.dart';
import 'package:memories_project/features/memories/widget/video/video_viewer.dart';

import 'map_service_mobile.dart';

class MapService {

  final MemoriesGroupingService memoriesGroupingService = MemoriesGroupingService();

  Future<Set<Marker>> createMarkersFromMemories(List<Memory> memories, BuildContext context, { bool isShared = false}) async {
    final Set<Marker> markers = {};
    final Map<String, List<Memory>> memoriesByCity = memoriesGroupingService.groupMemoriesByCity(memories);
    final MapServiceMobile mapServiceMobile = MapServiceMobile();
    String ninjaApiKey = '';

    if (memoriesByCity.isEmpty) {
      debugPrint('Aucune ville trouvée dans les souvenirs.');
      return markers;
    }

    if (!kIsWeb){
      ninjaApiKey=  mapServiceMobile.ninjaApiKey;
    }

    for (var entry in memoriesByCity.entries) {
      final String city = entry.key;
      final List<Memory> cityMemories = entry.value;

      try {
        final url = Uri.parse('https://api.api-ninjas.com/v1/geocoding?city=${Uri.encodeComponent(city)}');
        debugPrint('Récupération coordonnées pour : $city');
        final response = await http.get(url, headers: {'X-Api-Key': ninjaApiKey});

        if (response.statusCode == 200) {
          final List<dynamic> data = json.decode(response.body);
          if (data.isNotEmpty) {
            final LatLng position = LatLng(data[0]['latitude'], data[0]['longitude']);
            debugPrint('Coordonnées trouvées pour $city : ${position.latitude}, ${position.longitude}');

            final markerColor = isShared ? BitmapDescriptor.hueAzure : BitmapDescriptor.hueViolet;


            markers.add(
              Marker(
                markerId: MarkerId(city),
                position: position,
                icon: BitmapDescriptor.defaultMarkerWithHue(markerColor),
                infoWindow: InfoWindow(
                  title: city,
                  snippet: '${cityMemories.length} souvenir(s)',
                ),
                onTap: () => _showMemoryDialog(context, cityMemories),
              ),
            );
          } else {
            debugPrint('Aucune donnée de géocodage pour $city.');
          }
        } else {
          debugPrint('Erreur API Ninja pour $city : ${response.statusCode} ${response.body}');
        }
      } catch (e) {
        debugPrint('Exception lors de la récupération pour $city : $e');
      }
    }

    if (markers.isEmpty) {
      debugPrint('Aucun marqueur créé.');
    }

    return markers;
  }

  void _showMemoryDialog(BuildContext context, List<Memory> memories) {
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
                        onPageChanged: (index) => setState(() => currentPage = index),
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
                                      loadingBuilder: (context, child, loadingProgress) {
                                        if (loadingProgress == null) return child;
                                        return Center(
                                          child: CircularProgressIndicator(
                                            value: loadingProgress.expectedTotalBytes != null
                                                ? loadingProgress.cumulativeBytesLoaded /
                                                loadingProgress.expectedTotalBytes!
                                                : null,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _formatDate(memories[index].date),
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        memories.length,
                            (index) => Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: currentPage == index ? const Color.fromARGB(255, 138, 87, 220) : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text("Fermer"),
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
