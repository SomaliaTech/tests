// lib/features/admin/presentation/screens/chat/super_admin_list_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mobile/core/services/injection_container.dart';
import 'package:mobile/features/admin/presentation/screens/chat/super_admin_chat_screen.dart';
import 'package:mobile/features/chat/data/datasources/chat_remote_datasource.dart';
import 'dart:async';

class SuperAdminListScreen extends StatefulWidget {
  const SuperAdminListScreen({super.key});

  @override
  State<SuperAdminListScreen> createState() => _SuperAdminListScreenState();
}

class _SuperAdminListScreenState extends State<SuperAdminListScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  List<Map<String, dynamic>> _admins = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAdmins();
  }

  Future<void> _loadAdmins({String? search}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final dataSource = sl<ChatRemoteDataSource>();
      final admins = await dataSource.getAvailableAdmins();
      if (mounted) {
        setState(() {
          _admins = admins.map((a) => Map<String, dynamic>.from(a)).toList();
          if (search != null && search.isNotEmpty) {
            _admins = _admins
                .where(
                  (a) =>
                      (a['name']?.toString() ?? '').toLowerCase().contains(
                        search.toLowerCase(),
                      ) ||
                      (a['phoneNumber']?.toString() ?? '').contains(search),
                )
                .toList();
          }
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
      _loadAdmins(search: query.trim());
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
        title: const Text(
          'Admins',
          style: TextStyle(
            color: Color(0xFF111111),
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left, color: Color(0xFF111111)),
          onPressed: () => Navigator.pop(context),
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
                hintText: 'Search admins...',
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
                : _admins.isEmpty
                ? const Center(child: Text('No admins found'))
                : ListView.builder(
                    itemCount: _admins.length,
                    itemBuilder: (context, index) {
                      final admin = _admins[index];
                      return _AdminCard(
                        admin: admin,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SuperAdminUsersScreen(
                                adminId: admin['id']?.toString() ?? '',
                                adminName: admin['name']?.toString() ?? 'Admin',
                                adminImage: admin['profileImage']?.toString(),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _AdminCard extends StatelessWidget {
  final Map<String, dynamic> admin;
  final VoidCallback onTap;

  const _AdminCard({required this.admin, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final name = admin['name']?.toString() ?? 'Unknown';
    final phone = admin['phoneNumber']?.toString() ?? '';
    final isOnline = admin['isOnline'] == true;
    final image = admin['profileImage']?.toString();

    return ListTile(
      onTap: onTap,
      leading: Stack(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFF2ED573).withValues(alpha: 0.2),
            backgroundImage: image != null && image.isNotEmpty
                ? NetworkImage(image)
                : null,
            child: image == null || image.isEmpty
                ? Text(
                    name[0].toUpperCase(),
                    style: const TextStyle(
                      color: Color(0xFF2ED573),
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          if (isOnline)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
        ],
      ),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(
        phone.isNotEmpty ? phone : 'No phone',
        style: const TextStyle(color: Colors.grey),
      ),
      trailing: const Icon(Iconsax.arrow_right_3, color: Colors.grey),
    );
  }
}
