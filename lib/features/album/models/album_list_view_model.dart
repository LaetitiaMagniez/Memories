import 'package:flutter/material.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/utils/file_cache.dart';
import '../../user/logic/contact_service.dart';
import '../../user/models/app_user.dart';
import '../logic/album/album_service.dart';
import '../models/album.dart';

class AlbumListViewModel extends ChangeNotifier  {
  final FirestoreService firestoreService = FirestoreService();
  final AlbumService albumService = AlbumService();
  final ContactService contactService = ContactService();

  AppUser? _currentUser;
  AppUser? get currentUser => _currentUser;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  bool isManaging = false;

  void init() async {
    await _loadCurrentUserAndThumbnails();
    notifyListeners();
  }

  Stream<List<Album>> get myAlbumsStream {
    if (_currentUser == null) return const Stream.empty();
    return firestoreService.getAlbumsWithDetails(_currentUser!.uid).map(
          (albums) => albums.where((album) => album.userId == _currentUser!.uid).toList(),
    );
  }

  Stream<List<Album>> get sharedAlbumsStream {
    if (_currentUser == null) return const Stream.empty();
    return firestoreService.getSharedAlbumsForUser(_currentUser!.uid);
  }

  Future<void> _loadCurrentUserAndThumbnails() async {
    try {
      final user = await contactService.loadCurrentUser();
      _currentUser = user;
      _isLoading = false;
      notifyListeners();

      if (_currentUser != null) {
        final albums = await firestoreService
            .getAlbumsWithDetails(_currentUser!.uid)
            .first;
        for (final album in albums) {
          getCachedFilePath(
            album.thumbnailUrl,
            extension: getExtensionFromUrl(album.thumbnailUrl),
          );
        }
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
    }
  }

  String getExtensionFromUrl(String url) {
    final uri = Uri.parse(url);
    final segments = uri.pathSegments;
    final filename = segments.isNotEmpty ? segments.last : '';
    final parts = filename.split('.');
    return parts.length > 1 ? parts.last : 'jpg';
  }

  void refresh() => notifyListeners();

  void exitManaging() {
    isManaging = false;
    notifyListeners();
  }

  void clearSelection() {
    albumService.clearSelection(() => notifyListeners());
  }

  void onAddAlbum(BuildContext context) {
    albumService.showAlbumOptions(context, () {
      isManaging = true;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    super.dispose();
  }
}
