import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../logic/memories/memories_service.dart';
import '../models/memory.dart';

class AllMemoriesPage extends StatelessWidget {
  final MemoriesService memoriesService = MemoriesService();

  AllMemoriesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Tous les souvenirs")),
      body: StreamBuilder<List<Memory>>(
        stream: memoriesService.getAllMemoriesForUser(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text("Erreur de chargement"));
          }

          final memories = snapshot.data ?? [];

          if (memories.isEmpty) {
            return const Center(child: Text("Aucun souvenir trouvé"));
          }

          return ListView.builder(
            itemCount: memories.length,
            itemBuilder: (context, index) {
              final memory = memories[index];
              return ListTile(
                title: Text(memory.ville ?? 'Inconnue'),
                subtitle: Text(
                    DateFormat.yMMMd().format(memory.date)),
                leading: memory.type == 'image'
                    ? Image.network(memory.url, width: 50, fit: BoxFit.cover)
                    : const Icon(Icons.video_library),
              );
            },
          );
        },
      ),
    );
  }
}
