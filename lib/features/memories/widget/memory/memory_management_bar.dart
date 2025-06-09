import 'package:flutter/material.dart';
import '../../logic/memories/memories_service.dart';

class ManagementBar extends StatelessWidget {
  final MemoriesService memoriesService;
  final VoidCallback onMove;
  final VoidCallback onDelete;
  final VoidCallback onCancel;

  const ManagementBar({
    super.key,
    required this.memoriesService,
    required this.onMove,
    required this.onDelete,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      width: double.infinity,
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: const Text(
              "Touchez un ou plusieurs souvenirs pour les gérer (déplacer ou supprimer).",
              style: TextStyle(fontSize: 14),
            ),
          ),
          if (memoriesService.selectedMemories.isNotEmpty) ...[
            IconButton(
              icon: const Icon(Icons.move_to_inbox),
              tooltip: "Déplacer",
              onPressed: onMove,
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              tooltip: "Supprimer",
              onPressed: onDelete,
            ),
          ],
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: "Annuler",
            onPressed: onCancel,
          ),
        ],
      ),
    );
  }
}
