import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memories_project/features/album/models/album.dart';
import 'package:memories_project/features/album/widget/album/album_card.dart';
import 'package:memories_project/features/memories/widget/video/video_thumbnail_widget.dart';
import 'package:memories_project/core/utils/cached_image.dart';

void main() {
  group('AlbumCard Widget', () {
    testWidgets('renders image thumbnail and text info', (WidgetTester tester) async {
      final album = Album(
        id: '1',
        name: 'Vacances',
        thumbnailUrl: 'https://example.com/image.jpg',
        thumbnailType: 'image',
        itemCount: 3,
        userId: 'test',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AlbumCard(
              album: album,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Vacances'), findsOneWidget);
      expect(find.text('3 éléments'), findsOneWidget);
      expect(find.byType(CachedImage), findsOneWidget);
    });

    testWidgets('renders video thumbnail when type is video', (WidgetTester tester) async {
      final album = Album(
        id: '2',
        name: 'Anniversaire',
        thumbnailUrl: 'https://example.com/video.mp4',
        thumbnailType: 'video',
        itemCount: 1,
        userId: 'test',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AlbumCard(
              album: album,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Anniversaire'), findsOneWidget);
      expect(find.text('1 élément'), findsOneWidget);
      expect(find.byType(VideoThumbnailWidget), findsOneWidget);
    });

    testWidgets('renders shimmer when thumbnailUrl is empty', (WidgetTester tester) async {
      final album = Album(
        id: '3',
        name: 'Sans image',
        thumbnailUrl: '',
        thumbnailType: 'image',
        itemCount: 0,
        userId: 'test',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AlbumCard(
              album: album,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Sans image'), findsOneWidget);
      expect(find.text('0 élément'), findsOneWidget);
      expect(find.byType(Container), findsWidgets); // part of shimmer fallback
    });

    testWidgets('calls onTap callback when tapped', (WidgetTester tester) async {
      bool tapped = false;

      final album = Album(
        id: '4',
        name: 'Test',
        thumbnailUrl: 'https://example.com/image.jpg',
        thumbnailType: 'image',
        itemCount: 2,
        userId: 'test',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AlbumCard(
              album: album,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(AlbumCard));
      expect(tapped, isTrue);
    });
  });
}
