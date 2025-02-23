import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/material.dart';
import 'package:memories_project/class/souvenir.dart';
import 'package:memories_project/service/souvenir_service.dart';
import 'package:memories_project/service/map_service.dart';

class MapPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Carte des souvenirs")),
      body: StreamBuilder<List<Souvenir>>(
        stream: getAllSouvenirsForUser(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Erreur lors de la récupération des souvenirs"));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text("Aucun souvenir trouvé"));
          }

          return FutureBuilder<Set<Marker>>(
            future: MapService.createMarkersFromSouvenirs(snapshot.data!, context),
            builder: (context, markersSnapshot) {
              if (markersSnapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }
              if (markersSnapshot.hasError) {
                debugPrint("Erreur dans FutureBuilder: ${markersSnapshot.error}"); // Affichez l'erreur
                return Center(child: Text("Erreur lors de la création des marqueurs"));
              }

              return GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: LatLng(46.603354, 1.888334), // Centre de la France
                  zoom: 5,
                ),
                markers: markersSnapshot.data ?? {},
              );
            },
          );
        },
      ),
    );
  }
}