import 'package:flutter/material.dart';
import 'package:zecorner/presentation/widgets/admin-panel/admin_panel_in_appbar.dart';
import 'package:zecorner/infrastructure/coupon/coupon_api_repository.dart';
import 'package:zecorner/presentation/screens/coupon/coupon_admin_guard.dart';

class _CouponTypeOption {
  final String value;
  final String label;

  _CouponTypeOption({required this.value, required this.label});
}

class AddCouponTemplateScreen extends StatefulWidget {
  const AddCouponTemplateScreen({Key? key}) : super(key: key);

  @override
  State<AddCouponTemplateScreen> createState() => _AddCouponTemplateScreenState();
}

class _AddCouponTemplateScreenState extends State<AddCouponTemplateScreen>
    with CouponAdminGuard {
  static const double _kFieldHeight = 52.0;

  final _formKey = GlobalKey<FormState>();
  
  // Form controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _discountAmountController = TextEditingController();
  final TextEditingController _thresholdController = TextEditingController();
  final TextEditingController _maxDiscountController = TextEditingController();
  
  /// UI: "Ücretsiz" → FREE, "İndirim (yüzde)" → DISCOUNT
  String? _selectedCouponType;
  String? _selectedPaymentType; // "Danışman Ödemesi", "Eğitim Ödemesi"
  
  // Repository
  final CouponApiRepository _repository = CouponApiRepository();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      checkCouponAdminAccess();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _discountAmountController.dispose();
    _thresholdController.dispose();
    _maxDiscountController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCouponType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen kupon türü seçiniz'),
          backgroundColor: Color(0xFFE53935),
        ),
      );
      return;
    }

    if (_selectedPaymentType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen kuponun geçerli olduğu ödeme türünü seçiniz'),
          backgroundColor: Color(0xFFE53935),
        ),
      );
      return;
    }

    if (_selectedCouponType == 'İndirim (yüzde)') {
      if (_discountAmountController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lütfen indirim yüzdesini giriniz'),
            backgroundColor: Color(0xFFE53935),
          ),
        );
        return;
      }
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
      final String type = _selectedCouponType == 'İndirim (yüzde)' ? 'DISCOUNT' : 'FREE';

      final Map<String, dynamic> data = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'type': type,
        'status': 1,
      };

      if (_selectedPaymentType == 'Danışman Ödemesi') {
        data['applies_to'] = 'advisor';
      } else if (_selectedPaymentType == 'Eğitim Ödemesi') {
        data['applies_to'] = 'training';
      }

      // Ücretsiz: web ile uyumlu — ayrı data gönderilmez
      if (type == 'DISCOUNT') {
        final amount = double.tryParse(_discountAmountController.text.replaceAll(',', '.'));
        final threshold = num.tryParse(_thresholdController.text.replaceAll(',', '.'))?.toInt() ?? 0;
        if (amount == null || amount <= 0 || amount > 100) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Geçerli bir indirim yüzdesi giriniz (1–100)'),
              backgroundColor: Color(0xFFE53935),
            ),
          );
          return;
        }

        final discountData = <String, dynamic>{
          'amount': amount,
          'threshold': threshold,
          'discount_type': 'percent',
        };
        final maxDisc = num.tryParse(_maxDiscountController.text.replaceAll(',', '.'));
        if (maxDisc != null && maxDisc > 0) {
          discountData['max_discount'] = maxDisc;
        }
        data['data'] = discountData;
      }

      final result = await _repository.createCouponTemplate(data);

      if (mounted) {
        Navigator.pop(context); // Loading'i kapat

        result.fold(
          (failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Kupon şablonu oluşturulamadı: ${failure.message}'),
                backgroundColor: const Color(0xFFE53935),
              ),
            );
          },
          (template) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Kupon şablonu başarıyla oluşturuldu'),
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
            content: Text('Kupon şablonu oluşturulurken hata oluştu: $e'),
            backgroundColor: const Color(0xFFE53935),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final gate = couponAccessGate();
    if (gate != null) return gate;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AdminPanelInAppBar(
        title: 'Yeni Kupon Şablonu',
        onBackPressed: () => Navigator.pop(context),
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
                  
                  // Ad
                  _buildSectionTitle('Ad'),
                  const SizedBox(height: 12),
                  _buildNameField(),
                  const SizedBox(height: 28),
                  
                  // Açıklama
                  _buildSectionTitle('Açıklama'),
                  const SizedBox(height: 12),
                  _buildDescriptionField(),
                  const SizedBox(height: 28),
                  
                  // Kupon Türü
                  _buildSectionTitle('Kupon Türü'),
                  const SizedBox(height: 12),
                  _buildCouponTypeDropdown(),
                  if (_selectedCouponType == null)
                    Padding(
                      padding: const EdgeInsets.only(left: 14, top: 6),
                      child: Text(
                        'Kupon türü seçiniz',
                        style: TextStyle(
                          color: Colors.red.shade400,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  const SizedBox(height: 28),

                  _buildSectionTitle('Kuponun geçerli olduğu ödeme türü'),
                  const SizedBox(height: 12),
                  _buildPaymentTypeDropdown(),
                  if (_selectedPaymentType == null)
                    Padding(
                      padding: const EdgeInsets.only(left: 14, top: 6),
                      child: Text(
                        'Ödeme türü seçiniz',
                        style: TextStyle(
                          color: Colors.red.shade400,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  const SizedBox(height: 28),
                  
                  if (_selectedCouponType == 'İndirim (yüzde)') ...[
                    _buildSectionTitle('İndirim yüzdesi'),
                    const SizedBox(height: 12),
                    _buildDiscountAmountField(),
                    const SizedBox(height: 28),
                    _buildSectionTitle('Minimum sepet tutarı'),
                    const SizedBox(height: 12),
                    _buildThresholdField(),
                    const SizedBox(height: 28),
                    _buildSectionTitle('Maksimum indirim tutarı (₺)'),
                    const SizedBox(height: 12),
                    _buildMaxDiscountField(),
                    const SizedBox(height: 28),
                  ],
                  
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

  Widget _buildNameField() {
    return SizedBox(
      height: _kFieldHeight,
      child: Container(
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
        alignment: Alignment.center,
        child: TextFormField(
          controller: _nameController,
          textAlignVertical: TextAlignVertical.center,
          decoration: InputDecoration(
            hintText: 'Örn: %30 indirim',
            hintStyle: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
            prefixIcon: Container(
              margin: const EdgeInsets.all(10),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFE53935).withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.label_rounded,
                color: Color(0xFFE53935),
                size: 20,
              ),
            ),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: InputBorder.none,
          ),
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1F2937),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Ad giriniz';
            }
            return null;
          },
        ),
      ),
    );
  }

  Widget _buildDescriptionField() {
    return SizedBox(
      height: _kFieldHeight,
      child: Container(
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
        alignment: Alignment.center,
        child: TextFormField(
          controller: _descriptionController,
          maxLines: 1,
          textAlignVertical: TextAlignVertical.center,
          decoration: InputDecoration(
            hintText: 'Açıklama giriniz',
            hintStyle: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
            prefixIcon: Container(
              margin: const EdgeInsets.all(10),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFE53935).withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.description_rounded,
                color: Color(0xFFE53935),
                size: 20,
              ),
            ),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: InputBorder.none,
          ),
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1F2937),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Açıklama giriniz';
            }
            return null;
          },
        ),
      ),
    );
  }

  Widget _buildCouponTypeDropdown() {
    final couponTypes = [
      _CouponTypeOption(value: 'Ücretsiz', label: 'Ücretsiz'),
      _CouponTypeOption(value: 'İndirim (yüzde)', label: 'İndirim (yüzde)'),
    ];

    return GestureDetector(
      onTap: () => _showCouponTypePicker(couponTypes),
      child: Container(
        height: _kFieldHeight,
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE53935).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.category_rounded,
                  color: Color(0xFFE53935),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _selectedCouponType ?? 'Kupon türü seçiniz',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _selectedCouponType != null 
                        ? const Color(0xFF1F2937) 
                        : Colors.grey.shade400,
                  ),
                ),
              ),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Colors.grey.shade400,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCouponTypePicker(List<_CouponTypeOption> options) {
    final TextEditingController searchController = TextEditingController();
    List<_CouponTypeOption> filteredOptions = List.from(options);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.6,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                // Handle
                Container(
                  width: 48,
                  height: 5,
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                
                // Title
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    children: [
                      const Text(
                        'Kupon Türü',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(context),
                        color: Colors.grey.shade600,
                      ),
                    ],
                  ),
                ),
                
                // Search Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: searchController,
                      autofocus: false,
                      decoration: InputDecoration(
                        hintText: 'Ara...',
                        hintStyle: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 15,
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: Colors.grey.shade400,
                          size: 20,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                      onChanged: (value) {
                        setModalState(() {
                          filteredOptions = options.where((option) {
                            return option.label.toLowerCase().contains(value.toLowerCase());
                          }).toList();
                        });
                      },
                    ),
                  ),
                ),
                
                // Options List
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    itemCount: filteredOptions.length,
                    itemBuilder: (context, index) {
                      final option = filteredOptions[index];
                      final isSelected = _selectedCouponType == option.value;
                      
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _selectedCouponType = option.value;
                              if (option.value != 'İndirim (yüzde)') {
                                _discountAmountController.clear();
                                _thresholdController.clear();
                                _maxDiscountController.clear();
                              }
                            });
                            Navigator.pop(context);
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            margin: const EdgeInsets.only(bottom: 4),
                            decoration: BoxDecoration(
                              color: isSelected 
                                  ? const Color(0xFFE53935).withOpacity(0.1)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              border: isSelected
                                  ? Border.all(
                                      color: const Color(0xFFE53935).withOpacity(0.3),
                                      width: 1,
                                    )
                                  : null,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    option.label,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                      color: isSelected 
                                          ? const Color(0xFFE53935)
                                          : const Color(0xFF1F2937),
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  const Icon(
                                    Icons.check_circle_rounded,
                                    color: Color(0xFFE53935),
                                    size: 20,
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
            ),
          );
        },
      ),
    );
  }

  Widget _buildPaymentTypeDropdown() {
    final paymentTypes = [
      _CouponTypeOption(value: 'Danışman Ödemesi', label: 'Danışman Ödemesi'),
      _CouponTypeOption(value: 'Eğitim Ödemesi', label: 'Eğitim Ödemesi'),
    ];

    return GestureDetector(
      onTap: () => _showPaymentTypePicker(paymentTypes),
      child: Container(
        height: _kFieldHeight,
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE53935).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.payment_rounded,
                  color: Color(0xFFE53935),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _selectedPaymentType ?? 'Ödeme türü seçiniz',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _selectedPaymentType != null 
                        ? const Color(0xFF1F2937) 
                        : Colors.grey.shade400,
                  ),
                ),
              ),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Colors.grey.shade400,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPaymentTypePicker(List<_CouponTypeOption> options) {
    final TextEditingController searchController = TextEditingController();
    List<_CouponTypeOption> filteredOptions = List.from(options);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.7,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle
                Container(
                  width: 48,
                  height: 5,
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                
                // Title
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Kuponun geçerli olduğu ödeme türü',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1F2937),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(context),
                        color: Colors.grey.shade600,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
                
                // Search Bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: searchController,
                      autofocus: false,
                      decoration: InputDecoration(
                        hintText: 'Ara...',
                        hintStyle: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 15,
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: Colors.grey.shade400,
                          size: 20,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        isDense: true,
                      ),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                      onChanged: (value) {
                        setModalState(() {
                          filteredOptions = options.where((option) {
                            return option.label.toLowerCase().contains(value.toLowerCase());
                          }).toList();
                        });
                      },
                    ),
                  ),
                ),
                
                // Options List
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    itemCount: filteredOptions.length,
                    itemBuilder: (context, index) {
                      final option = filteredOptions[index];
                      final isSelected = _selectedPaymentType == option.value;
                      
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _selectedPaymentType = option.value;
                            });
                            Navigator.pop(context);
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            margin: const EdgeInsets.only(bottom: 4),
                            decoration: BoxDecoration(
                              color: isSelected 
                                  ? const Color(0xFFE53935).withOpacity(0.1)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              border: isSelected
                                  ? Border.all(
                                      color: const Color(0xFFE53935).withOpacity(0.3),
                                      width: 1,
                                    )
                                  : null,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    option.label,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                      color: isSelected 
                                          ? const Color(0xFFE53935)
                                          : const Color(0xFF1F2937),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (isSelected)
                                  const Icon(
                                    Icons.check_circle_rounded,
                                    color: Color(0xFFE53935),
                                    size: 20,
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
            ),
          );
        },
      ),
    );
  }

  Widget _buildDiscountAmountField() {
    return SizedBox(
      height: _kFieldHeight,
      child: Container(
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
        alignment: Alignment.center,
        child: TextFormField(
          controller: _discountAmountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textAlignVertical: TextAlignVertical.center,
          decoration: InputDecoration(
            hintText: 'Örn: 10',
            hintStyle: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
            prefixIcon: Container(
              margin: const EdgeInsets.all(10),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFE53935).withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.percent_rounded,
                color: Color(0xFFE53935),
                size: 20,
              ),
            ),
            suffixText: '%',
            suffixStyle: const TextStyle(
              color: Color(0xFF1F2937),
              fontWeight: FontWeight.w600,
            ),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: InputBorder.none,
          ),
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1F2937),
          ),
          validator: (value) {
            if (_selectedCouponType == 'İndirim (yüzde)' && (value == null || value.isEmpty)) {
              return 'İndirim yüzdesi giriniz';
            }
            final amount = double.tryParse((value ?? '').replaceAll(',', '.'));
            if (value != null && value.isNotEmpty && (amount == null || amount <= 0 || amount > 100)) {
              return '1–100 arası giriniz';
            }
            return null;
          },
        ),
      ),
    );
  }

  Widget _buildThresholdField() {
    return SizedBox(
      height: _kFieldHeight,
      child: Container(
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
        alignment: Alignment.center,
        child: TextFormField(
          controller: _thresholdController,
          keyboardType: TextInputType.number,
          textAlignVertical: TextAlignVertical.center,
          decoration: InputDecoration(
            hintText: 'Örn: 500',
            hintStyle: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
            prefixIcon: Container(
              margin: const EdgeInsets.all(10),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFE53935).withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.attach_money_rounded,
                color: Color(0xFFE53935),
                size: 20,
              ),
            ),
            suffixText: '₺',
            suffixStyle: const TextStyle(
              color: Color(0xFF1F2937),
              fontWeight: FontWeight.w600,
            ),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: InputBorder.none,
          ),
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1F2937),
          ),
        ),
      ),
    );
  }

  Widget _buildMaxDiscountField() {
    return SizedBox(
      height: _kFieldHeight,
      child: Container(
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
        alignment: Alignment.center,
        child: TextFormField(
          controller: _maxDiscountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textAlignVertical: TextAlignVertical.center,
          decoration: InputDecoration(
            hintText: 'Opsiyonel',
            hintStyle: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
            prefixIcon: Container(
              margin: const EdgeInsets.all(10),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFE53935).withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.savings_rounded,
                color: Color(0xFFE53935),
                size: 20,
              ),
            ),
            suffixText: '₺',
            suffixStyle: const TextStyle(
              color: Color(0xFF1F2937),
              fontWeight: FontWeight.w600,
            ),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: InputBorder.none,
          ),
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1F2937),
          ),
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
                    'Oluştur',
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

