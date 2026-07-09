import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mobile/core/theme/theme.dart';
import 'package:mobile/features/admin/presentation/bloc/faq/admin_faq_bloc.dart';
import 'package:mobile/features/admin/presentation/bloc/faq/admin_faq_event.dart';
import 'package:mobile/features/admin/presentation/bloc/faq/admin_faq_state.dart';
import 'package:mobile/features/admin/presentation/screens/create_faq_screen.dart';
import 'package:mobile/features/admin/presentation/screens/edit_faq_screen.dart';
import 'package:mobile/features/support/domain/entities/faq.dart';
import 'package:toastification/toastification.dart';

class AdminFaqScreen extends StatefulWidget {
  const AdminFaqScreen({super.key});

  @override
  State<AdminFaqScreen> createState() => _AdminFaqScreenState();
}

class _AdminFaqScreenState extends State<AdminFaqScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<AdminFaqBloc>().add(const LoadAllFaqsEvent());
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
          icon: const Icon(Iconsax.arrow_left, color: Color(0xFF1F2937)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'FAQ Management',
          style: TextStyle(
            color: Color(0xFF1F2937),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2ED573), Color(0xFF1ABC9C)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Iconsax.add, color: Colors.white, size: 20),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreateFaqScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: BlocConsumer<AdminFaqBloc, AdminFaqState>(
        listener: (context, state) {
          if (state is AdminFaqOperationSuccess) {
            toastification.show(
              context: context,
              title: Text(state.message),
              type: ToastificationType.success,
              style: ToastificationStyle.fillColored,
              autoCloseDuration: const Duration(seconds: 2),
            );
          } else if (state is AdminFaqError) {
            toastification.show(
              context: context,
              title: Text(state.message),
              type: ToastificationType.error,
              style: ToastificationStyle.fillColored,
              autoCloseDuration: const Duration(seconds: 3),
            );
          }
        },
        builder: (context, state) {
          if (state is AdminFaqsLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF2ED573)),
            );
          }

          if (state is AdminFaqsLoaded) {
            return Column(
              children: [
                _buildSearchBar(),
                _buildStats(state),
                Expanded(
                  child: state.filteredFaqs.isEmpty
                      ? _buildEmptyState(state.searchQuery != null)
                      : RefreshIndicator(
                          onRefresh: () async {
                            context.read<AdminFaqBloc>().add(
                              LoadAllFaqsEvent(
                                searchQuery: _searchController.text,
                              ),
                            );
                          },
                          color: const Color(0xFF2ED573),
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: state.filteredFaqs.length,
                            itemBuilder: (context, index) {
                              final faq = state.filteredFaqs[index];
                              return _buildFaqCard(faq);
                            },
                          ),
                        ),
                ),
              ],
            );
          }

          if (state is AdminFaqError) {
            return _buildErrorState(state.message);
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search FAQs...',
          hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
          prefixIcon: const Icon(
            Iconsax.search_normal,
            color: Color(0xFF2ED573),
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Iconsax.close_circle, color: Colors.grey),
                  onPressed: () {
                    _searchController.clear();
                    context.read<AdminFaqBloc>().add(
                      const SearchFaqsEvent(query: ''),
                    );
                  },
                )
              : null,
          filled: true,
          fillColor: const Color(0xFFF9FAFB),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF2ED573), width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        onChanged: (value) {
          setState(() {});
          context.read<AdminFaqBloc>().add(SearchFaqsEvent(query: value));
        },
      ),
    );
  }

  Widget _buildStats(AdminFaqsLoaded state) {
    final activeCount = state.faqs.where((faq) => faq.isActive).length;
    final inactiveCount = state.faqs.length - activeCount;

    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        children: [
          _buildStatChip(
            icon: Iconsax.document_text,
            label: 'Total',
            count: state.faqs.length,
            color: const Color(0xFF6B7280),
          ),
          const SizedBox(width: 12),
          _buildStatChip(
            icon: Iconsax.tick_circle,
            label: 'Active',
            count: activeCount,
            color: const Color(0xFF2ED573),
          ),
          const SizedBox(width: 12),
          _buildStatChip(
            icon: Iconsax.close_circle,
            label: 'Inactive',
            count: inactiveCount,
            color: Colors.grey,
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required int count,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1), // ✅ Fixed
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)), // ✅ Fixed
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqCard(Faq faq) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: faq.isActive
              ? const Color(0xFF2ED573).withValues(alpha: 0.3) // ✅ Fixed
              : Colors.grey.withValues(alpha: 0.3), // ✅ Fixed
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05), // ✅ Fixed
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: faq.isActive
                  ? const Color(0xFF2ED573).withValues(alpha: 0.05) // ✅ Fixed
                  : Colors.grey.withValues(alpha: 0.05), // ✅ Fixed
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: faq.isActive
                        ? const Color(0xFF2ED573).withValues(
                            alpha: 0.2,
                          ) // ✅ Fixed
                        : Colors.grey.withValues(alpha: 0.2), // ✅ Fixed
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Iconsax.document_text,
                    color: faq.isActive ? const Color(0xFF2ED573) : Colors.grey,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        faq.question,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (faq.category != null) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withValues(
                              alpha: 0.1,
                            ), // ✅ Fixed
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            faq.category!,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFF2ED573),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: faq.isActive ? const Color(0xFF2ED573) : Colors.grey,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    faq.isActive ? 'Active' : 'Inactive',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Answer Preview
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text(
              faq.answer,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                height: 1.5,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Actions
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    icon: Iconsax.edit_2,
                    label: 'Edit',
                    color: Colors.blue,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EditFaqScreen(faq: faq),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildActionButton(
                    icon: faq.isActive ? Iconsax.eye_slash : Iconsax.eye,
                    label: faq.isActive ? 'Deactivate' : 'Activate',
                    color: faq.isActive
                        ? Colors.orange
                        : const Color(0xFF2ED573),
                    onTap: () {
                      HapticFeedback.lightImpact();
                      context.read<AdminFaqBloc>().add(
                        ToggleFaqStatusEvent(id: faq.id),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildActionButton(
                    icon: Iconsax.trash,
                    label: 'Delete',
                    color: Colors.red,
                    onTap: () => _showDeleteConfirmation(faq.id),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1), // ✅ Fixed
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)), // ✅ Fixed
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isSearch) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF2ED573).withValues(alpha: 0.1), // ✅ Fixed
              shape: BoxShape.circle,
            ),
            child: Icon(
              isSearch ? Iconsax.search_status : Iconsax.document_text,
              size: 64,
              color: const Color(0xFF2ED573),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            isSearch ? 'No FAQs Found' : 'No FAQs Yet',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isSearch
                ? 'Try a different search term'
                : 'Create your first FAQ to help users',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
          if (!isSearch) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateFaqScreen()),
                );
              },
              icon: const Icon(Iconsax.add),
              label: const Text('Create FAQ'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2ED573),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Iconsax.warning_2, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              context.read<AdminFaqBloc>().add(const LoadAllFaqsEvent());
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(String faqId) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1), // ✅ Fixed
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Iconsax.trash, color: Colors.red, size: 20),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Delete FAQ',
                style: TextStyle(
                  color: Color(0xFF1F2937),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: const Text(
          'Are you sure you want to delete this FAQ? This action cannot be undone.',
          style: TextStyle(color: Colors.black54),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              HapticFeedback.mediumImpact();
              context.read<AdminFaqBloc>().add(DeleteFaqEvent(id: faqId));
            },
            style: TextButton.styleFrom(
              backgroundColor: Colors.red.withValues(alpha: 0.1), // ✅ Fixed
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
