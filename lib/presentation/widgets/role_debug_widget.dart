import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zecorner/core/cubit/auth_cubit.dart';

class RoleDebugWidget extends StatelessWidget {
  const RoleDebugWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        if (state is! AuthAuthenticated) {
          return const SizedBox.shrink();
        }

        final authCubit = context.read<AuthCubit>();
        
        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '🔐 Role Debug Bilgileri',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              _buildInfoRow('Kullanıcı', authCubit.currentUser?.fullName ?? 'Bilinmiyor'),
              _buildInfoRow('Email', authCubit.currentUser?.email ?? 'Bilinmiyor'),
              _buildInfoRow('Role ID', authCubit.currentRole ?? 'Bilinmiyor'),
              _buildInfoRow('Role Yüklü', authCubit.isRoleLoaded ? '✅ Evet' : '❌ Hayır'),
              if (authCubit.isRoleLoaded) ...[
                _buildInfoRow('Role Adı', authCubit.currentRoleObject?.name ?? 'Bilinmiyor'),
                _buildInfoRow('Role Seviyesi', '${authCubit.currentRoleObject?.level ?? 0}'),
                _buildInfoRow('Admin', authCubit.isAdmin ? '✅ Evet' : '❌ Hayır'),
                _buildInfoRow('Manager', authCubit.isManager ? '✅ Evet' : '❌ Hayır'),
                _buildInfoRow('Agent', authCubit.isAgent ? '✅ Evet' : '❌ Hayır'),
                const SizedBox(height: 8),
                const Text(
                  '📋 İzinler:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                ...authCubit.getGrantedPermissions().take(5).map((permission) => 
                  Padding(
                    padding: const EdgeInsets.only(left: 8, bottom: 2),
                    child: Text('• $permission', style: const TextStyle(fontSize: 12)),
                  )
                ),
                if (authCubit.getGrantedPermissions().length > 5)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Text(
                      '... ve ${authCubit.getGrantedPermissions().length - 5} tane daha',
                      style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                    ),
                  ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
