import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/album/models/album.dart';
import '../../features/album/models/album_list_view_model.dart';
import '../../features/album/services/album_repository.dart';
import '../../features/memories/models/memory.dart';
import '../../features/user/services/contact_service.dart';
import '../notifiers/friends_notifier.dart';
import '../services/selection_service.dart';



final albumRepositoryProvider = Provider<AlbumRepository>((ref) {
  return AlbumRepository();
});
final contactServiceProvider = Provider<ContactService>((ref) {
  return ContactService();
});

final friendsNotifierProvider = StateNotifierProvider<FriendsNotifier, FriendsState>((ref) {
  final contactService = ref.watch(contactServiceProvider);
  return FriendsNotifier(contactService);
});

final AlbumSelectionService = ChangeNotifierProvider<SelectionService<Album>>((ref) {
  return SelectionService<Album>();
});
final MemorySelectionService = ChangeNotifierProvider<SelectionService<Memory>>((ref) {
  return SelectionService<Memory>();
});

final albumListViewModelProvider = ChangeNotifierProvider<AlbumListViewModel>((ref) {
  final albumSelectionService = ref.watch(AlbumSelectionService);
  final contactService = ref.watch(contactServiceProvider);
  final albumRepository = ref.watch(albumRepositoryProvider);

  return AlbumListViewModel(
    albumSelectionService: albumSelectionService,
    contactService: contactService,
    albumRepository: albumRepository
  );
});
