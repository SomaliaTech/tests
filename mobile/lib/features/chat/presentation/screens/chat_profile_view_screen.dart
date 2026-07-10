// lib/features/chat/presentation/screens/profile_view_screen.dart
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:get_it/get_it.dart';
import 'package:mobile/core/services/storage/storage_service.dart';
import 'package:mobile/features/chat/data/datasources/chat_remote_datasource.dart';
import 'package:mobile/core/services/injection_container.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:mobile/core/constants/api_constants.dart';

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

  // ✅ Dynamic user info
  String _phoneNumber = '';
  String _username = '';
  String _displayName = '';
  String _profileImage = '';
  bool _isLoadingUserInfo = true;

  // Dynamic shared media counts
  int _photoCount = 0;
  int _videoCount = 0;
  int _docCount = 0;
  bool _isLoadingMedia = true;

  @override
  void initState() {
    super.initState();
    _displayName = widget.partnerName;
    _profileImage = widget.partnerImage ?? '';
    _loadMuteStatus();
    _loadUserInfo();
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

  /// ✅ Fetch user info from API
  Future<void> _loadUserInfo() async {
    try {
      final storageService = GetIt.instance<StorageService>();
      final token = await storageService.getAuthToken();

      if (token == null) {
        _setDefaultUserInfo();
        return;
      }

      // Try the status endpoint first
      final response = await http.get(
        Uri.parse(
          '${ApiConstants.baseUrl}/chat/users/${widget.partnerId}/status',
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (mounted) {
          setState(() {
            _phoneNumber = data['phoneNumber'] as String? ?? '';
            _displayName =
                data['name'] as String? ??
                data['fullName'] as String? ??
                widget.partnerName;
            _profileImage =
                data['profileImage'] as String? ?? widget.partnerImage ?? '';
            _username = _generateUsername(_displayName);
            _isLoadingUserInfo = false;
          });
        }
      } else {
        // Try user search endpoint as fallback
        await _loadUserInfoFromSearch(token);
      }
    } catch (e) {
      debugPrint('❌ Error loading user info: $e');
      await _loadUserInfoFromFallback();
    }
  }

  /// ✅ Fallback: Try user search endpoint
  Future<void> _loadUserInfoFromSearch(String token) async {
    try {
      final response = await http.get(
        Uri.parse(
          '${ApiConstants.baseUrl}/chat/users/chat-search?q=${Uri.encodeComponent(widget.partnerName)}&limit=1',
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final users = data is List
            ? data
            : (data['users'] as List? ?? data['data'] as List? ?? []);

        if (users.isNotEmpty) {
          final user = users.first as Map<String, dynamic>;
          if (mounted) {
            setState(() {
              _phoneNumber = user['phoneNumber'] as String? ?? '';
              _displayName =
                  user['name'] as String? ??
                  user['fullName'] as String? ??
                  widget.partnerName;
              _profileImage =
                  user['profileImage'] as String? ?? widget.partnerImage ?? '';
              _username = _generateUsername(_displayName);
              _isLoadingUserInfo = false;
            });
          }
          return;
        }
      }
      _setDefaultUserInfo();
    } catch (e) {
      debugPrint('❌ Error loading user info from search: $e');
      _setDefaultUserInfo();
    }
  }

  /// ✅ Try auth/me endpoint or conversations endpoint
  Future<void> _loadUserInfoFromFallback() async {
    try {
      final storageService = GetIt.instance<StorageService>();
      final token = await storageService.getAuthToken();
      if (token == null) {
        _setDefaultUserInfo();
        return;
      }

      // Try conversations endpoint which might have user info
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/chat/conversations'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final conversations = data is List
            ? data
            : (data['data'] as List? ?? []);

        for (final conv in conversations) {
          final participants = conv['participants'] as List? ?? [];
          for (final participant in participants) {
            if (participant['id'] == widget.partnerId) {
              if (mounted) {
                setState(() {
                  _phoneNumber = participant['phoneNumber'] as String? ?? '';
                  _displayName =
                      participant['name'] as String? ??
                      participant['fullName'] as String? ??
                      widget.partnerName;
                  _profileImage =
                      participant['profileImage'] as String? ??
                      widget.partnerImage ??
                      '';
                  _username = _generateUsername(_displayName);
                  _isLoadingUserInfo = false;
                });
              }
              return;
            }
          }
        }
      }
      _setDefaultUserInfo();
    } catch (e) {
      debugPrint('❌ Error loading user info from conversations: $e');
      _setDefaultUserInfo();
    }
  }

  void _setDefaultUserInfo() {
    if (mounted) {
      setState(() {
        _phoneNumber = '';
        _displayName = widget.partnerName;
        _profileImage = widget.partnerImage ?? '';
        _username = _generateUsername(widget.partnerName);
        _isLoadingUserInfo = false;
      });
    }
  }

  String _generateUsername(String name) {
    if (name.isEmpty) return 'user';
    return '@${name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]'), '_').replaceAll(RegExp(r'_+'), '_')}';
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
    final imageToShow = _profileImage.isNotEmpty
        ? _profileImage
        : widget.partnerImage;
    if (imageToShow != null && imageToShow.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => _FullScreenProfileImage(
            imageUrl: imageToShow,
            heroTag: 'avatar_${widget.partnerId}',
            name: _displayName,
          ),
        ),
      );
    }
  }

  /// ✅ Format phone number for display
  String _formatPhoneNumber(String phone) {
    if (phone.isEmpty) return 'No phone number';
    // Format: +252 61 532 8654 or similar
    if (phone.startsWith('+')) {
      final cleaned = phone.substring(1);
      if (cleaned.length >= 9) {
        return '+${cleaned.substring(0, 3)} ${cleaned.substring(3, 5)} ${cleaned.substring(5, 8)} ${cleaned.substring(8)}';
      }
    }
    return phone;
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
                        _displayName,
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
                        subtitle: _isLoadingUserInfo
                            ? 'Loading...'
                            : _phoneNumber.isNotEmpty
                            ? _formatPhoneNumber(_phoneNumber)
                            : 'No phone number',
                      ),
                      Divider(
                        height: 1,
                        indent: 56,
                        color: Colors.grey.shade100,
                      ),
                      _buildModernInfoTile(
                        icon: Iconsax.user,
                        title: 'Username',
                        subtitle: _isLoadingUserInfo ? 'Loading...' : _username,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Shared Media Section with DYNAMIC counts

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
                        title: 'Report ${_displayName.split(' ').first}',
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
  // SHARED MEDIA GRID
  // ==========================================

  Widget _buildMediaCountItem({
    required IconData icon,
    required int count,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          count.toString(),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  // ==========================================
  // AVATAR WITH GRADIENT FALLBACK
  // ==========================================
  Widget _buildProfileAvatar() {
    final imageToShow = _profileImage.isNotEmpty
        ? _profileImage
        : widget.partnerImage;
    final hasImage = imageToShow != null && imageToShow.isNotEmpty;

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
          _displayName.isNotEmpty ? _displayName[0].toUpperCase() : '?',
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
      imageUrl: imageToShow!,
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
        title: Text('Report ${_displayName.split(' ').first}?'),
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
                  content: Text('${_displayName.split(' ').first} reported'),
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
