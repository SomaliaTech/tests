// lib/features/admin/presentation/screens/chat/super_admin_users_screen.dart
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mobile/core/services/injection_container.dart';
import 'package:mobile/features/admin/presentation/screens/chat/super_admin_chat_detail_screen.dart';
import 'package:mobile/features/chat/data/datasources/chat_remote_datasource.dart';
import 'dart:async';

class SuperAdminUsersScreen extends StatefulWidget {
  final String adminId;
  final String adminName;
  final String? adminImage;

  const SuperAdminUsersScreen({
    super.key,
    required this.adminId,
    required this.adminName,
    this.adminImage,
  });

  @override
  State<SuperAdminUsersScreen> createState() => _SuperAdminUsersScreenState();
}

class _SuperAdminUsersScreenState extends State<SuperAdminUsersScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  List<dynamic> _users = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers({String? search}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final dataSource = sl<ChatRemoteDataSource>();
      final users = await dataSource.getUsersForAdmin(
        widget.adminId,
        search: search,
      );
      if (mounted) {
        setState(() {
          _users = users;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted)
        setState(() {
          _error = e.toString();
          _loading = false;
        });
    }
  }

  void _onSearch(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _loadUsers(search: query.trim());
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
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
          icon: const Icon(Iconsax.arrow_left, color: Color(0xFF111111)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.adminName,
          style: const TextStyle(
            color: Color(0xFF111111),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearch,
              decoration: InputDecoration(
                hintText: 'Search users...',
                prefixIcon: const Icon(Iconsax.search_normal),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF2ED573)),
                  )
                : _error != null
                ? Center(
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  )
                : _users.isEmpty
                ? const Center(child: Text('No users found'))
                : ListView.builder(
                    itemCount: _users.length,
                    itemBuilder: (context, index) {
                      final user = _users[index] as Map<String, dynamic>;
                      return _UserCard(
                        user: user,
                        adminId: widget.adminId,
                        adminName: widget.adminName,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final Map<String, dynamic> user;
  final String adminId;
  final String adminName;

  const _UserCard({
    required this.user,
    required this.adminId,
    required this.adminName,
  });

  @override
  Widget build(BuildContext context) {
    final name = user['userName']?.toString() ?? 'Unknown';
    final lastMsg = user['lastMessage']?.toString() ?? 'No messages';
    final isOnline = user['isOnline'] == true;

    return ListTile(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SuperAdminChatDetailScreen(
              conversationId: user['conversationId']?.toString() ?? '',
              userName: name,
              adminName: adminName,
              userId: user['userId']?.toString() ?? '',
              adminId: adminId,
            ),
          ),
        );
      },
      leading: Stack(
        children: [
          CircleAvatar(
            backgroundColor: Colors.grey[200],
            child: Text(
              name[0].toUpperCase(),
              style: const TextStyle(
                color: Color(0xFF2ED573),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (isOnline)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
              ),
            ),
        ],
      ),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(lastMsg, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: const Icon(Iconsax.arrow_right_3, color: Colors.grey),
    );
  }
}
