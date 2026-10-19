import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zecorner/core/cubit/auth_cubit.dart';
import 'package:zecorner/infrastructure/seminar/seminar_repository.dart';
import 'package:zecorner/models/seminar/seminar_model.dart';
import 'package:zecorner/presentation/screens/seminar/widgets/seminar_event_card.dart';
import 'package:zecorner/presentation/widgets/admin-panel/admin_panel_appbar.dart';
import 'package:zecorner/presentation/widgets/role-sidebar/role_sidebar.dart';
import 'package:zecorner/router/app_router.dart';

class SeminarDetailScreen extends StatefulWidget {
  const SeminarDetailScreen({Key? key}) : super(key: key);

  @override
  State<SeminarDetailScreen> createState() => _SeminarDetailScreenState();
}

class _SeminarDetailScreenState extends State<SeminarDetailScreen> {
  final SeminarRepository _repository = SeminarRepository();
  Seminar? _seminar;
  bool _isLoading = false;
  bool _didInit = false;
  bool _canManage = false;
  String? _errorMessage;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInit) return;
    _didInit = true;
    _canManage = context.read<AuthCubit>().isAdmin;
    _loadAccess();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Seminar) {
      _seminar = args;
      _refreshFromApi(args.id);
      return;
    }
    if (args is Map) {
      final seminar = args['seminar'];
      final id = args['id'];
      if (seminar is Seminar) {
        _seminar = seminar;
        _refreshFromApi(seminar.id);
        return;
      }
      if (id is int) {
        _isLoading = true;
        _loadById(id);
        return;
      }
    }
    _errorMessage = 'Seminer bilgisi bulunamadı.';
  }

  Future<void> _loadAccess() async {
    final prefs = await SharedPreferences.getInstance();
    final roles = prefs.getStringList('userRoleCodes') ?? [];
    final permissions = (prefs.getString('userPermissions') ?? '')
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty);
    final isAdmin = prefs.getBool('userIsAdmin') == true ||
        roles.contains('role_admin') ||
        (mounted && context.read<AuthCubit>().isAdmin);
    if (!mounted) return;
    setState(() {
      _canManage = RoleSidebar.allows(
        'admin_only',
        isAdmin: isAdmin,
        roleCodes: roles,
        permissions: permissions,
      );
    });
  }

  Future<void> _refreshFromApi(int id) async {
    final result = await _repository.getSeminarById(id);
    if (!mounted) return;
    result.fold((_) {}, (seminar) {
      setState(() => _seminar = seminar);
    });
  }

  Future<void> _loadById(int id) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    final result = await _repository.getSeminarById(id);
    if (!mounted) return;
    result.fold(
      (failure) {
        setState(() {
          _isLoading = false;
          _errorMessage = failure.message;
        });
      },
      (seminar) {
        setState(() {
          _seminar = seminar;
          _isLoading = false;
        });
      },
    );
  }

  void _showApplyFeedback(Seminar seminar) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF111827),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Text('${seminar.title} başvurusu için kayıt adımı hazırlanıyor.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final seminar = _seminar;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AdminPanelAppBar(
        title: seminar?.title ?? 'Seminer Detay',
        useBackButton: true,
        onMenuPressed: () => Navigator.pop(context),
        actions: [
          if (seminar != null && _canManage)
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: Colors.white),
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  AppRouter.editSeminar,
                  arguments: seminar,
                );
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFE53935)),
            )
          : seminar == null
              ? _DetailError(
                  message: _errorMessage ?? 'Seminer yüklenemedi.',
                  onRetry: () => Navigator.pop(context),
                )
              : Column(
                  children: [
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                        children: [
                          SeminarEventCard(
                            seminar: seminar,
                            showTypeBadge: seminar.type != null,
                            showInstructors: true,
                            logoStyle: seminar.isEducation,
                            showCta: _canManage,
                            onCtaPressed: _canManage && seminar.canApply
                                ? () => _showApplyFeedback(seminar)
                                : null,
                          ),
                          if (seminar.directions.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            _InfoSection(
                              title: 'Yol tarifi',
                              child: Text(
                                seminar.directions,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF4B5563),
                                  height: 1.45,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final String title;
  final Widget child;

  const _InfoSection({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _DetailError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _DetailError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, size: 48, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE53935),
                foregroundColor: Colors.white,
              ),
              child: const Text('Geri dön'),
            ),
          ],
        ),
      ),
    );
  }
}
