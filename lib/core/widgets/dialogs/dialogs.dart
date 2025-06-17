import 'package:flutter/material.dart';

import '../loading/upload_progress_bubble.dart';

class CoreDialogs {
  CoreDialogs._();

  static Future<void> confirmDeleteSingle<T>({
    required BuildContext context,
    required T item,
    required String itemName,
    required Future<void> Function(T item) onDelete,
    required VoidCallback onSuccess,
  }) async {
    bool isDeleting = false;
    double progress = 0.0;

    await showDialog(
      context: context,
      barrierDismissible: !isDeleting,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            Future<void> handleDelete() async {
              setState(() {
                isDeleting = true;
                progress = 0.1;
              });

              try {
                await onDelete(item);

                setState(() {
                  progress = 1.0;
                });

                await Future.delayed(const Duration(seconds: 1));

                if (dialogContext.mounted) Navigator.of(dialogContext).pop();

                onSuccess();

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$itemName supprimé avec succès')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erreur lors de la suppression de $itemName.'),
                      backgroundColor: Theme.of(context).colorScheme.error,
                    ),
                  );
                }
                if (dialogContext.mounted) Navigator.of(dialogContext).pop();
              }
            }

            return AlertDialog(
              title: Text(isDeleting ? 'Suppression...' : 'Confirmation'),
              content: isDeleting
                  ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 16),
                  UploadProgressBubble(progress: progress),
                  const SizedBox(height: 16),
                  Text(progress >= 1.0 ? "Supprimé" : "Suppression en cours..."),
                ],
              )
                  : Text("Voulez-vous vraiment supprimer ${item == 'Album' ? 'l\'' : 'le'} $itemName ?"),
                actions: isDeleting
                  ? null
                  : [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text("Annuler"),
                ),
                TextButton(
                  onPressed: handleDelete,
                  style: TextButton.styleFrom(foregroundColor: Color.fromARGB(255, 55, 14, 138)),
                  child: const Text("Supprimer"),
                ),
              ],
            );
          },
        );
      },
    );
  }

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

    bool isDeleting = false;
    double progress = 0.0;

    await showDialog(
      context: context,
      barrierDismissible: !isDeleting,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            Future<void> handleDelete() async {
              setState(() {
                isDeleting = true;
                progress = 0.1;
              });

              try {
                for (final item in selectedItems) {
                  await onDelete(item);
                }

                setState(() {
                  progress = 1.0;
                });

                await Future.delayed(const Duration(seconds: 1));

                if (dialogContext.mounted) Navigator.of(dialogContext).pop();

                selectedItems.clear();
                onSuccess();

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$count $itemName supprimé(s) avec succès')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erreur lors de la suppression de $itemName.'),
                      backgroundColor: theme.colorScheme.error,
                    ),
                  );
                }
                if (dialogContext.mounted) Navigator.of(dialogContext).pop();
              }
            }

            return AlertDialog(
              backgroundColor: theme.dialogBackgroundColor,
              title: Text(
                isDeleting ? "Suppression..." : "Confirmer la suppression",
                style: TextStyle(color: theme.textTheme.titleLarge?.color),
              ),
              content: isDeleting
                  ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 16),
                  UploadProgressBubble(progress: progress),
                  const SizedBox(height: 16),
                  Text(progress >= 1.0 ? "Supprimé" : "Suppression en cours..."),
                ],
              )
                  : Text(
                "Êtes-vous sûr de vouloir supprimer ${count > 1 ? '$count ' : ''}$itemName ?",
                style: TextStyle(color: theme.textTheme.bodyLarge?.color),
              ),
              actions: isDeleting
                  ? null
                  : [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text("Annuler"),
                ),
                ElevatedButton(
                  style: TextButton.styleFrom(foregroundColor: Color.fromARGB(255, 55, 14, 138)),
                  onPressed: handleDelete,
                  child: const Text("Supprimer"),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
