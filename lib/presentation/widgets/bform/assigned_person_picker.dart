import 'dart:async';

import 'package:flutter/material.dart';
import 'package:zecorner/core/utils/image_utils.dart';
import 'package:zecorner/infrastructure/contact/contact_search_repository.dart';
import 'package:zecorner/infrastructure/bform/bform_api_repository.dart';
import 'package:zecorner/models/contact/contact_search_model.dart';
import 'package:dio/dio.dart';

const _kRed = Color(0xFFE53935);

/// Klasik projedeki kişi araması: yazdıkça sonuç, seçince kart.
class AssignedPersonPicker extends StatefulWidget {
  const AssignedPersonPicker({
    super.key,
    this.initialPerson,
    this.onChanged,
    this.label = 'Atanan Kişi',
    this.hintText = 'Ara',
    this.useFormAssignables = false,
  });

  final ContactSearchModel? initialPerson;
  final ValueChanged<ContactSearchModel?>? onChanged;
  final String label;
  final String hintText;
  final bool useFormAssignables;

  @override
  State<AssignedPersonPicker> createState() => _AssignedPersonPickerState();
}

class _AssignedPersonPickerState extends State<AssignedPersonPicker> {
  final ContactSearchRepository _contactSearch = ContactSearchRepository();
  final BformApiRepository _bformRepository = BformApiRepository(dio: Dio());
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  Timer? _debounce;
  List<ContactSearchModel> _results = [];
  List<ContactSearchModel> _allAssignables = [];
  bool _isSearching = false;
  bool _showResults = false;
  ContactSearchModel? _selected;
  String? _searchError;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialPerson;
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        // Kısa gecikme: listeden tıklamaya izin ver
        Future<void>.delayed(const Duration(milliseconds: 180), () {
          if (mounted && !_focusNode.hasFocus) {
            setState(() => _showResults = false);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onQueryChanged(String query) {
    _debounce?.cancel();
    final trimmed = query.trim();
    if (trimmed.isEmpty && !widget.useFormAssignables) {
      setState(() {
        _results = [];
        _showResults = false;
        _isSearching = false;
        _searchError = null;
      });
      return;
    }

    // Assignables: önce yerel süz, gerekirse yeniden çek
    if (widget.useFormAssignables && _allAssignables.isNotEmpty) {
      setState(() {
        _searchError = null;
        _showResults = true;
        _isSearching = false;
        _results = _filterLocal(_allAssignables, trimmed);
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _showResults = true;
      _searchError = null;
    });

    _debounce = Timer(const Duration(milliseconds: 350), () {
      _search(trimmed);
    });
  }

  List<ContactSearchModel> _filterLocal(
    List<ContactSearchModel> source,
    String query,
  ) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return List<ContactSearchModel>.from(source);
    return source.where((c) {
      return c.title.toLowerCase().contains(q) ||
          c.email.toLowerCase().contains(q) ||
          c.typeDescription.toLowerCase().contains(q) ||
          c.contactNo.toString().contains(q);
    }).toList();
  }

  Future<void> _search(String query) async {
    try {
      List<ContactSearchModel> results = [];
      String? error;
      if (widget.useFormAssignables) {
        // Önce tam listeyi çek (searchText API'de boş dönse bile lokal süzülür)
        if (_allAssignables.isEmpty) {
          final seed = await _bformRepository.searchFormAssignables(
            query: '',
            pageSize: 200,
            page: 1,
          );
          seed.fold(
            (failure) => error = failure.message,
            (r) => _allAssignables = List<ContactSearchModel>.from(r),
          );
        }

        if (error == null && _allAssignables.isEmpty) {
          // Seed boşsa query ile tekrar dene
          final assignables = await _bformRepository.searchFormAssignables(
            query: query,
            pageSize: 100,
            page: 1,
          );
          results = assignables.fold(
            (failure) {
              error = failure.message;
              return <ContactSearchModel>[];
            },
            (r) => r,
          );
          if (error == null && query.trim().isEmpty) {
            _allAssignables = List<ContactSearchModel>.from(results);
          }
        } else if (error == null) {
          results = _filterLocal(_allAssignables, query);
        }
      } else {
        results = await _contactSearch.searchContacts(
          query: query,
          size: 8,
          userContacts: true,
        );
        if (results.isEmpty) {
          results = await _contactSearch.searchContacts(
            query: query,
            size: 8,
          );
        }
      }
      if (!mounted) return;
      setState(() {
        _results = results;
        _isSearching = false;
        _showResults = true;
        _searchError = error;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _results = [];
        _isSearching = false;
        _showResults = true;
        _searchError = 'Kişi araması başarısız';
      });
    }
  }

  void _select(ContactSearchModel person) {
    setState(() {
      _selected = person;
      _controller.clear();
      _results = [];
      _showResults = false;
    });
    _focusNode.unfocus();
    widget.onChanged?.call(person);
  }

  void _clear() {
    setState(() {
      _selected = null;
      _controller.clear();
      _results = [];
      _showResults = false;
    });
    widget.onChanged?.call(null);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 8),
        _buildSearchField(),
        if (_showResults) ...[
          const SizedBox(height: 8),
          _buildResults(),
        ],
        if (_selected != null) ...[
          const SizedBox(height: 10),
          AssignedPersonCard(
            name: _selected!.title,
            email: _selected!.email,
            role: _selected!.typeDescription,
            picture: _selected!.picture,
            onRemove: _clear,
          ),
        ],
      ],
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      onChanged: _onQueryChanged,
      onTap: () {
        if (widget.useFormAssignables) {
          setState(() {
            _showResults = true;
            if (_results.isEmpty && !_isSearching) {
              _isSearching = true;
            }
          });
          if (_results.isEmpty) {
            _search(_controller.text.trim());
          }
          return;
        }
        if (_controller.text.trim().isNotEmpty) {
          setState(() => _showResults = true);
        }
      },
      decoration: InputDecoration(
        hintText: widget.hintText,
        hintStyle: TextStyle(
          color: Colors.grey.shade400,
          fontSize: 15,
        ),
        suffixIcon: _isSearching
            ? const Padding(
                padding: EdgeInsets.all(14),
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: _kRed,
                  ),
                ),
              )
            : Icon(Icons.search_rounded, color: Colors.grey.shade400),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        filled: true,
        fillColor: Colors.white,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _kRed, width: 1.4),
        ),
      ),
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: Color(0xFF1F2937),
      ),
    );
  }

  Widget _buildResults() {
    return Container(
      constraints: const BoxConstraints(maxHeight: 240),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: _isSearching && _results.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: CircularProgressIndicator(color: _kRed, strokeWidth: 2),
              ),
            )
          : _searchError != null && _results.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    _searchError!,
                    style: const TextStyle(
                      color: _kRed,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )
          : _results.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Kişi bulunamadı',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  itemCount: _results.length,
                  separatorBuilder: (_, __) =>
                      Divider(height: 1, color: Colors.grey.shade200),
                  itemBuilder: (context, index) {
                    final person = _results[index];
                    return InkWell(
                      onTap: () => _select(person),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            AssignedPersonAvatar(
                              name: person.title,
                              picture: person.picture,
                              radius: 22,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    person.title,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF111827),
                                    ),
                                  ),
                                  if (person.email.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      person.email,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                  ],
                                  if (person.typeDescription.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      person.typeDescription,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

class AssignedPersonCard extends StatelessWidget {
  const AssignedPersonCard({
    super.key,
    required this.name,
    this.email,
    this.role,
    this.picture,
    this.onRemove,
    this.compact = false,
  });

  final String name;
  final String? email;
  final String? role;
  final String? picture;
  final VoidCallback? onRemove;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 12,
        vertical: compact ? 10 : 12,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          AssignedPersonAvatar(name: name, picture: picture, radius: compact ? 20 : 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
                if (email != null && email!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    email!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
                if (role != null && role!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    role!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (onRemove != null)
            IconButton(
              onPressed: onRemove,
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.close_rounded, color: _kRed, size: 20),
            ),
        ],
      ),
    );
  }
}

class AssignedPersonAvatar extends StatelessWidget {
  const AssignedPersonAvatar({
    super.key,
    required this.name,
    this.picture,
    this.radius = 22,
  });

  final String name;
  final String? picture;
  final double radius;

  String? get _imageUrl {
    if (picture == null || picture!.isEmpty) return null;
    if (picture!.startsWith('http')) return picture;
    final url = ImageUtils.getProfileImageUrl(picture);
    return url.isEmpty ? null : url;
  }

  @override
  Widget build(BuildContext context) {
    final url = _imageUrl;
    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFFE5E7EB),
      backgroundImage: url != null ? NetworkImage(url) : null,
      onBackgroundImageError: url != null ? (_, __) {} : null,
      child: url == null
          ? Icon(
              Icons.person_rounded,
              size: radius + 4,
              color: Colors.grey.shade500,
            )
          : null,
    );
  }
}
