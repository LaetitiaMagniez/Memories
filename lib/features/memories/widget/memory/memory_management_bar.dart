import 'package:flutter/material.dart';
import '../../../../core/notifiers/selected_items_notifier.dart';
import '../../models/memory.dart';
import '../../services/memories_crud_service.dart';

class ManagementBar extends StatelessWidget {
  final MemoriesCrudService memoriesCrudService;
  final SelectedItemsNotifier<Memory> memoriesSelectionNotifier;

  const ManagementBar({
    super.key,
    required this.memoriesCrudService,
    required this.memoriesSelectionNotifier,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      width: double.infinity,
      color: Colors.white,
      child: Row(
        children: [
          const Expanded(
            child: Text(
              "Touchez un ou plusieurs souvenirs pour les gérer (déplacer ou supprimer).",
              style: TextStyle(fontSize: 14),
            ),
          ),
          if (memoriesSelectionNotifier.selectedItems.isNotEmpty) ...[
            IconButton(
              icon: const Icon(Icons.move_to_inbox),
              tooltip: "Déplacer",
              onPressed: () => memoriesCrudService.onMove(context),
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              tooltip: "Supprimer",
              onPressed: () => memoriesCrudService.onDelete(context),
            ),
          ],
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: "Annuler",
            onPressed: memoriesCrudService.onCancel,
          ),
        ],
      ),
    );
  }
}
