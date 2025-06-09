import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../upload_progress_bubble.dart';

class UploadProgressDialog extends StatefulWidget {
  final UploadTask uploadTask;

  const UploadProgressDialog({super.key, required this.uploadTask});

  @override
  State<UploadProgressDialog> createState() => _UploadProgressDialogState();
}

class _UploadProgressDialogState extends State<UploadProgressDialog> {
  double _progress = 0.0;
  bool _isDone = false;
  bool _hasError = false;
  bool _isCancelled = false;
  bool _isCancelling = false;

  late final Stream<TaskSnapshot> _snapshotStream;
  late final StreamSubscription<TaskSnapshot> _subscription;

  @override
  void initState() {
    super.initState();

    _snapshotStream = widget.uploadTask.snapshotEvents;
    _subscription = _snapshotStream.listen(_handleSnapshot,
      onError: (error) => _handleError(error),
      cancelOnError: true,
    );

    widget.uploadTask.whenComplete(() {
      final state = widget.uploadTask.snapshot.state;
      if (state == TaskState.success) {
        _handleComplete();
      } else if (state == TaskState.canceled) {
        _handleCancelled();
      } else if (state == TaskState.error) {
        _handleError(null);
      }
    });
  }

  void _handleSnapshot(TaskSnapshot snapshot) {
    if (snapshot.totalBytes > 0) {
      setState(() {
        _progress = snapshot.bytesTransferred / snapshot.totalBytes;
      });
    }
  }

  void _handleComplete() {
    setState(() {
      _progress = 1.0;
      _isDone = true;
    });
    _closeDialogDelayed();
  }

  void _handleCancelled() {
    setState(() {
      _isCancelled = true;
      _isCancelling = false;
    });
    Navigator.of(context).pop(); // Ferme immédiatement si cancel
  }

  void _handleError(Object? error) {
    setState(() {
      _hasError = true;
      _isCancelling = false;
    });
  }

  void _closeDialogDelayed() {
    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) {
          // La pop a déjà eu lieu, rien à faire
          return;
        }
        // Si upload fini, erreur ou annulé, on autorise la fermeture automatique
        final bool canPop = _isDone || _hasError || _isCancelled;
        if (canPop) {
          // Pop possible normalement
          Navigator.of(context).pop(result);
        } else {
          // Sinon, par ex, afficher un dialogue ou empêcher la fermeture
          final shouldCancel = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Annuler le téléversement ?'),
              content: const Text('Voulez-vous vraiment annuler l\'upload en cours ?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Non'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Oui'),
                ),
              ],
            ),
          ) ?? false;
          if (shouldCancel) {
            await widget.uploadTask.cancel();
            Navigator.of(context).pop(result);
          }
        }
      },
      child: AlertDialog(
        title: Text(_hasError
            ? 'Erreur lors du téléversement'
            : _isCancelled
            ? 'Téléversement annulé'
            : 'Téléversement en cours...'),
        content: SizedBox(
          height: 150,
          child: Center(
            child: _hasError
                ? const Icon(Icons.error, color: Colors.red, size: 50)
                : _isCancelled
                ? const Icon(Icons.cancel, color: Colors.grey, size: 50)
                : UploadProgressBubble(progress: _progress),
          ),
        ),
        actions: [
          if (!_isDone && !_hasError && !_isCancelling && !_isCancelled)
            TextButton(
              onPressed: () async {
                setState(() {
                  _isCancelling = true;
                });
                try {
                  await widget.uploadTask.cancel();
                  // La fermeture du dialog se fait dans _handleCancelled()
                } catch (_) {
                  setState(() {
                    _isCancelling = false;
                  });
                }
              },
              child: _isCancelling
                  ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : const Text('Annuler'),
            ),
        ],
      ),
    );
  }
}
