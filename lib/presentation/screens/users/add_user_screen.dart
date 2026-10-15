import 'dart:async';
import 'package:flutter/material.dart';
import 'package:zecorner/presentation/widgets/admin-panel/admin_panel_appbar.dart';
import 'package:zecorner/infrastructure/contact/contact_search_repository.dart';
import 'package:zecorner/models/contact/contact_search_model.dart';
import 'package:zecorner/infrastructure/contact/contact_api_repository.dart';

class AddUserScreen extends StatefulWidget {
  const AddUserScreen({super.key});

  @override
  State<AddUserScreen> createState() => _AddUserScreenState();
}

class _AddUserScreenState extends State<AddUserScreen> {
  final List<String> _selectedRoles = [];
  bool _isExpanded = false;
  List<ContactSearchModel> _searchResults = [];
  ContactSearchModel? _selectedContact;
  bool _isSearching = false;
  final ContactSearchRepository _contactRepository = ContactSearchRepository();
  final ContactApiRepository _contactApiRepository = ContactApiRepository();
  
  List<String> _availableRoles = [];
  bool _isLoadingRoles = false;
  
  // Debouncing için timer
  Timer? _searchTimer;
  
  // Search input controller
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _loadRoles();
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _loadRoles() async {
    setState(() {
      _isLoadingRoles = true;
    });

    try {
      final result = await _contactApiRepository.getAvailableRoles();
      result.fold(
        (failure) {
          setState(() {
            _isLoadingRoles = false;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Roller yüklenemedi: ${failure.message}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        (roles) {
          setState(() {
            _availableRoles = roles;
            _isLoadingRoles = false;
          });
        },
      );
    } catch (e) {
      setState(() {
        _isLoadingRoles = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Roller yüklenirken hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _createUser() async {
    // Validation - Edit screen'deki gibi detaylı validasyon
    if (_selectedContact == null) {
      _showErrorSnackBar('Lütfen bir kişi seçin');
      return;
    }

    // DEBUG: Contact bilgilerini yazdır
    print('🔍 DEBUG: Selected Contact Details:');
    print('🔍 Contact No: ${_selectedContact!.contactNo}');
    print('🔍 Contact Title: ${_selectedContact!.title}');
    print('🔍 Contact Email: ${_selectedContact!.email}');
    print('🔍 Contact Type: ${_selectedContact!.typeDescription}');

    // Contact ID validasyonu - Edit screen'deki gibi
    if (_selectedContact!.contactNo <= 0) {
      print('❌ DEBUG: Invalid contact ID: ${_selectedContact!.contactNo}');
      _showErrorSnackBar('Seçilen kişinin geçerli bir ID\'si yok. Lütfen farklı bir kişi seçin.');
      return;
    }

    if (_selectedRoles.isEmpty) {
      _showErrorSnackBar('Lütfen en az bir rol seçin');
      return;
    }

    print('🔍 DEBUG: Selected Roles: $_selectedRoles');

    // Show loading
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
      // Contact'tan kullanıcı oluştur (durum ve roller birlikte)
      final createResult = await _contactApiRepository.createUserFromContact(
        contactId: _selectedContact!.contactNo,
        roles: _selectedRoles,
      );

      // Close loading dialog
      if (mounted) {
        Navigator.pop(context);

        if (createResult.isRight()) {
          _showSuccessSnackBar('Kullanıcı başarıyla oluşturuldu!');
          
          // Navigate back after a short delay
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) {
              Navigator.of(context).pop(true);
            }
          });
        } else {
          final failure = createResult.fold((l) => l, (r) => null);
          _showErrorSnackBar(failure?.message ?? 'Kullanıcı oluşturulamadı');
        }
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) {
        Navigator.pop(context);
        _showErrorSnackBar('Kullanıcı oluşturulurken hata oluştu: $e');
      }
    }
  }

  void _performSearch(String query) {
    // Önceki timer'ı iptal et
    _searchTimer?.cancel();
    
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }
    
    // Debouncing: 500ms bekle, sonra arama yap
    _searchTimer = Timer(const Duration(milliseconds: 500), () async {
      if (!mounted) return;
      
      setState(() {
        _isSearching = true;
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
          
          // Hata durumunda kullanıcıya bilgi ver
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Arama sırasında hata oluştu: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    });
  }

  // Helper methods - Edit screen'deki gibi
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFE53935),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AdminPanelAppBar(
        title: "Yeni Kullanıcı Ekle",
        useBackButton: true,
        onMenuPressed: () => Navigator.pop(context),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Kişi Arama
              const Text(
                "Kişi Arama",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _searchController,
                onChanged: (value) {
                  _performSearch(value);
                },
                decoration: InputDecoration(
                  hintText: "Kişi adı, email veya telefon ile ara...",
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Color(0xFFE53935),
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            Icons.clear,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchResults = [];
                            });
                            _performSearch('');
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: Color(0xFFE53935),
                      width: 2,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                ),
              ),
              
              // Arama sonuçları
              if (_searchController.text.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: _isSearching
                      ? const Padding(
                          padding: EdgeInsets.all(20),
                          child: Center(
                            child: Column(
                              children: [
                                CircularProgressIndicator(
                                  color: Color(0xFFE53935),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Aranıyor...',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : _searchResults.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.all(20),
                              child: Center(
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.search_off,
                                      color: Colors.grey,
                                      size: 48,
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Sonuç bulunamadı',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      'Farklı bir arama terimi deneyin',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : Column(
                              children: [
                                // Sonuç sayısı
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(8),
                                      topRight: Radius.circular(8),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.people,
                                        color: Colors.grey[600],
                                        size: 16,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${_searchResults.length} kişi bulundu',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Sonuç listesi
                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: _searchResults.length,
                                  itemBuilder: (context, index) {
                                    final contact = _searchResults[index];
                                    final isSelected = _selectedContact?.contactNo == contact.contactNo;
                                    
                                    return InkWell(
                                      onTap: () {
                                        setState(() {
                                          _selectedContact = contact;
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: isSelected ? const Color(0xFFFFEBEE) : Colors.white,
                                          border: index < _searchResults.length - 1 
                                              ? Border(bottom: BorderSide(color: Colors.grey[200]!))
                                              : null,
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
                                            // İsim ve detaylar
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    contact.title,
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                  if (contact.email.isNotEmpty)
                                                    Text(
                                                      contact.email,
                                                      style: TextStyle(
                                                        color: Colors.grey[600],
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                  Text(
                                                    contact.typeDescription,
                                                    style: TextStyle(
                                                      color: Colors.grey[600],
                                                      fontSize: 14,
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
                                              ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                ),
              
              // Seçilen kişi gösterimi
              if (_selectedContact != null)
                Container(
                  margin: const EdgeInsets.only(top: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE53935), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFE53935).withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: const Color(0xFFE53935),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            "Seçilen Kişi",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Color(0xFFE53935),
                            ),
                          ),
                          const Spacer(),
                          InkWell(
                            onTap: () {
                              setState(() {
                                _selectedContact = null;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE53935).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Color(0xFFE53935),
                                size: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: const Color(0xFFE53935),
                            child: _selectedContact!.picture != null
                                ? ClipOval(
                                    child: Image.network(
                                      _selectedContact!.picture!,
                                      width: 48,
                                      height: 48,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Text(
                                          _selectedContact!.title.split(' ').map((e) => e.isNotEmpty ? e[0] : '').join('').toUpperCase(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        );
                                      },
                                    ),
                                  )
                                : Text(
                                    _selectedContact!.title.split(' ').map((e) => e.isNotEmpty ? e[0] : '').join('').toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _selectedContact!.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: Color(0xFFE53935),
                                  ),
                                ),
                                if (_selectedContact!.email.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.email,
                                          color: Colors.grey[600],
                                          size: 16,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          _selectedContact!.email,
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.work,
                                        color: Colors.grey[600],
                                        size: 16,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        _selectedContact!.typeDescription,
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 24),
              // Kişi Yetkileri
              const Text(
                "Kişi Yetkileri",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              // Yetki seçme container'ı
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  children: [
                    // Seçili yetkiler ve başlık aynı satırda
                    InkWell(
                      onTap: () {
                        setState(() {
                          _isExpanded = !_isExpanded;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Seçiniz"),
                            const SizedBox(width: 8),
                            if (_selectedRoles.isNotEmpty)
                              Expanded(
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: _selectedRoles.map((role) => Container(
                                      margin: const EdgeInsets.only(right: 8),
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFEBEE),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            role,
                                            style: const TextStyle(
                                              color: Color.fromRGBO(238, 46, 36, 1),
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          InkWell(
                                            onTap: () {
                                              setState(() {
                                                _selectedRoles.remove(role);
                                              });
                                            },
                                            child: const Icon(
                                              Icons.close,
                                              size: 18,
                                              color: Color.fromRGBO(238, 46, 36, 1),
                                            ),
                                          ),
                                        ],
                                      ),
                                    )).toList(),
                                  ),
                                ),
                              ),
                            Icon(
                              _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                              color: Colors.grey[600],
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Yetki listesi
                    if (_isExpanded)
                      _isLoadingRoles
                          ? const Padding(
                              padding: EdgeInsets.all(20),
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xFFE53935),
                                ),
                              ),
                            )
                          : _availableRoles.isEmpty
                              ? const Padding(
                                  padding: EdgeInsets.all(20),
                                  child: Center(
                                    child: Text(
                                      'Rol bulunamadı',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: _availableRoles.length,
                                  itemBuilder: (context, index) {
                                    final role = _availableRoles[index];
                                    final isSelected = _selectedRoles.contains(role);
                                    return InkWell(
                                      onTap: () {
                                        setState(() {
                                          if (isSelected) {
                                            _selectedRoles.remove(role);
                                          } else {
                                            _selectedRoles.add(role);
                                          }
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 12,
                                        ),
                                        decoration: BoxDecoration(
                                          border: Border(
                                            top: BorderSide(color: Colors.grey[300]!),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    role,
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.w500,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            if (isSelected)
                                              const Icon(
                                                Icons.check,
                                                color: Color.fromRGBO(238, 46, 36, 1),
                                              ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              // Kullanıcı Oluştur Butonu
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _createUser,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE53935),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    "Kullanıcı Oluştur",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 