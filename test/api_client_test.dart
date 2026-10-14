import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_e_learning_micro_course_system/data/api/api_client.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ApiClient URL normalization & baseUrl', () {
    test('normalizeUrl appends /api and removes trailing slashes', () {
      expect(ApiClient.normalizeUrl('http://192.168.8.62:8000'), 'http://192.168.8.62:8000/api');
      expect(ApiClient.normalizeUrl('http://192.168.8.62:8000/'), 'http://192.168.8.62:8000/api');
      expect(ApiClient.normalizeUrl('http://192.168.8.62:8000/api'), 'http://192.168.8.62:8000/api');
      expect(ApiClient.normalizeUrl('http://192.168.8.62:8000/api/'), 'http://192.168.8.62:8000/api');
      expect(ApiClient.normalizeUrl('  http://10.0.2.2:8000  '), 'http://10.0.2.2:8000/api');
    });

    test('baseUrl migrates stale fallback 192.168.8.56 to current LAN IP', () async {
      SharedPreferences.setMockInitialValues({
        'backend_server_url': 'http://192.168.8.56:8000/api',
      });

      final url = await ApiClient.instance.baseUrl;
      expect(url, 'http://192.168.8.62:8000/api');
    });

    test('setBaseUrl updates baseUrl with normalized URL', () async {
      SharedPreferences.setMockInitialValues({});

      await ApiClient.instance.setBaseUrl('http://192.168.1.100:8000/');
      final url = await ApiClient.instance.baseUrl;
      expect(url, 'http://192.168.1.100:8000/api');
    });
  });
}
