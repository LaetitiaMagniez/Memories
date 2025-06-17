import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/material.dart';
import 'package:memories_project/features/memories/models/memory.dart';
import '../../../core/notifiers/selected_items_notifier.dart';
import '../../memories/services/memories_crud_service.dart';
import '../services/map_service_logic.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final SelectedItemsNotifier<Memory> selectionNotifier = SelectedItemsNotifier<Memory>();
  late final MemoriesCrudService memoriesCrudService;
  final MapService mapService = MapService();

  Set<Marker> _markersForUser = {};
  // Set<Marker> _markersShared= {};
  // Set<Marker> _allMarkers = {};
  bool _loadingMarkers = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    memoriesCrudService = MemoriesCrudService(memoriesSelectionNotifier: selectionNotifier);
    _loadMarkers();
  }

  Future<void> _loadMarkers() async {
    try {
      final userMemories = await memoriesCrudService.getAllMemoriesForUser().first;
      final markersUser = await mapService.createMarkersFromMemories(userMemories, context, isShared: false);

      // final sharedMemories = await memoriesCrudService.getAllSharedMemoriesForCurrentUser().first;
      // final markersShared = await mapService.createMarkersFromMemories(sharedMemories, context, isShared: true);
      //
      // final allMarkers = {...markersUser, ...markersShared};

      setState(() {
        _markersForUser = markersUser;
        // _markersShared = markersShared;
        // _allMarkers = allMarkers;
        _loadingMarkers = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loadingMarkers = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingMarkers) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        body: Center(child: Text('Erreur lors du chargement des marqueurs: $_error')),
      );
    }

    return Scaffold(
      body: GoogleMap(
        initialCameraPosition: const CameraPosition(
          target: LatLng(46.603354, 1.888334), // Centre de la France
          zoom: 5,
        ),
        markers: _markersForUser,
      ),
    );
  }
}
