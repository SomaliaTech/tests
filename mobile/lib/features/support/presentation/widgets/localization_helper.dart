// lib/features/support/presentation/widgets/localization_helper.dart
import 'package:flutter/material.dart';

class SupportLocalization {
  final BuildContext context;

  SupportLocalization(this.context);

  // Get current locale
  String get locale => Localizations.localeOf(context).languageCode;

  bool get isSomali => locale.startsWith('so');

  // All localized strings
  String get title => isSomali ? 'Caawimaad & Taageero' : 'Help & Support';

  String get subtitle =>
      isSomali ? 'Sideen ku caawin karnaa?' : 'How can we help you?';

  String get chatWithAdmin =>
      isSomali ? 'La hadal Maamulka' : 'Chat with Admin';

  String get chatDescription => isSomali
      ? 'Bilow wada hadal gudaha app-ka'
      : 'Start an in-app conversation';

  String get otherWays => isSomali
      ? 'Habab kale oo aad nagala soo xiriiri karto'
      : 'Other Ways to Reach Us';

  String get callUs => isSomali ? 'Naga soo wac' : 'Call Us';

  String get emailUs => isSomali ? 'Nagu soo dir Email' : 'Email Us';

  String get faqTitle =>
      isSomali ? "Su'aalaha Badanaa La Weydiiyo" : 'Frequently Asked Questions';

  String get noFaqs =>
      isSomali ? 'Ma jiraan Su\'aalo Weli' : 'No FAQs available yet';

  String get retry => isSomali ? 'Isku day mar kale' : 'Retry';

  String get supportTeam =>
      isSomali ? 'Kooxda FARXADA Taageero' : 'FARXADA Support Team';

  String get replyTime => isSomali
      ? 'Inta badan waxaan ku jawaabnaa 5 daqiiqo gudahood'
      : 'We typically reply within 5 minutes';

  String get loadingFaqs =>
      isSomali ? 'Soo dhaweynta su\'aalaha...' : 'Loading FAQs...';

  String get errorLoadingFaqs => isSomali
      ? 'Cillad ayaa ku timid soo dhaweynta su\'aalaha'
      : 'Failed to load FAQs';

  String get phoneNumber => '2701';
  String get email => 'support@farxada.com';
}

// Extension for easy access
extension SupportLocalizationExt on BuildContext {
  SupportLocalization get supportLocalization => SupportLocalization(this);
}
