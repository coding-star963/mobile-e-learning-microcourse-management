import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_e_learning_micro_course_system/core/media_url.dart';
import 'package:mobile_e_learning_micro_course_system/models/learning_resource.dart';
import 'package:mobile_e_learning_micro_course_system/models/lesson.dart';

void main() {
  const base = 'https://learning.ngrok-free.dev/api';
  test(
    'uploads use the phone server, including old localhost and LAN links',
    () {
      for (final url in [
        'lessons/videos/clip.mp4',
        '/storage/lessons/videos/clip.mp4',
        'storage/lessons/videos/clip.mp4',
        '/api/media/lessons/videos/clip.mp4',
        'http://localhost:8000/storage/lessons/videos/clip.mp4',
        'http://127.0.0.1:8000/api/media/lessons/videos/clip.mp4',
        'http://192.168.8.56:8000/storage/lessons/videos/clip.mp4',
        'https://old.ngrok-free.app/storage/lessons/videos/clip.mp4',
      ]) {
        expect(
          MediaUrl.resolve(url, base),
          'https://learning.ngrok-free.dev/api/media/lessons/videos/clip.mp4',
        );
      }
    },
  );
  test('external providers, URL encoding and query strings are preserved', () {
    const external = 'https://cdn.example.com/storage/cover.jpg?size=large';
    expect(MediaUrl.resolve(external, base), external);
    expect(
      MediaUrl.resolve('/storage/lessons/resources/my%20photo.png?v=2', base),
      'https://learning.ngrok-free.dev/api/media/lessons/resources/my%20photo.png?v=2',
    );
    expect(MediaUrl.resolve(null, base), isNull);
    expect(MediaUrl.resolve('', base), isNull);
    expect(MediaUrl.resolve('javascript:alert(1)', base), isNull);
  });
  test('nested API responses normalize thumbnails and lesson media only', () {
    final result = MediaUrl.resolveResponse({
      'data': [
        {
          'thumbnail': '/storage/course-thumbnails/cover.jpg',
          'video_url': 'http://localhost:8000/storage/lessons/videos/clip.mp4',
          'audio_url': '/storage/lessons/audio/clip.mp3',
          'resources': [
            {'file_url': '/storage/lessons/resources/photo.png'},
          ],
          'description': 'http://localhost:8000/storage/example',
        },
      ],
    }, base);
    final item = result['data'][0];
    expect(item['thumbnail'], '$base/media/course-thumbnails/cover.jpg');
    expect(item['video_url'], '$base/media/lessons/videos/clip.mp4');
    expect(item['audio_url'], '$base/media/lessons/audio/clip.mp3');
    expect(
      item['resources'][0]['file_url'],
      '$base/media/lessons/resources/photo.png',
    );
    expect(item['description'], 'http://localhost:8000/storage/example');
    final lesson = Lesson.fromJson(item as Map<String, dynamic>);
    expect(lesson.resources.single.fileUrl, '$base/media/lessons/resources/photo.png');
  });
  test('tunnel bypass headers are used only for tunnel hosts', () {
    expect(
      MediaUrl.headersFor('$base/media/lessons/videos/clip.mp4'),
      MediaUrl.tunnelHeaders,
    );
    expect(MediaUrl.headersFor('https://cdn.example.com/photo.png'), isEmpty);
  });
  test(
    'attachments detect image, audio and video from MIME types and extensions',
    () {
      expect(
        const LearningResource(
          id: '1',
          name: 'Image',
          fileType: 'image/png',
        ).isImage,
        isTrue,
      );
      expect(
        const LearningResource(
          id: '2',
          name: 'Audio',
          fileType: 'audio/mpeg',
        ).isAudio,
        isTrue,
      );
      expect(
        const LearningResource(
          id: '3',
          name: 'Video',
          fileType: 'video/mp4',
        ).isVideo,
        isTrue,
      );
      expect(
        const LearningResource(
          id: '4',
          name: 'Image',
          fileType: 'application/octet-stream',
          fileUrl: 'https://example.com/photo.JPG',
        ).isImage,
        isTrue,
      );
      expect(
        const LearningResource(
          id: '5',
          name: 'notes.pdf',
          fileType: 'application/pdf',
        ).isImage,
        isFalse,
      );
    },
  );
}
