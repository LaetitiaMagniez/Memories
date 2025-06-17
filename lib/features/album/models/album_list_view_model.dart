import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memories_project/features/album/models/album.dart';
import 'package:memories_project/features/album/services/album_dialogs.dart';
import 'package:memories_project/features/album/services/album_repository.dart';
import 'package:memories_project/features/user/models/app_user.dart';
import '../../../core/notifiers/selected_items_notifier.dart';
import '../../../core/providers/app_provider.dart';
import '../../../core/utils/file_cache.dart';

class AlbumListViewModel extends ChangeNotifier {
  final AlbumDialogs albumDialogs = AlbumDialogs();
  final Ref ref;
  final AlbumRepository albumRepository;
  final SelectedItemsNotifier<Album> albumSelectionNotifier;

  AppUser? _currentUser;
  AppUser? get currentUser => _currentUser;

  bool _isLoading = true;
  bool get isLoading => _isLoading;
 final VoidCallback OnManageMode = () {};
  bool isManaging = false;

  AlbumListViewModel({
    required this.ref,
    required this.albumSelectionNotifier,
    required this.albumRepository,
  });

  Future<void> init() async {
    await _loadCurrentUserAndThumbnails();
  }

  Stream<List<Album>> get myAlbumsStream {
    if (_currentUser == null) return const Stream.empty();
    return albumRepository
        .getAlbumsWithDetails(_currentUser!.uid)
        .map((albums) => albums.where((album) => album.userId == _currentUser!.uid).toList());
  }

  Stream<List<Album>> get sharedAlbumsStream {
    if (_currentUser == null) return const Stream.empty();
    return albumRepository.getSharedAlbumsForUser(_currentUser!.uid);
  }

  Future<void> _loadCurrentUserAndThumbnails() async {
    try {
      _isLoading = true;
      notifyListeners();

      final user = await ref.read(appUserProvider.future);
      _currentUser = user;

      if (_currentUser != null) {
        final albums = await albumRepository.getAlbumsWithDetails(_currentUser!.uid).first;
        for (final album in albums) {
          getCachedFilePath(album.thumbnailUrl);
        }
      }
    } catch (e) {
      debugPrint('Erreur loadCurrentUserAndThumbnails: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void refresh() {
    notifyListeners();
  }

  void enterManaging() {
    isManaging = true;
    albumSelectionNotifier.clear();
    notifyListeners();
  }

  void exitManaging() {
    isManaging = false;
    albumSelectionNotifier.clear();
    notifyListeners();
  }

  void clearSelection() {
    albumSelectionNotifier.clear();
    notifyListeners();
  }

  String getExtensionFromUrl(String url) {
    final uri = Uri.parse(url);
    final segments = uri.pathSegments;
    final filename = segments.isNotEmpty ? segments.last : '';
    final parts = filename.split('.');
    return parts.length > 1 ? parts.last : 'jpg';
  }
}
