import 'package:flutter/material.dart';

class CoreDialogs {
  CoreDialogs._();

  static Future<void> confirmDeleteSelected<T>({
    required BuildContext context,
    required List<T> selectedItems,
    required String itemNameSingular,
    required String itemNamePlural,
    required Future<void> Function(T item) onDelete,
    required VoidCallback onSuccess,
  }) async {
    if (selectedItems.isEmpty) return;

    final theme = Theme.of(context);
    final count = selectedItems.length;
    final itemName = count > 1 ? itemNamePlural : itemNameSingular;

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: theme.dialogBackgroundColor,
        title: Text("Confirmer la suppression",
            style: TextStyle(color: theme.textTheme.titleLarge?.color)),
        content: Text(
          "Êtes-vous sûr de vouloir supprimer $count $itemName ?",
          style: TextStyle(color: theme.textTheme.bodyLarge?.color),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Annuler")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text("Supprimer"),
            onPressed: () async {
              for (final item in selectedItems) {
                await onDelete(item);
              }
              Navigator.pop(context);
              selectedItems.clear();
              onSuccess();
            },
          ),
        ],
      ),
    );
  }
}
