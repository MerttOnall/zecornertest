import 'package:flutter/material.dart';
import 'package:zecorner/presentation/widgets/empty_data_view.dart';
import 'package:zecorner/presentation/widgets/status/status_hero.dart';
import 'package:zecorner/presentation/widgets/status/status_tokens.dart';
import 'package:zecorner/router/app_router.dart';

class AppStatusView extends StatefulWidget {
  const AppStatusView({
    super.key,
    required this.kind,
    this.code,
    this.label,
    this.title,
    this.message,
    this.icon,
    this.onRetry,
    this.onHome,
    this.retryLabel = 'Tekrar Dene',
    this.homeLabel = 'Ana Sayfaya Dön',
    this.showHomeButton = false,
    this.padding,
  });

  const AppStatusView.loading({
    super.key,
    this.title,
    this.message,
    this.label,
    this.padding,
  })  : kind = AppStatusKind.loading,
        code = null,
        icon = null,
        onRetry = null,
        onHome = null,
        retryLabel = 'Tekrar Dene',
        homeLabel = 'Ana Sayfaya Dön',
        showHomeButton = false;

  const AppStatusView.success({
    super.key,
    this.title,
    this.message,
    this.label,
    this.padding,
    this.onHome,
    this.homeLabel = 'Ana Sayfaya Dön',
    this.showHomeButton = false,
  })  : kind = AppStatusKind.success,
        code = null,
        icon = null,
        onRetry = null,
        retryLabel = 'Tekrar Dene';

  const AppStatusView.error({
    super.key,
    this.title,
    this.message,
    this.code,
    this.onRetry,
    this.onHome,
    this.retryLabel = 'Tekrar Dene',
    this.homeLabel = 'Ana Sayfaya Dön',
    this.showHomeButton = false,
    this.padding,
  })  : kind = AppStatusKind.error,
        label = null,
        icon = null;

  const AppStatusView.notFound({
    super.key,
    this.title,
    this.message,
    this.icon,
    this.onRetry,
    this.onHome,
    this.retryLabel = 'Tekrar Dene',
    this.homeLabel = 'Ana Sayfaya Dön',
    this.showHomeButton = true,
    this.padding,
  })  : kind = AppStatusKind.notFound,
        code = null,
        label = null;

  const AppStatusView.missing({
    super.key,
    this.title,
    this.message,
    this.icon,
    this.onRetry,
    this.onHome,
    this.retryLabel = 'Tekrar Dene',
    this.homeLabel = 'Ana Sayfaya Dön',
    this.showHomeButton = false,
    this.padding,
  })  : kind = AppStatusKind.missing,
        code = null,
        label = null;

  final AppStatusKind kind;
  final String? code;
  final String? label;
  final String? title;
  final String? message;
  final IconData? icon;
  final VoidCallback? onRetry;
  final VoidCallback? onHome;
  final String retryLabel;
  final String homeLabel;
  final bool showHomeButton;
  final EdgeInsetsGeometry? padding;

  @override
  State<AppStatusView> createState() => _AppStatusViewState();
}

class _AppStatusViewState extends State<AppStatusView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _enter;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _enter = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fade = CurvedAnimation(parent: _enter, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _enter, curve: Curves.easeOutCubic));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) {
        _enter.value = 1;
      } else {
        _enter.forward();
      }
    });
  }

  @override
  void dispose() {
    _enter.dispose();
    super.dispose();
  }

  String get _code {
    if (widget.code != null) return widget.code!;
    switch (widget.kind) {
      case AppStatusKind.error:
        return StatusTokens.errorCode;
      case AppStatusKind.notFound:
        return StatusTokens.notFoundCode;
      case AppStatusKind.missing:
        return StatusTokens.missingCode;
      default:
        return '';
    }
  }

  String get _label {
    if (widget.label != null) return widget.label!;
    switch (widget.kind) {
      case AppStatusKind.loading:
        return StatusTokens.loadingLabel;
      case AppStatusKind.success:
        return StatusTokens.successLabel;
      default:
        return '';
    }
  }

  String get _title {
    if (widget.title != null) return widget.title!;
    switch (widget.kind) {
      case AppStatusKind.loading:
        return StatusTokens.loadingTitle;
      case AppStatusKind.success:
        return StatusTokens.successTitle;
      case AppStatusKind.error:
        return StatusTokens.errorTitle;
      case AppStatusKind.notFound:
        return StatusTokens.notFoundTitle;
      case AppStatusKind.missing:
        return StatusTokens.missingTitle;
    }
  }

  String get _message {
    if (widget.message != null) return widget.message!;
    switch (widget.kind) {
      case AppStatusKind.loading:
        return StatusTokens.loadingMessage;
      case AppStatusKind.success:
        return StatusTokens.successMessage;
      case AppStatusKind.error:
        return StatusTokens.errorMessage;
      case AppStatusKind.notFound:
        return StatusTokens.notFoundMessage;
      case AppStatusKind.missing:
        return StatusTokens.missingMessage;
    }
  }

  bool get _isEmptyState =>
      widget.kind == AppStatusKind.missing ||
      widget.kind == AppStatusKind.notFound;

  bool get _isIllustratedError => widget.kind == AppStatusKind.error;

  IconData get _emptyIcon {
    if (widget.icon != null) return widget.icon!;
    if (widget.kind == AppStatusKind.notFound) {
      return Icons.search_off_rounded;
    }
    return Icons.inbox_rounded;
  }

  void _handleHome() {
    if (widget.onHome != null) {
      widget.onHome!();
      return;
    }
    final nav = Navigator.maybeOf(context);
    if (nav == null) return;
    nav.pushNamedAndRemoveUntil(AppRouter.homeListings, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxH = constraints.maxHeight;
        final compact = maxH.isFinite && maxH < 520;
        final heroSize = compact ? 168.0 : 236.0;
        final showMessage = !compact || widget.kind != AppStatusKind.loading;

        final content = Padding(
          padding: widget.padding ??
              EdgeInsets.symmetric(
                horizontal: 28,
                vertical: compact ? 12 : 20,
              ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isEmptyState)
                EmptyDataView(
                  title: _title,
                  subtitle: showMessage ? _message : null,
                  icon: _emptyIcon,
                  expanded: !compact,
                )
              else ...[
                StatusHero(kind: widget.kind, size: heroSize),
                SizedBox(height: compact ? 12 : 22),
                if (_isIllustratedError && _code.isNotEmpty)
                  _StatusCodeTag(code: _code),
                if (_label.isNotEmpty)
                  Text(
                    _label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: StatusTokens.red,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.8,
                    ),
                  ),
                const SizedBox(height: 10),
                Text(
                  _title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: StatusTokens.ink,
                    fontSize: compact ? 20 : 24,
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                  ),
                ),
                if (showMessage) ...[
                  const SizedBox(height: 10),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 340),
                    child: Text(
                      _message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: StatusTokens.muted,
                        fontSize: 14,
                        height: 1.55,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ],
              if (widget.onRetry != null ||
                  widget.showHomeButton ||
                  widget.onHome != null) ...[
                SizedBox(height: compact ? 22 : 28),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 320),
                  child: Column(
                    children: [
                      if (widget.onRetry != null)
                        _StatusActionButton(
                          label: widget.retryLabel,
                          filled: true,
                          onPressed: widget.onRetry!,
                        ),
                      if (widget.onRetry != null &&
                          (widget.showHomeButton || widget.onHome != null))
                        const SizedBox(height: 10),
                      if (widget.showHomeButton || widget.onHome != null)
                        _StatusActionButton(
                          label: widget.homeLabel,
                          filled: false,
                          onPressed: _handleHome,
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );

        Widget body = FadeTransition(
          opacity: _fade,
          child: SlideTransition(
            position: _slide,
            child: content,
          ),
        );

        if (maxH.isFinite) {
          body = SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: maxH),
              child: Center(child: body),
            ),
          );
        }

        return body;
      },
    );
  }
}

class _StatusCodeTag extends StatelessWidget {
  const _StatusCodeTag({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 22,
            height: 2,
            decoration: BoxDecoration(
              color: StatusTokens.red,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            code,
            style: const TextStyle(
              color: StatusTokens.red,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusActionButton extends StatelessWidget {
  const _StatusActionButton({
    required this.label,
    required this.filled,
    required this.onPressed,
  });

  final String label;
  final bool filled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(28),
    );
    if (filled) {
      return SizedBox(
        width: double.infinity,
        height: 52,
        child: FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: StatusTokens.red,
            foregroundColor: Colors.white,
            disabledBackgroundColor: StatusTokens.red.withValues(alpha: 0.5),
            elevation: 0,
            shape: shape,
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          child: Text(label),
        ),
      );
    }
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: StatusTokens.red,
          side: const BorderSide(color: StatusTokens.red, width: 1.4),
          shape: shape,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        child: Text(label),
      ),
    );
  }
}

class AppStatusPage extends StatelessWidget {
  const AppStatusPage({
    super.key,
    required this.kind,
    this.title,
    this.message,
    this.label,
    this.code,
    this.onRetry,
    this.onHome,
    this.retryLabel = 'Tekrar Dene',
    this.homeLabel = 'Ana Sayfaya Dön',
    this.showHomeButton = true,
    this.showAppBar = false,
  });

  const AppStatusPage.loading({
    super.key,
    this.title,
    this.message,
    this.label,
  })  : kind = AppStatusKind.loading,
        code = null,
        onRetry = null,
        onHome = null,
        retryLabel = 'Tekrar Dene',
        homeLabel = 'Ana Sayfaya Dön',
        showHomeButton = false,
        showAppBar = false;

  const AppStatusPage.error({
    super.key,
    this.title,
    this.message,
    this.code,
    this.onRetry,
    this.onHome,
    this.retryLabel = 'Tekrar Dene',
    this.homeLabel = 'Ana Sayfaya Dön',
    this.showHomeButton = true,
    this.showAppBar = false,
  })  : kind = AppStatusKind.error,
        label = null;

  const AppStatusPage.notFound({
    super.key,
    this.title,
    this.message,
    this.onRetry,
    this.onHome,
    this.retryLabel = 'Tekrar Dene',
    this.homeLabel = 'Ana Sayfaya Dön',
    this.showHomeButton = true,
    this.showAppBar = false,
  })  : kind = AppStatusKind.notFound,
        code = null,
        label = null;

  const AppStatusPage.missing({
    super.key,
    this.title,
    this.message,
    this.onRetry,
    this.onHome,
    this.retryLabel = 'Tekrar Dene',
    this.homeLabel = 'Ana Sayfaya Dön',
    this.showHomeButton = true,
    this.showAppBar = false,
  })  : kind = AppStatusKind.missing,
        code = null,
        label = null;

  final AppStatusKind kind;
  final String? title;
  final String? message;
  final String? label;
  final String? code;
  final VoidCallback? onRetry;
  final VoidCallback? onHome;
  final String retryLabel;
  final String homeLabel;
  final bool showHomeButton;
  final bool showAppBar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: StatusTokens.background,
      appBar: showAppBar
          ? AppBar(
              backgroundColor: StatusTokens.background,
              elevation: 0,
              foregroundColor: StatusTokens.ink,
            )
          : null,
      body: SafeArea(
        child: AppStatusView(
          kind: kind,
          title: title,
          message: message,
          label: label,
          code: code,
          onRetry: onRetry,
          onHome: onHome,
          retryLabel: retryLabel,
          homeLabel: homeLabel,
          showHomeButton: showHomeButton,
        ),
      ),
    );
  }
}

class AppFrameworkErrorView extends StatelessWidget {
  const AppFrameworkErrorView({super.key, this.details});

  final String? details;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: StatusTokens.background,
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final minH = constraints.maxHeight.isFinite
                ? constraints.maxHeight
                : 480.0;
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: minH),
                child: AppStatusView.error(
                  message: details == null || details!.isEmpty
                      ? StatusTokens.errorMessage
                      : details,
                  showHomeButton: true,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
