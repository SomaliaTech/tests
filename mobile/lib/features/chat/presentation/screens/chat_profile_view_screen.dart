// lib/features/chat/presentation/screens/profile_view_screen.dart
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:get_it/get_it.dart';
import 'package:mobile/core/services/storage/storage_service.dart';
import 'package:mobile/features/chat/data/datasources/chat_remote_datasource.dart';
import 'package:mobile/core/services/injection_container.dart';

class ChatProfileViewScreen extends StatefulWidget {
  final String partnerId;
  final String partnerName;
  final String? partnerImage;
  final bool isOnline;
  final String? lastSeen;

  const ChatProfileViewScreen({
    super.key,
    required this.partnerId,
    required this.partnerName,
    this.partnerImage,
    this.isOnline = false,
    this.lastSeen,
  });

  @override
  State<ChatProfileViewScreen> createState() => _ChatProfileViewScreenState();
}

class _ChatProfileViewScreenState extends State<ChatProfileViewScreen> {
  final StorageService _storageService = GetIt.instance<StorageService>();
  bool _isMuted = false;
  bool _isLoading = true;

  // Dynamic shared media counts
  int _photoCount = 0;
  int _videoCount = 0;
  int _docCount = 0;
  bool _isLoadingMedia = true;

  @override
  void initState() {
    super.initState();
    _loadMuteStatus();
    _loadSharedMediaCounts();
  }

  Future<void> _loadMuteStatus() async {
    try {
      final isMuted = await _storageService.isChatMuted(widget.partnerId);
      if (mounted) {
        setState(() {
          _isMuted = isMuted;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading mute status: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadSharedMediaCounts() async {
    try {
      final chatDataSource = sl<ChatRemoteDataSource>();
      final messages = await chatDataSource.getMessages(widget.partnerId);

      int photos = 0;
      int videos = 0;
      int docs = 0;

      for (final message in messages) {
        if (message.type == 'image') {
          photos++;
        } else if (message.type == 'video') {
          videos++;
        } else if (message.type == 'document' || message.type == 'file') {
          docs++;
        }
      }

      if (mounted) {
        setState(() {
          _photoCount = photos;
          _videoCount = videos;
          _docCount = docs;
          _isLoadingMedia = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading shared media counts: $e');
      if (mounted) {
        setState(() {
          _isLoadingMedia = false;
        });
      }
    }
  }

  Future<void> _toggleMute(bool value) async {
    try {
      await _storageService.setChatMuted(widget.partnerId, value);
      if (mounted) {
        setState(() => _isMuted = value);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              value ? 'Notifications muted' : 'Notifications unmuted',
            ),
            backgroundColor: value ? Colors.orange : const Color(0xFF2ED573),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update notification settings'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _openFullScreenImage() {
    if (widget.partnerImage != null && widget.partnerImage!.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => _FullScreenProfileImage(
            imageUrl: widget.partnerImage!,
            heroTag: 'avatar_${widget.partnerId}',
            name: widget.partnerName,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: CustomScrollView(
        slivers: [
          // Modern Clean App Bar
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Iconsax.arrow_left, color: Colors.black87),
              onPressed: () => Navigator.pop(context),
            ),

            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: Colors.white,
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      // Avatar with online indicator - NOW CLICKABLE
                      GestureDetector(
                        onTap: _openFullScreenImage,
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            Hero(
                              tag: 'avatar_${widget.partnerId}',
                              child: _buildProfileAvatar(),
                            ),
                            if (widget.isOnline)
                              Container(
                                margin: const EdgeInsets.all(8),
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2ED573),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 3,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF2ED573,
                                      ).withOpacity(0.4),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        widget.partnerName,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Modern Status Pill
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: widget.isOnline
                              ? const Color(0xFF2ED573).withOpacity(0.1)
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          widget.isOnline ? 'Online' : _formatLastSeen(),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: widget.isOnline
                                ? const Color(0xFF2ED573)
                                : Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // About Card
                  _buildModernCard(
                    children: [
                      _buildModernInfoTile(
                        icon: Iconsax.call,
                        title: 'Phone',
                        subtitle: '+255 123 456 789',
                      ),
                      Divider(
                        height: 1,
                        indent: 56,
                        color: Colors.grey.shade100,
                      ),
                      _buildModernInfoTile(
                        icon: Iconsax.user,
                        title: 'Username',
                        subtitle:
                            '@${widget.partnerName.toLowerCase().replaceAll(' ', '_')}',
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Shared Media Section with DYNAMIC counts
                  const Text(
                    'Shared Media',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),

                  const SizedBox(height: 24),

                  // Settings Card
                  _buildModernCard(
                    children: [
                      _buildModernActionTile(
                        icon: Iconsax.star,
                        title: 'Starred Messages',
                        iconColor: Colors.amber,
                        onTap: () {},
                      ),
                      Divider(
                        height: 1,
                        indent: 56,
                        color: Colors.grey.shade100,
                      ),
                      _buildModernActionTile(
                        icon: _isMuted
                            ? Iconsax.notification_status
                            : Iconsax.notification,
                        title: 'Mute Notifications',
                        iconColor: _isMuted
                            ? Colors.orange
                            : Colors.grey.shade600,
                        trailing: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Switch(
                                value: _isMuted,
                                onChanged: _toggleMute,
                                activeColor: const Color(0xFF2ED573),
                              ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Security Card
                  _buildModernCard(
                    children: [
                      _buildModernActionTile(
                        icon: Iconsax.lock,
                        title: 'Encryption',
                        subtitle: 'End-to-end encrypted',
                        iconColor: Colors.grey.shade600,
                        onTap: () {},
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Message Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Iconsax.message, size: 20),
                      label: const Text(
                        'Message',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2ED573),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 8,
                        shadowColor: const Color(0xFF2ED573).withOpacity(0.4),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Report Card
                  _buildModernCard(
                    color: Colors.red.shade50,
                    children: [
                      _buildModernActionTile(
                        icon: Iconsax.warning_2,
                        title: 'Report ${widget.partnerName.split(' ')[0]}',
                        iconColor: Colors.red,
                        onTap: () => _showReportDialog(context),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // AVATAR WITH GRADIENT FALLBACK
  // ==========================================
  Widget _buildProfileAvatar() {
    final hasImage =
        widget.partnerImage != null && widget.partnerImage!.isNotEmpty;

    final fallbackWidget = Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF2ED573),
            const Color(0xFF2ED573).withOpacity(0.7),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2ED573).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Center(
        child: Text(
          widget.partnerName.isNotEmpty
              ? widget.partnerName[0].toUpperCase()
              : '?',
          style: const TextStyle(
            fontSize: 56,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );

    if (!hasImage) return fallbackWidget;

    return CachedNetworkImage(
      imageUrl: widget.partnerImage!,
      imageBuilder: (context, imageProvider) => Container(
        width: 140,
        height: 140,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          image: DecorationImage(image: imageProvider, fit: BoxFit.cover),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
      ),
      placeholder: (context, url) => Container(
        width: 140,
        height: 140,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.grey.shade200,
        ),
        child: const Center(
          child: SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: Color(0xFF2ED573),
            ),
          ),
        ),
      ),
      errorWidget: (context, url, error) {
        debugPrint('❌ Failed to load profile avatar: $url');
        return fallbackWidget;
      },
    );
  }

  // ==========================================
  // MODERN UI HELPERS
  // ==========================================

  Widget _buildModernCard({required List<Widget> children, Color? color}) {
    return Container(
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildModernInfoTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.grey.shade700, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernActionTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Color? iconColor,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (iconColor ?? Colors.grey.shade600).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: iconColor ?? Colors.grey.shade700,
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            trailing ??
                const Icon(Iconsax.arrow_right_3, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }

  void _showReportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Report ${widget.partnerName.split(' ')[0]}?'),
        content: const Text(
          'The last 5 messages from this contact will be forwarded to our team for review.',
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${widget.partnerName.split(' ')[0]} reported'),
                  backgroundColor: Colors.orange,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Report', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String _formatLastSeen() {
    if (widget.lastSeen == null) return 'Offline';
    return 'Last seen ${widget.lastSeen}';
  }
}

// ==========================================
// FULL SCREEN PROFILE IMAGE VIEWER
// ==========================================
class _FullScreenProfileImage extends StatelessWidget {
  final String imageUrl;
  final String heroTag;
  final String name;

  const _FullScreenProfileImage({
    required this.imageUrl,
    required this.heroTag,
    required this.name,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(name, style: const TextStyle(color: Colors.white)),
      ),
      body: Center(
        child: Hero(
          tag: heroTag,
          child: InteractiveViewer(
            minScale: 0.5,
            maxScale: 4.0,
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.contain,
              width: double.infinity,
              placeholder: (context, url) => const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
              errorWidget: (context, url, error) {
                // Fallback to initial letter if image fails
                return Center(
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF2ED573),
                          const Color(0xFF2ED573).withOpacity(0.7),
                        ],
                      ),
                    ),
                    child: Center(
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: const TextStyle(
                          fontSize: 80,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
