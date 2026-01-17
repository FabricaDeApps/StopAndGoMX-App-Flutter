enum ApiEnvironment { local, prod }

class ApiEnv {
  static const String _env = String.fromEnvironment(
    'API_ENV',
    defaultValue: 'prod',
  );

  static ApiEnvironment get current {
    switch (_env) {
      case 'local':
        return ApiEnvironment.local;
      case 'prod':
      default:
        return ApiEnvironment.prod;
    }
  }

  static String get baseUrl {
    switch (current) {
      case ApiEnvironment.local:
        return 'http://192.168.0.194:8000/api';
      case ApiEnvironment.prod:
        return 'https://stopandgomx.app/api';
    }
  }
}
