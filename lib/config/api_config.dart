class ApiConfig {
  static const String baseUrl = 'https://server.allgiftstudio.com';
  static const String loginEndpoint = '/api/auth/login';
  static const String refreshEndpoint = '/api/auth/refresh';
  static const String requestOtpEndpoint = '/api/auth/request-otp';
  static const String verifyOtpEndpoint = '/api/auth/verify-otp';

  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
