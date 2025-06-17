import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/album/models/album.dart';
import '../../features/album/models/album_list_view_model.dart';
import '../../features/album/services/album_options_menu.dart';
import '../../features/album/services/album_repository.dart';
import '../../features/memories/models/memory.dart';
import '../../features/memories/services/memories_crud_service.dart';
import '../../features/memories/services/memories_options_menu.dart';
import '../../features/user/models/app_user.dart';
import '../../features/user/services/contact_service.dart';
import '../notifiers/friends_notifier.dart';
import '../notifiers/management_notifier.dart';
import '../notifiers/paginated_data_notifier.dart';
import '../notifiers/selected_items_notifier.dart';
import '../notifiers/selection_controller.dart';
import '../notifiers/theme_notifier.dart';

final albumRepositoryProvider = Provider<AlbumRepository>((ref) {
  return AlbumRepository();
});

final albumSelectionControllerProvider = ChangeNotifierProvider<SelectionController<Album>>((ref) {
  return SelectionController<Album>();
});

final albumManagementProvider =
StateNotifierProvider<AlbumManagementNotifier, bool>((ref) {
  return AlbumManagementNotifier();
});

final albumListViewModelProvider = ChangeNotifierProvider<AlbumListViewModel>((ref) {
  final albumRepository = ref.watch(albumRepositoryProvider);
  final albumSelectionNotifier = ref.watch(selectedAlbumsProvider.notifier);

  final viewModel = AlbumListViewModel(
    ref: ref,
    albumRepository: albumRepository,
    albumSelectionNotifier: albumSelectionNotifier,
  );

  viewModel.init();

  return viewModel;
});


final albumOptionsMenuProvider = Provider<AlbumOptionsMenu>((ref) {
  return AlbumOptionsMenu();
});

final albumsStreamProvider = StreamProvider<List<Album>>((ref) {
  final user = ref.watch(appUserProvider).value;
  if (user == null) return const Stream.empty();
  return ref.watch(albumRepositoryProvider).getAlbumsWithDetails(user.uid);
});


final appUserProvider = FutureProvider<AppUser?>((ref) async {
  final firebaseUser = await ref.watch(firebaseUserProvider.future);
  if (firebaseUser == null) return null;

  final doc = await FirebaseFirestore.instance
      .collection('users')
      .doc(firebaseUser.uid)
      .get();

  if (!doc.exists) return null;

  return AppUser.fromDocument(doc);
});

final contactServiceProvider = Provider<ContactService>((ref) {
  return ContactService();
});

final connectivityProvider = StreamProvider<List<ConnectivityResult>>((ref) {
  return Connectivity().onConnectivityChanged;
});

final firebaseUserProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

final friendsNotifierProvider = StateNotifierProvider<FriendsNotifier, FriendsState>((ref) {
  final contactService = ref.watch(contactServiceProvider);
  return FriendsNotifier(contactService);
});

final memoriesCrudServiceProvider = Provider<MemoriesCrudService>((ref) {
  return MemoriesCrudService(memoriesSelectionNotifier: ref.watch(selectedMemoriesProvider.notifier));
});

final memoriesOptionsMenuProvider = Provider<MemoriesOptionsMenu>((ref) {
  return MemoriesOptionsMenu();
});

final memorySelectionControllerProvider = ChangeNotifierProvider<SelectionController<Memory>>((ref) {
  return SelectionController<Memory>();
});

final paginatedMemoriesProvider = StateNotifierProvider<PaginatedDataNotifier<Memory>, AsyncValue<List<Memory>>>(
      (ref) => PaginatedDataNotifier<Memory>(ref.watch(memoriesCrudServiceProvider)),
);


final selectedAlbumsProvider = StateNotifierProvider<SelectedItemsNotifier<Album>, Set<Album>>(
      (ref) => SelectedItemsNotifier<Album>(),
);


final selectedMemoriesProvider = StateNotifierProvider.autoDispose<SelectedItemsNotifier<Memory>, Set<Memory>>(
      (ref) => SelectedItemsNotifier<Memory>(),
);

final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) async {
  return await SharedPreferences.getInstance();
});

final themeNotifierProvider = AsyncNotifierProvider<ThemeAsyncNotifier, ThemeMode>(ThemeAsyncNotifier.new);
