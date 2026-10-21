import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';
import 'package:mobile_e_learning_micro_course_system/core/media_url.dart';
import 'package:mobile_e_learning_micro_course_system/models/learning_resource.dart';
import 'package:mobile_e_learning_micro_course_system/models/lesson.dart';
import 'package:mobile_e_learning_micro_course_system/data/repositories/lesson_repository.dart';
import 'package:mobile_e_learning_micro_course_system/providers/lesson_provider.dart';
import 'package:mobile_e_learning_micro_course_system/ui/screens/lesson/lesson_detail_screen.dart';
import 'package:mobile_e_learning_micro_course_system/ui/widgets/learning_resource_card.dart';
import 'package:mobile_e_learning_micro_course_system/ui/widgets/lesson_media_player.dart';
import 'support/fake_platforms.dart';

class _BothMediaRepository implements LessonRepository {
  @override
  Future<Lesson?> getLessonDetails(
    String courseId,
    String lessonId,
  ) async => const Lesson(
    id: 'lesson',
    courseId: 'course',
    title: 'Video and audio',
    description: 'Both are available',
    videoUrl:
        'https://learning.ngrok-free.dev/api/media/lessons/videos/video.mp4',
    audioUrl:
        'https://learning.ngrok-free.dev/api/media/lessons/audio/audio.mp3',
  );
  @override
  Future<List<Lesson>> getLessonsForCourse(String courseId) async => [];
  @override
  Future<bool> markLessonCompleted(
    String lessonId, {
    bool completed = true,
  }) async => true;
}

void main() {
  setUp(() {
    VideoPlayerPlatform.instance = FakeVideoPlayer();
  });

  testWidgets('a lesson exposes both its video and audio players', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => LessonProvider(repo: _BothMediaRepository()),
        child: const MaterialApp(
          home: LessonDetailScreen(courseId: 'course', lessonId: 'lesson'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final players = tester
        .widgetList<LessonMediaPlayer>(find.byType(LessonMediaPlayer))
        .toList();
    expect(players.length, 2);
    expect(players[0].isAudio, isFalse);
    expect(players[1].isAudio, isTrue);
  });

  testWidgets('audio plays in-app with the tunnel header and supports pause', (
    tester,
  ) async {
    final player = FakeVideoPlayer();
    VideoPlayerPlatform.instance = player;
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: LessonMediaPlayer(
            url:
                'https://learning.ngrok-free.dev/api/media/lessons/audio/audio.mp3',
            isAudio: true,
          ),
        ),
      ),
    );
    expect(player.sources, isEmpty);
    await tester.tap(find.byIcon(Icons.play_arrow_rounded).first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(player.sources.single.httpHeaders, MediaUrl.tunnelHeaders);
    expect(player.calls, contains('play'));
    await tester.tap(find.byTooltip('Pause'));
    await tester.pump();
    expect(player.calls, contains('pause'));
  });

  testWidgets(
    'attachment video uses an inline player instead of opening a browser',
    (tester) async {
      var openedExternally = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: LearningResourceCard(
                resource: const LearningResource(
                  id: 'video',
                  name: 'Video attachment',
                  fileType: 'video/mp4',
                  fileUrl: 'https://example.com/clip.mp4',
                ),
                onOpen: () {
                  openedExternally = true;
                },
              ),
            ),
          ),
        ),
      );
      expect(find.byType(LessonMediaPlayer), findsOneWidget);
      await tester.tap(find.byIcon(Icons.play_arrow_rounded).first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(openedExternally, isFalse);
      expect(find.byTooltip('Pause'), findsOneWidget);
    },
  );

  testWidgets('image attachment is shown inline and opens a zoomable viewer', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: LearningResourceCard(
              resource: const LearningResource(
                id: 'image',
                name: 'Lesson diagram',
                fileType: 'image/png',
                fileUrl:
                    'https://learning.ngrok-free.dev/api/media/lessons/resources/diagram.png',
              ),
              onOpen: () {},
            ),
          ),
        ),
      ),
    );
    final image = tester.widget<Image>(find.byType(Image));
    expect((image.image as NetworkImage).headers, MediaUrl.tunnelHeaders);
    await tester.tap(find.byTooltip('View image'));
    await tester.pumpAndSettle();
    expect(find.byType(InteractiveViewer), findsOneWidget);
    expect(find.text('Lesson diagram'), findsWidgets);
  });

  testWidgets('failed playback can be retried', (tester) async {
    VideoPlayerPlatform.instance = FakeVideoPlayer(failToLoad: true);
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: LessonMediaPlayer(
            url: 'https://example.com/audio.mp3',
            isAudio: true,
          ),
        ),
      ),
    );
    await tester.tap(find.byIcon(Icons.play_arrow_rounded).first);
    await tester.pumpAndSettle();
    expect(find.textContaining('Could not play this media'), findsOneWidget);
    final healthy = FakeVideoPlayer();
    VideoPlayerPlatform.instance = healthy;
    await tester.tap(find.text('Retry'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(healthy.calls, contains('play'));
  });

  testWidgets('a changed media URL releases the previous player', (
    tester,
  ) async {
    final player = FakeVideoPlayer();
    VideoPlayerPlatform.instance = player;
    final file = ValueNotifier('first');
    addTearDown(file.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ValueListenableBuilder(
            valueListenable: file,
            builder: (context, value, child) => LessonMediaPlayer(
              url: 'https://example.com/$value.mp4',
              isAudio: false,
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byIcon(Icons.play_arrow_rounded).first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    file.value = 'second';
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();
    expect(tester.widget<LessonMediaPlayer>(find.byType(LessonMediaPlayer)).url, 'https://example.com/second.mp4');
    expect(find.text('Video lesson'), findsOneWidget);
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    expect(player.calls, contains('dispose 1'));
    await tester.tap(find.byIcon(Icons.play_arrow_rounded).first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(player.sources.last.uri, 'https://example.com/second.mp4');
  });
}
