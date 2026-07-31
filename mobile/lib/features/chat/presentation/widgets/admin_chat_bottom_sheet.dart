// lib/features/chat/presentation/widgets/admin_chat_bottom_sheet.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mobile/core/services/injection_container.dart';
import 'package:mobile/core/services/chat_socket_service.dart';
import 'package:mobile/features/chat/domain/entities/chat_user.dart';
import 'package:mobile/features/chat/domain/usecases/get_admin_users.dart';
import 'package:mobile/features/chat/presentation/screens/chat_room_screen.dart';
import 'package:mobile/features/chat/presentation/screens/conversations_screen.dart';

class AdminChatBottomSheet extends StatefulWidget {
  const AdminChatBottomSheet({super.key});

  @override
  State<AdminChatBottomSheet> createState() => _AdminChatBottomSheetState();
}

class _AdminChatBottomSheetState extends State<AdminChatBottomSheet> {
  List<ChatUser> _admins = [];
  List<ChatUser> _filteredAdmins = [];
  bool _isLoading = true;
  StreamSubscription? _statusSub;
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadAdmins();
    _setupStatusListener();
  }

  @override
  void dispose() {
    _statusSub?.cancel();
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  /// ✅ Listen for real-time status changes from WebSocket
  void _setupStatusListener() {
    final socketService = sl<ChatSocketService>();
    _statusSub = socketService.onStatusChange.listen((data) {
      if (!mounted) return;

      final userId = data['userId'] as String?;
      final isOnline = data['isOnline'] as bool? ?? false;

      if (userId == null) return;

      // Update the admin's online status in the list
      setState(() {
        for (int i = 0; i < _admins.length; i++) {
          if (_admins[i].id == userId) {
            _admins[i] = ChatUser(
              id: _admins[i].id,
              name: _admins[i].name,
              phoneNumber: _admins[i].phoneNumber,
              profileImage: _admins[i].profileImage,
              isOnline: isOnline,
              lastSeen: _admins[i].lastSeen,
              isAdmin: _admins[i].isAdmin,
              isSuperAdmin: _admins[i].isSuperAdmin,
            );
            break;
          }
        }
        // Also update filtered list
        _applyFilter(_searchController.text);
      });
    });
  }

  Future<void> _loadAdmins() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final result = await sl<GetAdminUsers>()();
      result.fold(
        (_) {
          if (mounted) setState(() => _isLoading = false);
        },
        (admins) {
          if (mounted) {
            // ✅ Sort: Regular admins first, then super admins
            final sortedAdmins = List<ChatUser>.from(admins);
            sortedAdmins.sort((a, b) {
              final aIsSuper = a.isSuperAdmin == true;
              final bIsSuper = b.isSuperAdmin == true;

              if (aIsSuper && !bIsSuper)
                return 1; // Super admin goes after regular
              if (!aIsSuper && bIsSuper)
                return -1; // Regular admin goes before super
              // Alphabetically sort within same type
              return (a.name ?? a.phoneNumber).compareTo(
                b.name ?? b.phoneNumber,
              );
            });

            setState(() {
              _admins = sortedAdmins;
              _applyFilter(_searchController.text);
              _isLoading = false;
            });
          }
        },
      );
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyFilter(String query) {
    if (query.isEmpty) {
      _filteredAdmins = List.from(_admins);
    } else {
      _filteredAdmins = _admins
          .where(
            (admin) =>
                (admin.name?.toLowerCase().contains(query.toLowerCase()) ??
                    false) ||
                (admin.phoneNumber?.contains(query) ?? false),
          )
          .toList();
    }
    setState(() {});
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _applyFilter(query);
    });
  }

  // ✅ FIXED: Capture navigator before closing bottom sheet
  void _onAdminTap(ChatUser admin) {
    // ✅ Save the navigator before popping
    final navigator = Navigator.of(context);

    // Close bottom sheet first
    navigator.pop();

    // ✅ Navigate to chat room after bottom sheet is closed
    // Use a microtask to ensure the pop is complete
    Future.microtask(() {
      if (!mounted) return;

      navigator
          .push(
            MaterialPageRoute(
              builder: (_) => ChatRoomScreen(
                partnerId: admin.id,
                partnerName: admin.name ?? admin.phoneNumber,
                partnerImage: admin.profileImage,
                isOnline: admin.isOnline,
              ),
            ),
          )
          .then((_) {
            // When user presses back from ChatRoom, navigate to ConversationsScreen
            if (!mounted) return;

            navigator.pushReplacement(
              MaterialPageRoute(builder: (_) => const ConversationsScreen()),
            );
          });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Title
          const Text(
            'Chat with Support',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Select an admin to chat with',
            style: TextStyle(fontSize: 13, color: Colors.grey[500]),
          ),
          const SizedBox(height: 12),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search Users...',
                prefixIcon: const Icon(
                  Iconsax.search_normal,
                  color: Colors.grey,
                  size: 20,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Iconsax.close_circle, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          _applyFilter('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFFF5F7FA),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Admin count summary
          if (!_isLoading && _admins.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _buildCountChip(
                    'Employee',
                    _admins.where((a) => a.isSuperAdmin != true).length,
                    const Color(0xFF2ED573),
                    Iconsax.user_tick,
                  ),
                  const SizedBox(width: 8),
                  _buildCountChip(
                    'Super',
                    _admins.where((a) => a.isSuperAdmin == true).length,
                    Colors.orange,
                    Iconsax.crown,
                  ),
                  const SizedBox(width: 8),
                  _buildCountChip(
                    'Online',
                    _admins.where((a) => a.isOnline).length,
                    Colors.blue,
                    Iconsax.status,
                  ),
                ],
              ),
            ),

          const SizedBox(height: 12),

          // Admins List
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF2ED573)),
                  )
                : _filteredAdmins.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _searchController.text.isNotEmpty
                              ? Iconsax.search_normal
                              : Iconsax.user,
                          size: 48,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _searchController.text.isNotEmpty
                              ? 'No admins match your search'
                              : 'No admins available',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredAdmins.length,
                    itemBuilder: (context, index) {
                      final admin = _filteredAdmins[index];
                      final isSuperAdmin = admin.isSuperAdmin == true;

                      // Show section header for super admins
                      final showSuperHeader =
                          isSuperAdmin &&
                          (index == 0 ||
                              _filteredAdmins[index - 1].isSuperAdmin != true);

                      return Column(
                        children: [
                          if (showSuperHeader) _buildSuperAdminHeader(),
                          _buildAdminTile(admin),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountChip(String label, int count, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            '$count',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 2),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuperAdminHeader() {
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: const Row(
        children: [
          Icon(Iconsax.crown, color: Colors.orange, size: 16),
          SizedBox(width: 8),
          Text(
            'Maamulaha Sare',
            style: TextStyle(
              color: Colors.orange,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminTile(ChatUser admin) {
    final isSuperAdmin = admin.isSuperAdmin == true;
    final isOnline = admin.isOnline;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSuperAdmin
              ? Colors.orange.withOpacity(0.3)
              : Colors.grey.withOpacity(0.1),
        ),
      ),
      child: InkWell(
        onTap: () => _onAdminTap(admin),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Avatar with status indicator
              Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSuperAdmin
                            ? Colors.orange
                            : const Color(0xFF2ED573),
                        width: 2,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 24,
                      backgroundColor: isSuperAdmin
                          ? Colors.orange.withOpacity(0.2)
                          : const Color(0xFF2ED573).withOpacity(0.1),
                      backgroundImage:
                          admin.profileImage != null &&
                              admin.profileImage!.isNotEmpty &&
                              !admin.profileImage!.contains('example.com')
                          ? CachedNetworkImageProvider(admin.profileImage!)
                          : null,
                      child:
                          admin.profileImage == null ||
                              admin.profileImage!.isEmpty ||
                              admin.profileImage!.contains('example.com')
                          ? Text(
                              (admin.name?.isNotEmpty == true
                                      ? admin.name![0]
                                      : admin.phoneNumber.isNotEmpty
                                      ? admin.phoneNumber[0]
                                      : 'A')
                                  .toUpperCase(),
                              style: TextStyle(
                                color: isSuperAdmin
                                    ? Colors.orange
                                    : const Color(0xFF2ED573),
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            )
                          : null,
                    ),
                  ),
                  // Online/Offline indicator
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: isOnline
                            ? const Color(0xFF2ED573)
                            : Colors.grey[400],
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: isOnline
                          ? const Icon(
                              Icons.check,
                              size: 8,
                              color: Colors.white,
                            )
                          : null,
                    ),
                  ),
                  // Super admin crown
                  if (isSuperAdmin)
                    Positioned(
                      top: -4,
                      right: -4,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1),
                        ),
                        child: const Icon(
                          Iconsax.crown,
                          color: Colors.white,
                          size: 12,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),

              // Admin Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            admin.name ?? admin.phoneNumber,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: Color(0xFF1F2937),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isSuperAdmin)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.orange.withOpacity(0.3),
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Iconsax.crown,
                                  color: Colors.orange,
                                  size: 12,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Maamule',
                                  style: TextStyle(
                                    color: Colors.orange,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2ED573).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFF2ED573).withOpacity(0.3),
                              ),
                            ),
                            child: const Text(
                              'Shaqale',
                              style: TextStyle(
                                color: Color(0xFF2ED573),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isOnline
                                ? const Color(0xFF2ED573)
                                : Colors.grey[400],
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isOnline ? 'Online' : 'Offline',
                          style: TextStyle(
                            fontSize: 12,
                            color: isOnline
                                ? const Color(0xFF2ED573)
                                : Colors.grey[500],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (!isOnline && admin.lastSeen != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            '• ${_formatLastSeen(admin.lastSeen!)}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[400],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Arrow
              Icon(Iconsax.arrow_right_3, color: Colors.grey[400], size: 20),
            ],
          ),
        ),
      ),
    );
  }

  String _formatLastSeen(DateTime lastSeen) {
    final now = DateTime.now();
    final difference = now.difference(lastSeen);

    if (difference.inMinutes < 1) return 'just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    return '${lastSeen.day}/${lastSeen.month}/${lastSeen.year}';
  }
}
