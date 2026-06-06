import 'package:flutter/material.dart';
import 'package:mobile/features/support/presentation/widgets/contact_button.dart';
import 'package:mobile/features/support/presentation/widgets/faq_card.dart';
import 'package:mobile/features/support/providers/support_provider.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';

class SupportView extends StatefulWidget {
  const SupportView({super.key});

  @override
  State<SupportView> createState() => _SupportViewState();
}

class _SupportViewState extends State<SupportView> {
  // Maintained text controller instance across screen state rebuilds
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left, color: Color(0xFF333333)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Help Center',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF333333),
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Consumer<SupportProvider>(
            builder: (context, provider, child) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => provider.setTab(SupportTab.faq),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: provider.currentTab == SupportTab.faq
                                    ? const Color(0xFF2ED573)
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                          ),
                          child: Text(
                            'FAQs',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: provider.currentTab == SupportTab.faq
                                  ? const Color(0xFF2ED573)
                                  : Colors.grey[500],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => provider.setTab(SupportTab.categories),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color:
                                    provider.currentTab == SupportTab.categories
                                    ? const Color(0xFF2ED573)
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                          ),
                          child: Text(
                            'Help',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color:
                                  provider.currentTab == SupportTab.categories
                                  ? const Color(0xFF2ED573)
                                  : Colors.grey[500],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
      body: Consumer<SupportProvider>(
        builder: (context, provider, child) {
          if (provider.currentTab == SupportTab.categories) {
            return _buildCategoriesTab(context, provider);
          } else {
            return _buildFaqTab(context, provider);
          }
        },
      ),
    );
  }

  Widget _buildCategoriesTab(BuildContext context, SupportProvider provider) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 8),

          // Contact Support Section
          Container(
            margin: const EdgeInsets.all(15),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Still need help?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Can't find what you're looking for? We're here to help.",
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                ),
                const SizedBox(height: 20),
                ContactButton(
                  icon: Iconsax.message,
                  title: 'Chat with us',
                  subtitle: 'Average response time: 2 mins',
                  onTap: () {
                    provider.contactChat();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Starting chat support...'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                ),
                ContactButton(
                  icon: Iconsax.call,
                  title: 'Call us',
                  subtitle: '+252 61 673 9858',
                  onTap: () {
                    provider.contactCall();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Calling support...'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                ),
                ContactButton(
                  icon: Iconsax.sms,
                  title: 'Email us',
                  subtitle: 'support@soomar.so',
                  onTap: () {
                    provider.contactEmail();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Opening email...'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFaqTab(BuildContext context, SupportProvider provider) {
    return Column(
      children: [
        // Search Bar
        const SizedBox(height: 40),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: SearchBar(
            backgroundColor: WidgetStateProperty.all(Colors.grey[100]),
            controller: _searchController,
            padding: WidgetStatePropertyAll(
              EdgeInsets.symmetric(horizontal: 20),
            ),
            hintText: 'How can we help you?',
            onChanged: (query) {
              provider.setSearchQuery(query);
            },
            trailing: [
              if (_searchController.text.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    provider.clearSearch();
                  },
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // FAQ List
        Expanded(
          child: provider.filteredFaqs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Iconsax.search_normal,
                        size: 60,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No results found',
                        style: TextStyle(fontSize: 16, color: Colors.grey[500]),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Try searching with different keywords',
                        style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  itemCount: provider.filteredFaqs.length,
                  itemBuilder: (context, index) {
                    final faq = provider.filteredFaqs[index];
                    return FAQCard(item: faq);
                  },
                ),
        ),
      ],
    );
  }
}
