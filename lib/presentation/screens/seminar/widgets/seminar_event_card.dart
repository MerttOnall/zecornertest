import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:zecorner/models/seminar/seminar_model.dart';

class SeminarEventCard extends StatelessWidget {
  final Seminar seminar;
  final VoidCallback? onTap;
  final VoidCallback? onCtaPressed;
  final VoidCallback? onOptionsPressed;
  final bool compact;
  final bool showTypeBadge;
  final bool showInstructors;
  final bool logoStyle;
  final bool showQuotaBar;

  const SeminarEventCard({
    super.key,
    required this.seminar,
    this.onTap,
    this.onCtaPressed,
    this.onOptionsPressed,
    this.compact = false,
    this.showTypeBadge = true,
    this.showInstructors = true,
    this.logoStyle = false,
    this.showQuotaBar = true,
  });

  static final DateFormat _dateTime = DateFormat('dd.MM.yyyy HH:mm');

  /// Web Eğitimler kartı Türkiye saati (UTC+3, yaz saati yok).
  static DateTime _toTurkey(DateTime value) =>
      value.toUtc().add(const Duration(hours: 3));

  static String formatRange(DateTime? start, DateTime? end) {
    if (start == null && end == null) return '-';
    if (start != null && end != null) {
      return '${_dateTime.format(_toTurkey(start))} - ${_dateTime.format(_toTurkey(end))}';
    }
    final only = start ?? end!;
    return _dateTime.format(_toTurkey(only));
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = seminar.resolvedCoverUrl;
    final imageHeight = compact ? 168.0 : 210.0;
    final containImage = logoStyle;
    final paid = !seminar.isFree && seminar.price != null && seminar.price! > 0;
    final badgeColor = paid ? const Color(0xFFEA580C) : const Color(0xFF16A34A);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                child: Stack(
                  children: [
                    SizedBox(
                      height: imageHeight,
                      width: double.infinity,
                      child: ColoredBox(
                        color: containImage
                            ? Colors.white
                            : const Color(0xFF0F172A),
                        child: imageUrl != null && imageUrl.isNotEmpty
                            ? Image.network(
                                imageUrl,
                                fit: containImage
                                    ? BoxFit.contain
                                    : BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    const _CoverFallback(),
                              )
                            : const _CoverFallback(),
                      ),
                    ),
                    if (!containImage)
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withOpacity(0.08),
                                Colors.black.withOpacity(0.38),
                              ],
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      top: 14,
                      left: 14,
                      child: _PillBadge(
                        label: seminar.priceBadgeLabel,
                        color: badgeColor,
                      ),
                    ),
                    Positioned(
                      top: 14,
                      right: 8,
                      child: Row(
                        children: [
                          if (showTypeBadge)
                            _PillBadge(
                              label: seminar.typeLabel,
                              color: seminar.isEducation
                                  ? const Color(0xFF2563EB)
                                  : const Color(0xFFE53935),
                            ),
                          if (onOptionsPressed != null)
                            IconButton(
                              onPressed: onOptionsPressed,
                              icon: Icon(
                                Icons.more_vert_rounded,
                                color: containImage
                                    ? const Color(0xFF111827)
                                    : Colors.white,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (!containImage && seminar.locationLabel.isNotEmpty)
                      Positioned(
                        left: 14,
                        right: 14,
                        bottom: 14,
                        child: Row(
                          children: [
                            const Icon(
                              Icons.location_on_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                seminar.locationLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      seminar.title,
                      style: TextStyle(
                        fontSize: compact ? 18 : 20,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF111827),
                        letterSpacing: -0.3,
                        height: 1.25,
                      ),
                    ),
                    if (seminar.slogan.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        seminar.slogan,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                          height: 1.35,
                        ),
                      ),
                    ],
                    if (seminar.address.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Adres: ${seminar.address}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF4B5563),
                          height: 1.4,
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    _MetaRow(
                      icon: Icons.event_available_rounded,
                      label: 'Başvuru',
                      value: formatRange(
                        seminar.applicationStart,
                        seminar.applicationEnd,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _MetaRow(
                      icon: Icons.calendar_month_rounded,
                      label: 'Etkinlik',
                      value: formatRange(
                        seminar.displayEventStart,
                        seminar.displayEventEnd,
                      ),
                    ),
                    if (showInstructors && seminar.instructors.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _MetaRow(
                        icon: Icons.person_outline_rounded,
                        label: 'Eğitmen(ler)',
                        value: seminar.instructorsText,
                      ),
                    ],
                    if (seminar.quota > 0) ...[
                      const SizedBox(height: 14),
                      if (showQuotaBar) ...[
                        Row(
                          children: [
                            Text(
                              '${seminar.applicationCount} / ${seminar.quota} başvuru',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: Color(0xFF111827),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '%${(seminar.quotaProgress * 100).round()}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: seminar.isQuotaFull
                                    ? const Color(0xFFDC2626)
                                    : const Color(0xFF16A34A),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(99),
                          child: LinearProgressIndicator(
                            value: seminar.quotaProgress,
                            minHeight: 7,
                            backgroundColor: const Color(0xFFF3F4F6),
                            color: seminar.isQuotaFull
                                ? const Color(0xFFDC2626)
                                : const Color(0xFF16A34A),
                          ),
                        ),
                      ] else
                        Text(
                          '${seminar.applicationCount} / ${seminar.quota} başvuru',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                    ],
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: seminar.canApply
                            ? (onCtaPressed ?? onTap)
                            : null,
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor: const Color(0xFFE53935),
                          disabledBackgroundColor: const Color(0xFFE5E7EB),
                          foregroundColor: Colors.white,
                          disabledForegroundColor: const Color(0xFF4B5563),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          textStyle: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            fontStyle: seminar.canApply
                                ? FontStyle.normal
                                : FontStyle.italic,
                          ),
                        ),
                        child: Text(seminar.ctaLabel),
                      ),
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

class _CoverFallback extends StatelessWidget {
  const _CoverFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E3A8A), Color(0xFF0F172A)],
        ),
      ),
      child: const Center(
        child: Icon(Icons.school_rounded, color: Colors.white54, size: 48),
      ),
    );
  }
}

class _PillBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _PillBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(99),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.28),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MetaRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: const Color(0xFFE53935)),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
            color: Color(0xFF111827),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF4B5563),
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}
