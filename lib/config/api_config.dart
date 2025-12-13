class ApiConfig {
  // EC2 server - 所有組員和設備都可以訪問
  // 移除 /api 前綴，因為後端根路由直接提供服務
  static const String baseUrl = 'http://3.26.147.119:8000';
  static const String wsUrl = 'ws://3.26.147.119:8000/ws';
  static const String googleMapsApiKey = 'AIzaSyCbIh5wZOTTPFWX1xURjOEX699LpKAU0wQ';

  // Timeout configurations
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
