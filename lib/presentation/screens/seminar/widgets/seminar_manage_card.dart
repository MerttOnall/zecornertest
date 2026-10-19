import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:zecorner/models/seminar/seminar_model.dart';

class SeminarManageCard extends StatelessWidget {
  final Seminar seminar;
  final VoidCallback? onTap;
  final VoidCallback? onOptionsPressed;

  const SeminarManageCard({
    super.key,
    required this.seminar,
    this.onTap,
    this.onOptionsPressed,
  });

  static final DateFormat _dateTime = DateFormat('dd/MM/yyyy HH:mm');

  @override
  Widget build(BuildContext context) {
    final imageUrl = seminar.resolvedCoverUrl;
    final instructors = seminar.instructorsText;
    final city = seminar.districtText.trim();
    final start = seminar.applicationStart ?? seminar.displayEventStart;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Thumb(
                imageUrl: imageUrl,
                isActive: seminar.isActive,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      seminar.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111827),
                        height: 1.25,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _MetaLine(
                      icon: Icons.person_outline_rounded,
                      text: instructors.isEmpty ? 'Eğitmen belirtilmedi' : instructors,
                    ),
                    if (city.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      _MetaLine(
                        icon: Icons.location_on_outlined,
                        text: city,
                      ),
                    ],
                    const SizedBox(height: 4),
                    _MetaLine(
                      icon: Icons.schedule_rounded,
                      text: _dateTime.format(start.toLocal()),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _MiniChip(
                          label: seminar.typeLabel,
                          color: seminar.isEducation
                              ? const Color(0xFF2563EB)
                              : const Color(0xFFE53935),
                        ),
                        _MiniChip(
                          label: seminar.isActive ? 'Aktif' : 'Pasif',
                          color: seminar.isActive
                              ? const Color(0xFF16A34A)
                              : const Color(0xFF9CA3AF),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (onOptionsPressed != null)
                IconButton(
                  onPressed: onOptionsPressed,
                  icon: const Icon(Icons.more_horiz_rounded),
                  color: const Color(0xFFE53935),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  final String? imageUrl;
  final bool isActive;

  const _Thumb({required this.imageUrl, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFF3F4F6),
            border: Border.all(color: const Color(0xFFF3F4F6), width: 2),
          ),
          clipBehavior: Clip.antiAlias,
          child: imageUrl != null && imageUrl!.isNotEmpty
              ? Image.network(
                  imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.school_rounded,
                    color: Color(0xFF9CA3AF),
                  ),
                )
              : const Icon(Icons.school_rounded, color: Color(0xFF9CA3AF)),
        ),
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFF16A34A) : const Color(0xFF9CA3AF),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Icon(
              isActive ? Icons.check_rounded : Icons.close_rounded,
              size: 12,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}

class _MetaLine extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MetaLine({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: const Color(0xFF9CA3AF)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12.5,
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _MiniChip extends StatelessWidget {
  final String label;
  final Color color;

  const _MiniChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
