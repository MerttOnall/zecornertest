import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';
import 'package:video_player/video_player.dart';
import 'package:zecorner/core/config/env_api.dart';
import 'package:zecorner/presentation/widgets/admin-panel/admin_panel_appbar.dart';
import 'package:zecorner/presentation/widgets/animated_background_widget.dart';
import 'package:zecorner/presentation/widgets/navbar/admin_navbar.dart';
import 'package:zecorner/presentation/widgets/role-sidebar/role_sidebar.dart';

class StudyScreen extends StatefulWidget {
  const StudyScreen({super.key});

  @override
  State<StudyScreen> createState() => _StudyScreenState();
}

class _StudyScreenState extends State<StudyScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isDrawerOpen = false;
  bool _isLoadingVideos = true;
  String? _videosError;

  List<_TrainingVideoItem> _videos = [];

  @override
  void initState() {
    super.initState();
    _loadVideos();
  }

  Future<void> _loadVideos() async {
    final candidates = _videoListCandidates();
    if (candidates.isEmpty) {
      setState(() {
        _videosError = 'Video endpoint tanimli degil. .env kontrol edin.';
        _isLoadingVideos = false;
      });
      return;
    }

    setState(() {
      _isLoadingVideos = true;
      _videosError = null;
    });

    Object? lastError;
    var sawAnyNon404Response = false;
    for (final listUrl in candidates) {
      try {
        debugPrint('🎬 Training videos request => $listUrl');
        final response = await Dio().get(
          listUrl,
          options: Options(
            headers: const {'Accept': 'application/json'},
            validateStatus: (code) => code != null && code >= 200 && code < 500,
          ),
        );
        debugPrint('🎬 Training videos status => ${response.statusCode}');
        final dataForLog = response.data;
        if (dataForLog is String && dataForLog.length > 240) {
          debugPrint(
            '🎬 Training videos data => ${dataForLog.substring(0, 240)}… (truncated)',
          );
        } else {
          debugPrint('🎬 Training videos data => $dataForLog');
        }

        final code = response.statusCode;
        if (code == 404) {
          debugPrint('⚠️ 404 — bu hostta bu API route yok: $listUrl');
          continue;
        }
        sawAnyNon404Response = true;

        if (code == null || code < 200 || code >= 300) {
          throw Exception('HTTP $code');
        }

        final data = response.data;
        dynamic listRaw;
        if (data is Map<String, dynamic>) {
          listRaw = data['videos'] ??
              (data['data'] is Map<String, dynamic>
                  ? data['data']['videos']
                  : null);
        }
        if (listRaw is! List) {
          throw Exception('Beklenmeyen response formati: videos[] yok');
        }

        final parsed = listRaw
            .whereType<Map>()
            .map((raw) => Map<String, dynamic>.from(raw))
            .map(_TrainingVideoItem.fromApi)
            .where((item) => item.videoUrl.isNotEmpty)
            .toList();

        if (!mounted) return;
        setState(() {
          _videos = parsed;
          _isLoadingVideos = false;
        });
        return;
      } catch (e) {
        lastError = e;
        debugPrint('❌ Training videos failed for $listUrl => $e');
      }
    }

    if (!mounted) return;
    setState(() {
      _videosError = !sawAnyNon404Response
          ? 'Video listesi sunucuda bulunamadi (404). Next.js API dosyasi deploy edilmedi veya URL yanlis. .env icinde TRAINING_VIDEOS_API_URL degerini tarayicida acilinca JSON donen tam adres yapin.'
          : 'Videolar su an yuklenemedi. Lutfen tekrar deneyin.';
      _isLoadingVideos = false;
    });
    debugPrint('❌ Training videos all endpoints failed => $lastError');
  }

  List<String> _videoListCandidates() {
    final urls = <String>[];
    final explicit = EnvApi.trainingVideosApiUrl;
    if (explicit != null && explicit.isNotEmpty) {
      urls.add(explicit);
    }
    final origin = EnvApi.webNextApiOrigin;
    if (origin != null && origin.isNotEmpty) {
      final o = origin.replaceAll(RegExp(r'/$'), '');
      // Deploy’daki gerçek route: pages/api/list-s3-videos.ts → /api/list-s3-videos/
      urls.add('$o/api/list-s3-videos/');
      urls.add('$o/api/videos/');
      urls.add('$o/api/list-videos/');
      urls.add('$o/api/training-videos/');
    }
    return urls.toSet().toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      drawer: const Drawer(
        child: RoleSidebar(currentPage: 'Eğitici Videolar'),
      ),
      onDrawerChanged: (isOpened) {
        setState(() {
          _isDrawerOpen = isOpened;
        });
      },
      appBar: AdminPanelAppBar(
        title: 'Eğitici Videolar',
        onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      body: GestureDetector(
        onTap: () {
          if (_isDrawerOpen) {
            _scaffoldKey.currentState?.closeDrawer();
          }
        },
        child: AbsorbPointer(
          absorbing: _isDrawerOpen,
          child: SafeArea(
            child: AnimatedBackgroundWidget(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFFFFE5E5).withValues(alpha: 0.60),
                      const Color(0xFFFFCFCF).withValues(alpha: 0.52),
                    ],
                  ),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final useListLayout = width < 640;

                    if (_isLoadingVideos) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFFE53935),
                        ),
                      );
                    }

                    if (_videosError != null) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _videosError!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Color(0xFF374151),
                                  fontWeight: FontWeight.w600,
                                  height: 1.35,
                                ),
                              ),
                              const SizedBox(height: 16),
                              FilledButton.icon(
                                onPressed: _loadVideos,
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFFE53935),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 12,
                                  ),
                                ),
                                icon: const Icon(Icons.refresh),
                                label: const Text('Tekrar dene'),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    if (_videos.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'Yüklü video bulunamadı.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFF374151),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      );
                    }

                    const scrollPhysics = AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    );
                    final listChild = useListLayout
                        ? ListView.separated(
                            physics: scrollPhysics,
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                            itemCount: _videos.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final item = _videos[index];
                              return _TrainingVideoListTile(
                                item: item,
                                onTap: () => _openVideoPlayer(item),
                              );
                            },
                          )
                        : GridView.builder(
                            physics: scrollPhysics,
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                            itemCount: _videos.length,
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: width >= 1100 ? 3 : 2,
                              crossAxisSpacing: 14,
                              mainAxisSpacing: 14,
                              childAspectRatio: width >= 1100 ? 1.22 : 1.18,
                            ),
                            itemBuilder: (context, index) {
                              final item = _videos[index];
                              return _TrainingVideoCard(
                                item: item,
                                onTap: () => _openVideoPlayer(item),
                              );
                            },
                          );

                    return RefreshIndicator(
                      color: const Color(0xFFE53935),
                      onRefresh: _loadVideos,
                      child: listChild,
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: const AdminNavbar(currentIndex: 3),
    );
  }

  void _openVideoPlayer(_TrainingVideoItem item) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (context) => _TrainingVideoPlayerPage(item: item),
      ),
    );
  }
}

class _TrainingVideoListTile extends StatelessWidget {
  const _TrainingVideoListTile({
    required this.item,
    required this.onTap,
  });

  static const _brand = Color(0xFFE53935);

  final _TrainingVideoItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(18);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: _brand.withValues(alpha: 0.10),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.white,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          splashColor: _brand.withValues(alpha: 0.10),
          highlightColor: _brand.withValues(alpha: 0.05),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 4,
                  height: 52,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        _brand,
                        _brand.withValues(alpha: 0.55),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFFFF8F8), Color(0xFFFFE4E4)],
                    ),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.95),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _brand.withValues(alpha: 0.14),
                        blurRadius: 14,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: SizedBox(
                    width: 78,
                    height: 78,
                    child: Icon(
                      Icons.play_circle_fill_rounded,
                      color: _brand,
                      size: 46,
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.18),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          height: 1.28,
                          letterSpacing: -0.2,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.touch_app_outlined,
                            size: 15,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              item.subtitle,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 13,
                                height: 1.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 10),
                    child: Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.grey.shade500,
                      size: 26,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TrainingVideoCard extends StatelessWidget {
  const _TrainingVideoCard({
    required this.item,
    required this.onTap,
  });

  static const _brand = Color(0xFFE53935);

  final _TrainingVideoItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(18);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: _brand.withValues(alpha: 0.11),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.white,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          splashColor: _brand.withValues(alpha: 0.10),
          highlightColor: _brand.withValues(alpha: 0.05),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFFFF8F8), Color(0xFFFFE8E8)],
                    ),
                    border: Border(
                      bottom: BorderSide(
                        color: _brand.withValues(alpha: 0.10),
                      ),
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              colors: [
                                _brand.withValues(alpha: 0.06),
                                Colors.transparent,
                              ],
                              radius: 0.85,
                            ),
                          ),
                        ),
                      ),
                      Icon(
                        Icons.play_circle_rounded,
                        color: _brand.withValues(alpha: 0.88),
                        size: 68,
                        shadows: const [
                          Shadow(
                            color: Color(0x22000000),
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        height: 1.22,
                        letterSpacing: -0.15,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.touch_app_outlined,
                          size: 15,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            item.subtitle,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                              height: 1.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatDuration(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  if (h > 0) {
    return '$h:$m:$s';
  }
  return '$m:$s';
}

class _TrainingVideoPlayerPage extends StatefulWidget {
  const _TrainingVideoPlayerPage({required this.item});

  final _TrainingVideoItem item;

  @override
  State<_TrainingVideoPlayerPage> createState() => _TrainingVideoPlayerPageState();
}

class _TrainingVideoPlayerPageState extends State<_TrainingVideoPlayerPage> {
  late final VideoPlayerController _controller;
  late final TransformationController _zoomController;
  bool _isInitializing = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _zoomController = TransformationController();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.item.videoUrl));
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      await _controller.initialize();
      await _controller.play();
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) => _syncImmersiveUi());
      }
    } catch (e, st) {
      debugPrint('Training video init failed: $e\n$st');
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _errorMessage = 'Video yüklenemedi. Lütfen tekrar deneyin.';
        });
      }
    }
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _zoomController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncImmersiveUi();
  }

  /// Yatayda gerçek tam ekran; dikeyde normal çubuklar.
  void _syncImmersiveUi() {
    if (!mounted) return;
    final ready = _controller.value.isInitialized && _errorMessage == null;
    final landscape = MediaQuery.orientationOf(context) == Orientation.landscape;
    if (ready && landscape) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  void _pop() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    Navigator.of(context).pop();
  }

  void _resetZoom() {
    _zoomController.value = Matrix4.identity();
  }

  Widget _playerChromeRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: _pop,
            icon: const Icon(Icons.close_rounded, color: Colors.white),
            tooltip: 'Kapat',
          ),
          Expanded(
            child: Text(
              widget.item.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w600,
                height: 1.25,
              ),
            ),
          ),
          if (_controller.value.isInitialized)
            IconButton(
              onPressed: _resetZoom,
              tooltip: 'Görünümü sıfırla',
              icon: Icon(
                Icons.fit_screen_rounded,
                color: Colors.white.withValues(alpha: 0.92),
              ),
            ),
        ],
      ),
    );
  }

  Widget _transportControls({required bool compactHint}) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final v = _controller.value;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            VideoProgressIndicator(
              _controller,
              allowScrubbing: true,
              colors: const VideoProgressColors(
                playedColor: Color(0xFFE53935),
                bufferedColor: Color(0xFFFFCDD2),
                backgroundColor: Color(0xFF4B5563),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                IconButton.filled(
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFFE53935),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    if (v.isPlaying) {
                      _controller.pause();
                    } else {
                      _controller.play();
                    }
                  },
                  icon: Icon(
                    v.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  _formatDuration(v.position),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 14,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                Text(
                  ' / ',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.35),
                    fontSize: 14,
                  ),
                ),
                Text(
                  _formatDuration(v.duration),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 14,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const Spacer(),
              ],
            ),
            if (compactHint) ...[
              const SizedBox(height: 4),
              Text(
                'İki parmakla yakınlaştırın; dikeyde küçük pencereye dönersiniz.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.55),
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
            ] else ...[
              const SizedBox(height: 4),
              Text(
                'İki parmakla yakınlaştırıp uzaklaştırın; sürükleyerek kaydırın. Yatay çevirince tam ekran olur.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.55),
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  /// Yatay: kenardan kenara video + üst/alt yarı saydam kontroller.
  Widget _buildLandscapeFullscreen(double ar) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _isInitializing || _errorMessage != null
          ? Center(child: _buildVideoState())
          : Stack(
              fit: StackFit.expand,
              children: [
                Positioned.fill(
                  child: LayoutBuilder(
                    builder: (context, c) {
                      final maxW = c.maxWidth;
                      final maxH = c.maxHeight;
                      var w = maxW;
                      var h = w / ar;
                      if (h > maxH) {
                        h = maxH;
                        w = h * ar;
                      }
                      final margin = math.max(w, h) * 0.55;
                      return ColoredBox(
                        color: Colors.black,
                        child: Center(
                          child: InteractiveViewer(
                            transformationController: _zoomController,
                            minScale: 0.35,
                            maxScale: 5.0,
                            panAxis: PanAxis.free,
                            clipBehavior: Clip.hardEdge,
                            boundaryMargin: EdgeInsets.all(margin),
                            trackpadScrollCausesScale: true,
                            child: SizedBox(
                              width: w,
                              height: h,
                              child: VideoPlayer(_controller),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.72),
                          Colors.black.withValues(alpha: 0.35),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.55, 1.0],
                      ),
                    ),
                    child: SafeArea(
                      bottom: false,
                      child: _playerChromeRow(),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.78),
                          Colors.black.withValues(alpha: 0.4),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.45, 1.0],
                      ),
                    ),
                    child: SafeArea(
                      top: false,
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(12, 10, 12, 8 + MediaQuery.paddingOf(context).bottom),
                        child: _transportControls(compactHint: true),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final ar = _controller.value.isInitialized
        ? _controller.value.aspectRatio
        : 16 / 9;

    final ready = _controller.value.isInitialized && _errorMessage == null;
    final landscape = MediaQuery.orientationOf(context) == Orientation.landscape;

    if (ready && landscape) {
      return _buildLandscapeFullscreen(ar);
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _playerChromeRow(),
            Expanded(
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF141414), Color(0xFF050505)],
                  ),
                ),
                child: _isInitializing || _errorMessage != null
                    ? ColoredBox(
                        color: Colors.black,
                        child: Center(child: _buildVideoState()),
                      )
                    : LayoutBuilder(
                        builder: (context, c) {
                          final maxW = c.maxWidth;
                          final maxH = c.maxHeight;
                          final orientation = MediaQuery.orientationOf(context);
                          var w = maxW;
                          var h = w / ar;

                          // Dikey modda yatay video: tam genişlik yerine yükseklik tavanı — dev siyah şerit hissi azalır.
                          if (orientation == Orientation.portrait && ar > 1.0) {
                            final capH = maxH * 0.40;
                            if (h > capH) {
                              h = capH;
                              w = h * ar;
                              if (w > maxW) {
                                w = maxW;
                                h = w / ar;
                              }
                            }
                          } else if (h > maxH) {
                            h = maxH;
                            w = h * ar;
                          }

                          final margin = math.max(w, h) * 0.75;
                          return Center(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: SizedBox(
                                width: w,
                                height: h,
                                child: InteractiveViewer(
                                  transformationController: _zoomController,
                                  minScale: 0.35,
                                  maxScale: 5.0,
                                  panAxis: PanAxis.free,
                                  clipBehavior: Clip.hardEdge,
                                  boundaryMargin: EdgeInsets.all(margin),
                                  trackpadScrollCausesScale: true,
                                  child: SizedBox(
                                    width: w,
                                    height: h,
                                    child: VideoPlayer(_controller),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
            if (_controller.value.isInitialized)
              Padding(
                padding: EdgeInsets.fromLTRB(12, 8, 12, 8 + bottomInset),
                child: _transportControls(compactHint: false),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoState() {
    if (_isInitializing) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFE53935)),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 15),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _pop,
                style: FilledButton.styleFrom(
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

    return const SizedBox.shrink();
  }
}

class _TrainingVideoItem {
  const _TrainingVideoItem({
    required this.title,
    required this.subtitle,
    required this.videoUrl,
  });

  factory _TrainingVideoItem.fromApi(Map<String, dynamic> json) {
    final key = (json['key'] ?? '').toString();
    final name = (json['name'] ?? '').toString();
    final titleSource = name.isNotEmpty ? name : key;

    return _TrainingVideoItem(
      title: _prettifyTitle(titleSource),
      subtitle: 'İzlemek için dokunun',
      videoUrl: _buildVideoUrl(key),
    );
  }

  static String _buildVideoUrl(String key) {
    final trimmed = key.trim();
    if (trimmed.isEmpty) return '';
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    final clean = trimmed.startsWith('/') ? trimmed.substring(1) : trimmed;

    // S3 bucket çoğu ortamda doğrudan 403; web ile aynı Next proxy (retrieve-file).
    final proxyOrigin = EnvApi.webNextApiOrigin;
    if (proxyOrigin != null && proxyOrigin.isNotEmpty) {
      final base = Uri.parse(proxyOrigin.replaceAll(RegExp(r'/$'), ''));
      return base
          .replace(
            path: '/api/retrieve-file/',
            queryParameters: <String, String>{'name': clean},
          )
          .toString();
    }

    return '${EnvApi.trainingVideosPublicBaseUrl}$clean';
  }

  /// S3 / API dosya adları ASCII (danisman, portfoy…). Görünen başlıkta Türkçe harf kullan.
  static const _slugToTurkish = <String, String>{
    'danisman': 'Danışman',
    'danismanlik': 'Danışmanlık',
    'gorev': 'Görev',
    'gorevler': 'Görevler',
    'yonetici': 'Yönetici',
    'yoneticisi': 'Yöneticisi',
    'yonetim': 'Yönetim',
    'giris': 'Giriş',
    'girisi': 'Girişi',
    'cikis': 'Çıkış',
    'islem': 'İşlem',
    'islemler': 'İşlemler',
    'onay': 'Onay',
    'onayi': 'Onayı',
    'onaylama': 'Onaylama',
    'portfoy': 'Portföy',
    'portfoyum': 'Portföyüm',
    'portfoyler': 'Portföyler',
    'ilan': 'İlan',
    'ilanlar': 'İlanlar',
    'musteri': 'Müşteri',
    'musteriler': 'Müşteriler',
    'alici': 'Alıcı',
    'satici': 'Satıcı',
    'basvuru': 'Başvuru',
    'duyuru': 'Duyuru',
    'duyurular': 'Duyurular',
    'kullanici': 'Kullanıcı',
    'kullanicilar': 'Kullanıcılar',
    'kullanim': 'Kullanım',
    'duzenle': 'Düzenle',
    'duzenleme': 'Düzenleme',
    'istatistik': 'İstatistik',
    'istatistikler': 'İstatistikler',
    'satis': 'Satış',
    'egitim': 'Eğitim',
    'egitici': 'Eğitici',
    'nasil': 'Nasıl',
    'kisi': 'Kişi',
    'kisiler': 'Kişiler',
    'tum': 'Tüm',
    'sifre': 'Şifre',
    'sifirlama': 'Sıfırlama',
    'odeme': 'Ödeme',
    'odemeler': 'Ödemeler',
    'sozlesme': 'Sözleşme',
    'guncelle': 'Güncelle',
    'guncelleme': 'Güncelleme',
    'yukle': 'Yükle',
    'yukleme': 'Yükleme',
    'indir': 'İndir',
    'paylas': 'Paylaş',
    'paylasim': 'Paylaşım',
    'ozel': 'Özel',
    'ozet': 'Özet',
    'ozeti': 'Özeti',
    'aciklama': 'Açıklama',
    'baslik': 'Başlık',
    'icerik': 'İçerik',
    'fotograf': 'Fotoğraf',
    'fotograflar': 'Fotoğraflar',
    'dokuman': 'Doküman',
    'kazanc': 'Kazanç',
    'detayi': 'Detayı',
    'listesi': 'Listesi',
  };

  static final _turkishChars = RegExp(r'[çğıöşüÇĞİÖŞÜ]');

  static String _prettifyTitle(String raw) {
    var t = raw.trim();
    try {
      t = Uri.decodeComponent(t);
    } catch (_) {}
    t = t.replaceAll(RegExp(r'\.(mp4|mov|webm)$', caseSensitive: false), '');
    if (t.isEmpty) return raw;

    final alreadyReadable =
        t.contains(' ') || t.contains('_') || _turkishChars.hasMatch(t);
    final parts = alreadyReadable
        ? t.split(RegExp(r'[\s_\-]+'))
        : () {
            var slug = t.toLowerCase();
            slug = slug.replaceAll(RegExp(r'^\w+-'), '');
            slug = slug.replaceAll(RegExp(r'-\d+$'), '');
            return slug.split('-');
          }();

    final words = parts.where((w) => w.isNotEmpty).map(_displayWord);
    final result = words.join(' ');
    return result.isEmpty ? raw : result;
  }

  static String _displayWord(String word) {
    final mapped = _slugToTurkish[word.toLowerCase()];
    if (mapped != null) return mapped;
    if (word.length <= 2 && !_turkishChars.hasMatch(word)) {
      return word.toUpperCase();
    }
    return _titleCaseTurkish(word);
  }

  static String _titleCaseTurkish(String word) {
    if (word.isEmpty) return word;
    final first = word[0];
    final rest = word.substring(1);
    final upperFirst = switch (first) {
      'i' || 'İ' when _turkishChars.hasMatch(word) => 'İ',
      'ı' => 'I',
      'ş' => 'Ş',
      'ğ' => 'Ğ',
      'ü' => 'Ü',
      'ö' => 'Ö',
      'ç' => 'Ç',
      _ => first.toUpperCase(),
    };
    return '$upperFirst$rest';
  }

  final String title;
  final String subtitle;
  final String videoUrl;
}
