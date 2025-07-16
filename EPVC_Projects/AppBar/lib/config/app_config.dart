enum AppEnvironment { production, test, local }

class AppConfig {
  // Altere aqui para AppEnvironment.test para usar o ambiente de testes
  static AppEnvironment environment = AppEnvironment.test;

  static String get apiBaseUrl {
    switch (environment) {
      case AppEnvironment.test:
        return 'https://qly.appbar.epvc.pt/API';
      case AppEnvironment.production:
        return 'https://appbar.epvc.pt/API';
      case AppEnvironment.local:
        return 'http://192.168.22.88/api';
      default:
        return 'https://appbar.epvc.pt/API';
    }
  }

  // Centralize external XD API endpoint (for local/test/production)
  static String get externalXdApiUrl {
    switch (environment) {
      case AppEnvironment.local:
        return 'http://192.168.22.88/api/api.php';
      case AppEnvironment.test:
        return 'https://qly.appbar.epvc.pt/api/api.php'; // adjust if needed
      case AppEnvironment.production:
      default:
        return 'https://appbar.epvc.pt/api/api.php'; // adjust if needed
    }
  }
} 