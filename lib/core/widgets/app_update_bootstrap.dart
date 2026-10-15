import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zecorner/core/services/app_update_service.dart';
import 'package:zecorner/presentation/widgets/status/app_status_view.dart';
import 'package:zecorner/presentation/widgets/status/status_tokens.dart';

/// Mağazada daha yeni sürüm varsa uygulamayı kilitler; indirmeden devam edilemez.
class AppUpdateBootstrap extends StatefulWidget {
  const AppUpdateBootstrap({super.key, required this.child});

  final Widget child;

  @override
  State<AppUpdateBootstrap> createState() => _AppUpdateBootstrapState();
}

class _AppUpdateBootstrapState extends State<AppUpdateBootstrap>
    with WidgetsBindingObserver {
  AppUpdateInfo? _update;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _check();
    }
  }

  Future<void> _check() async {
    if (_checking) return;
    _checking = true;
    try {
      final update = await AppUpdateService.instance.checkForRequiredUpdate();
      if (!mounted) return;
      setState(() => _update = update);
    } finally {
      _checking = false;
    }
  }

  Future<void> _openStore() async {
    final url = _update?.storeUrl;
    if (url == null || url.isEmpty) return;
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final update = _update;
    if (update == null) return widget.child;

    return PopScope(
      canPop: false,
      child: Stack(
        fit: StackFit.expand,
        children: [
          widget.child,
          const ModalBarrier(dismissible: false, color: Colors.white),
          Material(
            color: StatusTokens.background,
            child: SafeArea(
              child: AppStatusView(
                kind: AppStatusKind.missing,
                code: 'GÜNCELLEME',
                title: 'Yeni sürüm zorunlu',
                message:
                    'Uygulamayı kullanmaya devam etmek için ${update.storeVersion} sürümünü indirmeniz gerekiyor. '
                    'Yüklü sürüm: ${update.currentVersion}.',
                retryLabel: update.storeLabel,
                onRetry: _openStore,
                showHomeButton: false,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
