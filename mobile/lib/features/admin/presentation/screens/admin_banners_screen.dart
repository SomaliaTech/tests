import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mobile/core/theme/theme.dart';
import 'package:mobile/features/admin/presentation/bloc/banner/admin_banner_bloc.dart';
import 'package:mobile/features/admin/presentation/bloc/banner/admin_banner_event.dart';
import 'package:mobile/features/admin/presentation/bloc/banner/admin_banner_state.dart';
import 'package:mobile/features/admin/presentation/screens/create_banner_screen.dart';
import 'package:mobile/features/admin/presentation/screens/edit_banner_screen.dart';
import 'package:mobile/features/product/domain/entities/banner.dart';

import 'package:toastification/toastification.dart';

class AdminBannersScreen extends StatefulWidget {
  const AdminBannersScreen({super.key});

  @override
  State<AdminBannersScreen> createState() => _AdminBannersScreenState();
}

class _AdminBannersScreenState extends State<AdminBannersScreen> {
  @override
  void initState() {
    super.initState();
    context.read<AdminBannerBloc>().add(const LoadAllBannersEvent());
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
          'Banner Management',
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
                MaterialPageRoute(builder: (_) => const CreateBannerScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: BlocConsumer<AdminBannerBloc, AdminBannerState>(
        listener: (context, state) {
          if (state is AdminBannerOperationSuccess) {
            toastification.show(
              context: context,
              title: Text(state.message),
              type: ToastificationType.success,
              style: ToastificationStyle.fillColored,
              autoCloseDuration: const Duration(seconds: 2),
            );
          } else if (state is AdminBannerError) {
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
          if (state is AdminBannersLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF2ED573)),
            );
          }

          if (state is AdminBannersLoaded) {
            if (state.banners.isEmpty) {
              return _buildEmptyState();
            }

            return RefreshIndicator(
              onRefresh: () async {
                context.read<AdminBannerBloc>().add(
                  const LoadAllBannersEvent(),
                );
              },
              color: const Color(0xFF2ED573),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: state.banners.length,
                itemBuilder: (context, index) {
                  final banner = state.banners[index];
                  return _buildBannerCard(banner);
                },
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF2ED573).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Iconsax.image,
              size: 64,
              color: Color(0xFF2ED573),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'No Banners Yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first banner to display\non the home screen',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreateBannerScreen()),
              );
            },
            icon: const Icon(Iconsax.add),
            label: const Text('Create Banner'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2ED573),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBannerCard(AppBanner banner) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Preview
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
            child: Stack(
              children: [
                Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient:
                        banner.gradientStart != null &&
                            banner.gradientEnd != null
                        ? LinearGradient(
                            colors: [
                              _hexToColor(banner.gradientStart!),
                              _hexToColor(banner.gradientEnd!),
                            ],
                          )
                        : null,
                    color: banner.backgroundColor != null
                        ? _hexToColor(banner.backgroundColor!)
                        : null,
                  ),
                  child: banner.imageUrl.isNotEmpty
                      ? Image.network(
                          banner.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Center(
                            child: Icon(
                              Iconsax.image,
                              size: 48,
                              color: Colors.white54,
                            ),
                          ),
                        )
                      : const Center(
                          child: Icon(
                            Iconsax.image,
                            size: 48,
                            color: Colors.white54,
                          ),
                        ),
                ),
                // Status Badge
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: banner.isActive
                          ? const Color(0xFF2ED573)
                          : Colors.grey,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          banner.isActive
                              ? Iconsax.tick_circle
                              : Iconsax.close_circle,
                          color: Colors.white,
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          banner.isActive ? 'Active' : 'Inactive',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Banner Info
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  banner.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (banner.subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    banner.subtitle!,
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (banner.buttonText != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Button: ${banner.buttonText}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF2ED573),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    const Spacer(),
                    Text(
                      'Order: ${banner.order}',
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
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
                              builder: (_) => EditBannerScreen(banner: banner),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildActionButton(
                        icon: banner.isActive ? Iconsax.eye_slash : Iconsax.eye,
                        label: banner.isActive ? 'Deactivate' : 'Activate',
                        color: banner.isActive
                            ? Colors.orange
                            : const Color(0xFF2ED573),
                        onTap: () {
                          HapticFeedback.lightImpact();
                          context.read<AdminBannerBloc>().add(
                            ToggleBannerStatusEvent(id: banner.id),
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
                        onTap: () => _showDeleteConfirmation(banner.id),
                      ),
                    ),
                  ],
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
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3)),
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

  void _showDeleteConfirmation(String bannerId) {
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
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Iconsax.trash, color: Colors.red, size: 20),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Delete Banner',
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
          'Are you sure you want to delete this banner? This action cannot be undone.',
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
              context.read<AdminBannerBloc>().add(
                DeleteBannerEvent(id: bannerId),
              );
            },
            style: TextButton.styleFrom(
              backgroundColor: Colors.red.withOpacity(0.1),
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

  Color _hexToColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) {
      hex = 'FF$hex';
    }
    return Color(int.parse(hex, radix: 16));
  }
}
