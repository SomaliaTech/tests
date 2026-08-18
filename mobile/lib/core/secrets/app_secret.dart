import 'dart:io' show Platform;

class AppSecrets {
  // Platform-specific Google Client IDs
  static String get googleClientId {
    if (Platform.isIOS) {
      return "159665748516-q57ehiuvg427bluh15gdj701disc746r.apps.googleusercontent.com"; // ✅ iOS
    } else if (Platform.isAndroid) {
      return "159665748516-9kan2pvb50ap4uvdc3djkpr9g73p0nt5.apps.googleusercontent.com"; // ✅ Android
    } else {
      // Web or default fallback
      return "159665748516-bffn5l47e89cmjs2bl1nsif7q2k79u3v.apps.googleusercontent.com"; // ✅ Web
    }
  }
}
