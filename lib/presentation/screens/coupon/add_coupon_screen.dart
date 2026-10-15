import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:zecorner/presentation/screens/coupon/coupon_valid_until_picker.dart';
import 'package:zecorner/presentation/screens/coupon/coupon_template_picker_sheet.dart';
import 'package:zecorner/presentation/screens/coupon/coupon_admin_guard.dart';
import 'package:zecorner/presentation/widgets/admin-panel/admin_panel_in_appbar.dart';
import 'package:zecorner/infrastructure/contact/contact_search_repository.dart';
import 'package:zecorner/models/contact/contact_search_model.dart';
import 'package:zecorner/infrastructure/coupon/coupon_api_repository.dart';

class AddCouponScreen extends StatefulWidget {
  const AddCouponScreen({Key? key}) : super(key: key);

  @override
  State<AddCouponScreen> createState() => _AddCouponScreenState();
}

class _AddCouponScreenState extends State<AddCouponScreen> with CouponAdminGuard {
  final _formKey = GlobalKey<FormState>();
  
  // Form controllers
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _userSearchController = TextEditingController();
  
  // Form states
  String? _selectedTemplateId;
  ContactSearchModel? _selectedContact;
  DateTime? _selectedValidUntil;
  
  // Search states
  List<ContactSearchModel> _searchResults = [];
  bool _isSearching = false;
  bool _showSearchResults = false;
  
  // Repositories
  final ContactSearchRepository _contactRepository = ContactSearchRepository();
  final CouponApiRepository _couponRepository = CouponApiRepository();
  
  // Templates
  List<Map<String, dynamic>> _couponTemplates = [];
  bool _isLoadingTemplates = false;
  
  // Debouncing için timer
  Timer? _searchTimer;

  @override
  void initState() {
    super.initState();
    print('✅ AddCouponScreen initState çağrıldı');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      checkCouponAdminAccess(onAllowed: _loadCouponTemplates);
    });
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    _amountController.dispose();
    _userSearchController.dispose();
    super.dispose();
  }

  Future<void> _loadCouponTemplates() async {
    setState(() {
      _isLoadingTemplates = true;
    });

    final result = await _couponRepository.getCouponTemplates();
    result.fold(
      (failure) {
        if (mounted) {
          setState(() {
            _isLoadingTemplates = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Kupon şablonları yüklenemedi: ${failure.message}'),
              backgroundColor: const Color(0xFFE53935),
            ),
          );
        }
      },
      (templates) {
        if (mounted) {
          setState(() {
            _couponTemplates = templates;
            _isLoadingTemplates = false;
          });
        }
      },
    );
  }

  void _performUserSearch(String query) {
    // Önceki timer'ı iptal et
    _searchTimer?.cancel();
    
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _showSearchResults = false;
        _isSearching = false;
      });
      return;
    }
    
    // Debouncing: 500ms bekle, sonra arama yap
    _searchTimer = Timer(const Duration(milliseconds: 500), () async {
      if (!mounted) return;
      
      setState(() {
        _isSearching = true;
        _showSearchResults = true;
      });
      
      try {
        final results = await _contactRepository.searchContacts(
          query: query,
          size: 10,
          type: '',
        );
        
        if (mounted) {
          setState(() {
            _searchResults = results;
            _isSearching = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _searchResults = [];
            _isSearching = false;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Arama sırasında hata oluştu: $e'),
              backgroundColor: const Color(0xFFE53935),
            ),
          );
        }
      }
    });
  }

  void _selectUser(ContactSearchModel contact) {
    setState(() {
      _selectedContact = contact;
      _userSearchController.text = contact.title;
      _showSearchResults = false;
    });
    FocusScope.of(context).unfocus();
  }

  Future<void> _selectDate() async {
    final picked = await pickCouponValidUntil(
      context,
      current: _selectedValidUntil,
      firstSelectableDate: DateTime.now(),
    );
    if (picked != null && mounted) {
      setState(() => _selectedValidUntil = picked);
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedTemplateId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen kupon şablonu seçiniz'),
          backgroundColor: Color(0xFFE53935),
        ),
      );
      return;
    }

    if (_selectedContact == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen kullanıcı/ofis seçiniz'),
          backgroundColor: Color(0xFFE53935),
        ),
      );
      return;
    }

    if (_selectedValidUntil == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen son kullanma tarihi seçiniz'),
          backgroundColor: Color(0xFFE53935),
        ),
      );
      return;
    }

    // Loading göster
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFE53935),
        ),
      ),
    );

    try {
      final templateId = int.tryParse(_selectedTemplateId ?? '');
      final amount = int.tryParse(_amountController.text);
      
      if (templateId == null) {
        Navigator.pop(context); // Loading'i kapat
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Geçersiz kupon şablonu'),
            backgroundColor: Color(0xFFE53935),
          ),
        );
        return;
      }

      if (amount == null || amount <= 0) {
        Navigator.pop(context); // Loading'i kapat
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Geçerli bir adet giriniz'),
            backgroundColor: Color(0xFFE53935),
          ),
        );
        return;
      }

      final result = await _couponRepository.grantCoupon(
        couponTemplateId: templateId,
        contactId: _selectedContact!.contactNo,
        amount: amount,
        validUntil: _selectedValidUntil!,
        status: 1,
      );

      if (mounted) {
        Navigator.pop(context); // Loading'i kapat

        result.fold(
          (failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Kupon tanımlanamadı: ${failure.message}'),
                backgroundColor: const Color(0xFFE53935),
              ),
            );
          },
          (response) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Kupon başarıyla tanımlandı'),
                backgroundColor: Colors.green,
              ),
            );
            
            // Başarılı olduktan sonra geri dön
            Navigator.pop(context, true);
          },
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Loading'i kapat
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kupon tanımlanırken hata oluştu: $e'),
            backgroundColor: const Color(0xFFE53935),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    print('✅ AddCouponScreen build çağrıldı');
    final gate = couponAccessGate();
    if (gate != null) return gate;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AdminPanelInAppBar(
        title: 'Kupon Tanımla',
        onBackPressed: () {
          print('🔵 Geri butonu tıklandı');
          Navigator.pop(context);
        },
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Container(
            color: Colors.white,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),
                  
                  // Kupon Şablonu
                  _buildSectionTitle('Kupon Şablonu'),
                  const SizedBox(height: 12),
                  _buildTemplateDropdown(),
                  const SizedBox(height: 28),
                  
                  // Kullanıcı/Ofis
                  _buildSectionTitle('Kullanıcı/Ofis'),
                  const SizedBox(height: 12),
                  _buildUserSearchField(),
                  const SizedBox(height: 28),
                  
                  // Adet
                  _buildSectionTitle('Adet'),
                  const SizedBox(height: 12),
                  _buildAmountField(),
                  const SizedBox(height: 28),
                  
                  // Son Kullanma Tarihi
                  _buildSectionTitle('Son Kullanma Tarihi'),
                  const SizedBox(height: 12),
                  _buildDateField(),
                  const SizedBox(height: 48),
                  
                  // Butonlar
                  _buildActionButtons(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFFE53935),
                const Color(0xFFE53935).withOpacity(0.6),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1F2937),
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildTemplateDropdown() {
    if (_isLoadingTemplates) {
      return Container(
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFE53935).withOpacity(0.25),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFE53935).withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.confirmation_number_rounded,
                color: Color(0xFFE53935),
                size: 20,
              ),
            ),
            const Expanded(
              child: Text(
                'Kupon şablonları yükleniyor...',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1F2937),
                ),
              ),
            ),
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                color: Color(0xFFE53935),
                strokeWidth: 2,
              ),
            ),
          ],
        ),
      );
    }

    return FormField<String>(
      initialValue: _selectedTemplateId,
      validator: (v) {
        if (v == null || v.isEmpty) {
          return 'Kupon şablonu seçiniz';
        }
        return null;
      },
      builder: (fieldState) {
        String? selectedName;
        final currentId = fieldState.value;
        if (currentId != null) {
          for (final t in _couponTemplates) {
            if ('${t['id']}' == currentId) {
              selectedName = t['name'] as String?;
              break;
            }
          }
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _couponTemplates.isEmpty
                    ? null
                    : () async {
                        final id = await showCouponTemplatePickerSheet(
                          context,
                          templates: _couponTemplates,
                          selectedId: fieldState.value ?? _selectedTemplateId,
                        );
                        if (id != null && mounted) {
                          fieldState.didChange(id);
                          setState(() => _selectedTemplateId = id);
                        }
                      },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  constraints: const BoxConstraints(minHeight: 56),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: fieldState.hasError
                          ? const Color(0xFFE53935)
                          : const Color(0xFFE53935).withOpacity(0.25),
                      width: fieldState.hasError ? 2 : 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE53935).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.confirmation_number_rounded,
                          color: Color(0xFFE53935),
                          size: 20,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          selectedName ??
                              (_couponTemplates.isEmpty
                                  ? 'Kupon şablonu bulunamadı'
                                  : 'Listeyi açmak için dokunun'),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: selectedName != null
                                ? const Color(0xFF1F2937)
                                : Colors.grey.shade400,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(
                        Icons.unfold_more_rounded,
                        color: Colors.grey.shade500,
                        size: 22,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (fieldState.hasError)
              Padding(
                padding: const EdgeInsets.only(left: 8, top: 6),
                child: Text(
                  fieldState.errorText!,
                  style: const TextStyle(
                    color: Color(0xFFE53935),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildUserSearchField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          constraints: const BoxConstraints(minHeight: 56),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFE53935).withOpacity(0.25),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: _userSearchController,
            onChanged: _performUserSearch,
            onTap: () {
              if (_userSearchController.text.isNotEmpty) {
                setState(() {
                  _showSearchResults = true;
                });
              }
            },
            decoration: InputDecoration(
              hintText: 'Ara',
              hintStyle: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 15,
              ),
              prefixIcon: Container(
                margin: const EdgeInsets.all(10),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE53935).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.search_rounded,
                  color: Color(0xFFE53935),
                  size: 20,
                ),
              ),
              suffixIcon: _userSearchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(
                        Icons.clear_rounded,
                        color: Colors.grey.shade400,
                      ),
                      onPressed: () {
                        setState(() {
                          _userSearchController.clear();
                          _selectedContact = null;
                          _searchResults = [];
                          _showSearchResults = false;
                        });
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
              border: InputBorder.none,
            ),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
            ),
          ),
        ),
        
        // Arama sonuçları
        if (_showSearchResults)
          Container(
            margin: const EdgeInsets.only(top: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.grey.shade200,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            constraints: const BoxConstraints(maxHeight: 200),
            child: _isSearching
                ? const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFE53935),
                      ),
                    ),
                  )
                : _searchResults.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'Sonuç bulunamadı',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        itemCount: _searchResults.length,
                        separatorBuilder: (context, index) => Divider(
                          height: 1,
                          color: Colors.grey.shade200,
                        ),
                        itemBuilder: (context, index) {
                          final contact = _searchResults[index];
                          final isSelected = _selectedContact?.contactNo == contact.contactNo;
                          
                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _selectUser(contact),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected 
                                      ? const Color(0xFFE53935).withOpacity(0.05)
                                      : Colors.transparent,
                                ),
                                child: Row(
                                  children: [
                                    // Avatar
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundColor: const Color(0xFFE53935),
                                      child: contact.picture != null
                                          ? ClipOval(
                                              child: Image.network(
                                                contact.picture!,
                                                width: 40,
                                                height: 40,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) {
                                                  return Text(
                                                    contact.title.split(' ').map((e) => e.isNotEmpty ? e[0] : '').join('').toUpperCase(),
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 14,
                                                    ),
                                                  );
                                                },
                                              ),
                                            )
                                          : Text(
                                              contact.title.split(' ').map((e) => e.isNotEmpty ? e[0] : '').join('').toUpperCase(),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            contact.title,
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF1F2937),
                                            ),
                                          ),
                                          if (contact.email.isNotEmpty) ...[
                                            const SizedBox(height: 2),
                                            Text(
                                              contact.email,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade600,
                                                fontWeight: FontWeight.w400,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                          const SizedBox(height: 2),
                                          Text(
                                            contact.typeDescription,
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.grey.shade600,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (isSelected)
                                      Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFE53935),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.check,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      )
                                    else
                                      Icon(
                                        Icons.arrow_forward_ios_rounded,
                                        size: 16,
                                        color: Colors.grey.shade400,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
      ],
    );
  }

  Widget _buildAmountField() {
    return Container(
      constraints: const BoxConstraints(minHeight: 56),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE53935).withOpacity(0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: _amountController,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          hintText: 'Örn: 5',
          hintStyle: TextStyle(
            color: Colors.grey.shade400,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFE53935).withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.numbers_rounded,
              color: Color(0xFFE53935),
              size: 20,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          border: InputBorder.none,
        ),
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1F2937),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Adet giriniz';
          }
          final amount = int.tryParse(value);
          if (amount == null || amount <= 0) {
            return 'Geçerli bir adet giriniz';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildDateField() {
    return GestureDetector(
      onTap: _selectDate,
      child: Container(
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFE53935).withOpacity(0.25),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFE53935).withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.calendar_today_outlined,
                color: Color(0xFFE53935),
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                _selectedValidUntil != null
                    ? DateFormat('dd.MM.yyyy HH:mm').format(_selectedValidUntil!)
                    : 'Tarih ve saat seçiniz',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: _selectedValidUntil != null
                      ? const Color(0xFF1F2937)
                      : Colors.grey.shade400,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Navigator.pop(context),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.grey.shade300,
                    width: 1.5,
                  ),
                ),
                child: const Center(
                  child: Text(
                    'İptal',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          flex: 2,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _handleSubmit,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFE53935),
                      const Color(0xFFD32F2F),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFE53935).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    'Tanımla',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

