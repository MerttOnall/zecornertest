import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zecorner/core/cubit/auth_cubit.dart';
import 'package:zecorner/presentation/widgets/role_debug_widget.dart';

class RoleTestScreen extends StatelessWidget {
  const RoleTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Role Sistemi Test'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          if (state is! AuthAuthenticated) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Giriş yapmanız gerekiyor',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final authCubit = context.read<AuthCubit>();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Role Debug Widget
                const RoleDebugWidget(),
                
                const SizedBox(height: 24),
                
                // Role Kontrolleri
                const Text(
                  '🔍 Role Kontrolleri',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                
                _buildRoleCard(
                  'Admin Kontrolü',
                  authCubit.isAdmin,
                  'Kullanıcı admin yetkisine sahip mi?',
                  Icons.admin_panel_settings,
                ),
                
                _buildRoleCard(
                  'Manager Kontrolü',
                  authCubit.isManager,
                  'Kullanıcı manager yetkisine sahip mi?',
                  Icons.manage_accounts,
                ),
                
                _buildRoleCard(
                  'Agent Kontrolü',
                  authCubit.isAgent,
                  'Kullanıcı agent yetkisine sahip mi?',
                  Icons.person,
                ),
                
                const SizedBox(height: 24),
                
                // İzin Testleri
                const Text(
                  '📋 İzin Testleri',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                
                _buildPermissionCard(
                  'Kullanıcı Yönetimi',
                  'users',
                  authCubit,
                ),
                
                _buildPermissionCard(
                  'İlan Yönetimi',
                  'listings',
                  authCubit,
                ),
                
                _buildPermissionCard(
                  'Ofis Yönetimi',
                  'offices',
                  authCubit,
                ),
                
                _buildPermissionCard(
                  'Müşteri Yönetimi',
                  'customers',
                  authCubit,
                ),
                
                const SizedBox(height: 24),
                
                // Test Butonları
                const Text(
                  '🧪 Test Butonları',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                
                ElevatedButton.icon(
                  onPressed: () {
                    _showPermissionsDialog(context, authCubit);
                  },
                  icon: const Icon(Icons.list),
                  label: const Text('Tüm İzinleri Göster'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                ElevatedButton.icon(
                  onPressed: () {
                    _showRoleInfoDialog(context, authCubit);
                  },
                  icon: const Icon(Icons.info),
                  label: const Text('Role Bilgilerini Göster'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                ElevatedButton.icon(
                  onPressed: () {
                    authCubit.signOut();
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Çıkış Yap'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRoleCard(String title, bool hasRole, String description, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(
          icon,
          color: hasRole ? Colors.green : Colors.grey,
        ),
        title: Text(title),
        subtitle: Text(description),
        trailing: Icon(
          hasRole ? Icons.check_circle : Icons.cancel,
          color: hasRole ? Colors.green : Colors.red,
        ),
      ),
    );
  }

  Widget _buildPermissionCard(String title, String resource, AuthCubit authCubit) {
    final canRead = authCubit.hasPermission(resource, 'read');
    final canCreate = authCubit.hasPermission(resource, 'create');
    final canUpdate = authCubit.hasPermission(resource, 'update');
    final canDelete = authCubit.hasPermission(resource, 'delete');
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildPermissionChip('Okuma', canRead),
                const SizedBox(width: 8),
                _buildPermissionChip('Oluşturma', canCreate),
                const SizedBox(width: 8),
                _buildPermissionChip('Güncelleme', canUpdate),
                const SizedBox(width: 8),
                _buildPermissionChip('Silme', canDelete),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionChip(String label, bool hasPermission) {
    return Chip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: hasPermission ? Colors.white : Colors.grey[600],
        ),
      ),
      backgroundColor: hasPermission ? Colors.green : Colors.grey[300],
    );
  }

  void _showPermissionsDialog(BuildContext context, AuthCubit authCubit) {
    final permissions = authCubit.getGrantedPermissions();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tüm İzinler'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: permissions.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(permissions[index]),
                leading: const Icon(Icons.check_circle, color: Colors.green),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  void _showRoleInfoDialog(BuildContext context, AuthCubit authCubit) {
    final role = authCubit.currentRoleObject;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Role Bilgileri'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Role ID: ${authCubit.currentRole}'),
            Text('Role Adı: ${role?.name ?? 'Bilinmiyor'}'),
            Text('Role Seviyesi: ${role?.level ?? 0}'),
            Text('Açıklama: ${role?.description ?? 'Açıklama yok'}'),
            const SizedBox(height: 8),
            Text('İzin Sayısı: ${role?.permissions.length ?? 0}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }
}
