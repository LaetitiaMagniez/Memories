import 'package:flutter_riverpod/flutter_riverpod.dart';

class AlbumManagementNotifier extends StateNotifier<bool> {
  AlbumManagementNotifier() : super(false);

  void enterManaging() => state = true;
  void exitManaging() => state = false;
}
