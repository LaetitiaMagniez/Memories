import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memories_project/core/providers/app_provider.dart';
import 'package:memories_project/features/album/models/album.dart';
import 'package:memories_project/features/memories/models/memory.dart';
import '../../features/album/models/album_test.mocks.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
  });

  tearDown(() {
    container.dispose();
  });

  test('All providers should be properly instantiated', () {
    expect(container.read(albumRepositoryProvider), isNotNull);
    expect(container.read(contactServiceProvider), isNotNull);
    expect(container.read(friendsNotifierProvider), isNotNull);
    expect(container.read(albumListViewModelProvider), isNotNull);
  });

}
