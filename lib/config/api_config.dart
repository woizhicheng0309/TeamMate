import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  // EC2 server - 所有組員和設備都可以訪問
  // 移除 /api 前綴，因為後端根路由直接提供服務
  static String get baseUrl =>
      dotenv.env['AWS_BACKEND_URL'] ?? 'http://3.26.147.119:8000';
  static String get wsUrl =>
      'ws://${baseUrl.replaceFirst('http://', '')}:8000/ws';
  static String get googleMapsApiKey => dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';

  // Timeout configurations
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
