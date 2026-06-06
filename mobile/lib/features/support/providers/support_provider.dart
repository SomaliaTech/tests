import 'package:flutter/material.dart';
import 'package:mobile/features/support/data/model/support_models.dart';

enum SupportTab { faq, categories }

class SupportProvider extends ChangeNotifier {
  SupportTab _currentTab = SupportTab.faq;
  String _searchQuery = '';

  SupportTab get currentTab => _currentTab;
  String get searchQuery => _searchQuery;

  List<SupportCategory> get categories => supportCategories;

  List<FAQItem> get filteredFaqs {
    if (_searchQuery.isEmpty) {
      return faqs;
    }
    return faqs
        .where(
          (faq) =>
              faq.question.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              faq.answer.toLowerCase().contains(_searchQuery.toLowerCase()),
        )
        .toList();
  }

  bool get hasSearchResults => filteredFaqs.isNotEmpty;

  void setTab(SupportTab tab) {
    if (_currentTab != tab) {
      _currentTab = tab;
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = '';
    notifyListeners();
  }

  // Contact methods
  void contactChat() {
    debugPrint('Chat support tapped');
  }

  void contactCall() {
    debugPrint('Call support tapped');
  }

  void contactEmail() {
    debugPrint('Email support tapped');
  }

  void onCategoryTap(SupportCategory category) {
    debugPrint('Category tapped: ${category.title}');
  }
}
