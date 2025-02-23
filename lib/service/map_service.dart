import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:memories_project/class/souvenir.dart';

class MapService {
  // Grouper les souvenirs par ville
  static Map<String, List<Souvenir>> groupSouvenirsByCity(List<Souvenir> souvenirs) {
    Map<String, List<Souvenir>> souvenirsByCity = {};

    for (var souvenir in souvenirs) {
      if (souvenir.ville != null && souvenir.ville!.isNotEmpty) {
        if (!souvenirsByCity.containsKey(souvenir.ville)) {
          souvenirsByCity[souvenir.ville!] = [];
        }
        souvenirsByCity[souvenir.ville!]!.add(souvenir);
      }
    }

    return souvenirsByCity;
  }

  // Créer des marqueurs à partir des souvenirs
  static Future<Set<Marker>> createMarkersFromSouvenirs(List<Souvenir> souvenirs, BuildContext context) async {
    Set<Marker> markers = {};
    final String apiKey = dotenv.env['ninja_API_KEY'] ?? '';

    // Grouper les souvenirs par ville
    Map<String, List<Souvenir>> souvenirsByCity = groupSouvenirsByCity(souvenirs);

    for (var entry in souvenirsByCity.entries) {
      String city = entry.key;
      List<Souvenir> citySouvenirs = entry.value;

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
                _showPhotoDialog(context, citySouvenirs); // Passez les souvenirs de la ville
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

  // Afficher une boîte de dialogue avec les images des souvenirs
  static void _showPhotoDialog(BuildContext context, List<Souvenir> souvenirs) {
  int currentPage = 0; // Index de l'image actuellement affichée

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            content: Container(
              width: double.maxFinite, // Prend toute la largeur disponible
              child: Column(
                mainAxisSize: MainAxisSize.min, // La colonne s'adapte à son contenu
                children: [
                  // PageView pour faire défiler les images des souvenirs
                  SizedBox(
                    height: 300, // Hauteur fixe pour le PageView
                    child: PageView.builder(
                      itemCount: souvenirs.length,
                      onPageChanged: (index) {
                        setState(() {
                          currentPage = index; // Mettez à jour l'index de la page actuelle
                        });
                      },
                      itemBuilder: (context, index) {
                        return Column(
                          children: [
                            Expanded(
                              child: Image.network(
                                souvenirs[index].url,
                                fit: BoxFit.cover, // Ajuste l'image à la taille disponible
                                loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                                  if (loadingProgress == null) {
                                    return child;
                                  } else {
                                    return Center(
                                      child: CircularProgressIndicator(
                                        value: loadingProgress.expectedTotalBytes != null
                                            ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                            : null,
                                      ),
                                    );
                                  }
                                },
                              ),
                            ),
                            SizedBox(height: 8),
                          ],
                        );
                      },
                    ),
                  ),
                  SizedBox(height: 16),
                  // Indicateurs de position (points)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      souvenirs.length,
                      (index) => Container(
                        width: 8,
                        height: 8,
                        margin: EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: currentPage == index ? Colors.blue : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Fermez la boîte de dialogue
                    },
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
}