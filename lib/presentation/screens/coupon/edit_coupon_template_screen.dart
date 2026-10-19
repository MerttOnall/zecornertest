import 'package:flutter/material.dart';
import 'package:zecorner/core/widgets/keyboard_dismiss.dart';
import 'package:zecorner/presentation/widgets/admin-panel/admin_panel_in_appbar.dart';
import 'package:zecorner/infrastructure/coupon/coupon_api_repository.dart';
import 'package:zecorner/models/coupon/coupon_template_model.dart';
import 'package:zecorner/presentation/screens/coupon/coupon_admin_guard.dart';

class EditCouponTemplateScreen extends StatefulWidget {
  final CouponTemplateModel template;

  const EditCouponTemplateScreen({Key? key, required this.template}) : super(key: key);

  @override
  State<EditCouponTemplateScreen> createState() => _EditCouponTemplateScreenState();
}

class _EditCouponTemplateScreenState extends State<EditCouponTemplateScreen>
    with CouponAdminGuard {
  static const Color _primary = Color(0xFFE53935);
  static const Color _text = Color(0xFF1F2937);

  final _formKey = GlobalKey<FormState>();
  
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _discountAmountController;
  late final TextEditingController _thresholdController;
  late final TextEditingController _maxDiscountController;
  
  String? _selectedType;
  static const String _kPaymentUnset = '__none__';
  String _appliesToSelection = _kPaymentUnset;
  int _selectedStatus = 1;
  
  // Repository
  final CouponApiRepository _repository = CouponApiRepository();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.template.name);
    _descriptionController = TextEditingController(text: widget.template.description);
    _selectedType = widget.template.type.toUpperCase() == 'DISCOUNT' ? 'DISCOUNT' : 'FREE';
    final appliesTo = widget.template.appliesTo;
    _appliesToSelection = (appliesTo == 'advisor' || appliesTo == 'training')
        ? appliesTo!
        : _kPaymentUnset;
    _selectedStatus = widget.template.status;
    
    if (widget.template.type.toUpperCase() == 'DISCOUNT' && widget.template.data != null) {
      final d = widget.template.data!;
      _discountAmountController = TextEditingController(
        text: d['amount']?.toString() ?? '',
      );
      _thresholdController = TextEditingController(
        text: d['threshold']?.toString() ?? '0',
      );
      _maxDiscountController = TextEditingController(
        text: d['max_discount']?.toString() ?? '',
      );
    } else {
      _discountAmountController = TextEditingController();
      _thresholdController = TextEditingController(text: '0');
      _maxDiscountController = TextEditingController();
    }
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

    if (_selectedType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen kupon türü seçiniz'),
          backgroundColor: Color(0xFFE53935),
        ),
      );
      return;
    }

    if (_appliesToSelection == _kPaymentUnset) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen kuponun geçerli olduğu ödeme türünü seçiniz'),
          backgroundColor: Color(0xFFE53935),
        ),
      );
      return;
    }

    if (_selectedType == 'DISCOUNT') {
      if (_discountAmountController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lütfen indirim miktarını giriniz'),
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
      final Map<String, dynamic> data = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'type': _selectedType!,
        'status': _selectedStatus,
        'applies_to': _appliesToSelection,
      };

      if (_selectedType == 'DISCOUNT') {
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

      final result = await _repository.updateCouponTemplate(widget.template.id, data);

      if (mounted) {
        Navigator.pop(context); // Loading'i kapat

        result.fold(
          (failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Kupon şablonu güncellenemedi: ${failure.message}'),
                backgroundColor: const Color(0xFFE53935),
              ),
            );
          },
          (template) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Kupon şablonu başarıyla güncellendi'),
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
            content: Text('Kupon şablonu güncellenirken hata oluştu: $e'),
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
      backgroundColor: const Color(0xFFF7F7F8),
      appBar: AdminPanelInAppBar(
        title: 'Kupon Şablonu Düzenle',
        onBackPressed: () => Navigator.pop(context),
      ),
      body: KeyboardDismiss(
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: EdgeInsets.fromLTRB(
                      16,
                      16,
                      16,
                      16 + MediaQuery.viewInsetsOf(context).bottom,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildSectionTitle('Ad'),
                        const SizedBox(height: 8),
                        _buildNameField(),
                        const SizedBox(height: 18),
                        _buildSectionTitle('Açıklama'),
                        const SizedBox(height: 8),
                        _buildDescriptionField(),
                        const SizedBox(height: 18),
                        _buildSectionTitle('Kupon Türü'),
                        const SizedBox(height: 8),
                        _buildTypeDropdown(),
                        const SizedBox(height: 18),
                        _buildSectionTitle('Kuponun geçerli olduğu ödeme türü'),
                        const SizedBox(height: 8),
                        _buildAppliesToDropdown(),
                        if (_selectedType == 'DISCOUNT') ...[
                          const SizedBox(height: 18),
                          _buildSectionTitle('İndirim yüzdesi'),
                          const SizedBox(height: 8),
                          _buildDiscountPercentField(),
                          const SizedBox(height: 18),
                          _buildSectionTitle('Minimum sepet tutarı'),
                          const SizedBox(height: 8),
                          _buildThresholdField(),
                          const SizedBox(height: 18),
                          _buildSectionTitle('Maksimum indirim tutarı (₺)'),
                          const SizedBox(height: 8),
                          _buildMaxDiscountField(),
                        ],
                        const SizedBox(height: 18),
                        _buildSectionTitle('Durum'),
                        const SizedBox(height: 8),
                        _buildStatusDropdown(),
                      ],
                    ),
                  ),
                ),
                _buildActionButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration({
    required IconData icon,
    String? hint,
    String? suffix,
  }) {
    const radius = BorderRadius.all(Radius.circular(14));
    final border = OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(color: _primary.withOpacity(0.22), width: 1.2),
    );
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: Colors.grey.shade400,
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
      prefixIcon: Padding(
        padding: const EdgeInsets.only(left: 12, right: 4),
        child: Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: _primary, size: 18),
        ),
      ),
      prefixIconConstraints: const BoxConstraints(minWidth: 58, minHeight: 52),
      suffixText: suffix,
      suffixStyle: const TextStyle(
        color: _text,
        fontWeight: FontWeight.w700,
        fontSize: 15,
      ),
      isDense: true,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      border: border,
      enabledBorder: border,
      focusedBorder: const OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: _primary, width: 1.4),
      ),
      errorBorder: const OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: _primary, width: 1.2),
      ),
      focusedErrorBorder: const OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: _primary, width: 1.4),
      ),
      errorStyle: const TextStyle(fontSize: 12, height: 1.2),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: _primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _text,
              height: 1.2,
            ),
          ),
        ),
      ],
    );
  }

  TextStyle get _fieldTextStyle => const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: _text,
      );

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      textAlignVertical: TextAlignVertical.center,
      style: _fieldTextStyle,
      decoration: _fieldDecoration(
        icon: Icons.label_rounded,
        hint: 'Örn: %30 indirim',
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Ad giriniz';
        }
        return null;
      },
    );
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      minLines: 2,
      maxLines: 3,
      textAlignVertical: TextAlignVertical.top,
      style: _fieldTextStyle,
      decoration: _fieldDecoration(
        icon: Icons.description_rounded,
        hint: 'Açıklama giriniz',
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Açıklama giriniz';
        }
        return null;
      },
    );
  }

  Widget _buildTypeDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedType,
      isExpanded: true,
      menuMaxHeight: 280,
      icon: Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey.shade500),
      dropdownColor: Colors.white,
      style: _fieldTextStyle,
      decoration: _fieldDecoration(icon: Icons.local_offer_rounded),
      items: const [
        DropdownMenuItem(value: 'FREE', child: Text('Ücretsiz')),
        DropdownMenuItem(value: 'DISCOUNT', child: Text('İndirim (yüzde)')),
      ],
      onChanged: (value) {
        setState(() {
          _selectedType = value;
          if (value == 'FREE') {
            _discountAmountController.clear();
            _thresholdController.clear();
            _maxDiscountController.clear();
          }
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Kupon türü seçiniz';
        }
        return null;
      },
    );
  }

  Widget _buildDiscountPercentField() {
    return TextFormField(
      controller: _discountAmountController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textAlignVertical: TextAlignVertical.center,
      style: _fieldTextStyle,
      decoration: _fieldDecoration(
        icon: Icons.percent_rounded,
        hint: 'Örn: 30',
        suffix: '%',
      ),
      validator: (value) {
        if (_selectedType != 'DISCOUNT') return null;
        if (value == null || value.isEmpty) {
          return 'İndirim yüzdesi giriniz';
        }
        final amount = double.tryParse(value.replaceAll(',', '.'));
        if (amount == null || amount <= 0 || amount > 100) {
          return '1–100 arası giriniz';
        }
        return null;
      },
    );
  }

  Widget _buildThresholdField() {
    return TextFormField(
      controller: _thresholdController,
      keyboardType: TextInputType.number,
      textAlignVertical: TextAlignVertical.center,
      style: _fieldTextStyle,
      decoration: _fieldDecoration(
        icon: Icons.shopping_bag_outlined,
        hint: 'Örn: 500',
        suffix: '₺',
      ),
    );
  }

  Widget _buildMaxDiscountField() {
    return TextFormField(
      controller: _maxDiscountController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textAlignVertical: TextAlignVertical.center,
      style: _fieldTextStyle,
      decoration: _fieldDecoration(
        icon: Icons.savings_outlined,
        hint: 'Opsiyonel',
        suffix: '₺',
      ),
    );
  }

  Widget _buildAppliesToDropdown() {
    return DropdownButtonFormField<String>(
      value: _appliesToSelection,
      isExpanded: true,
      menuMaxHeight: 280,
      icon: Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey.shade500),
      dropdownColor: Colors.white,
      style: _fieldTextStyle,
      decoration: _fieldDecoration(icon: Icons.payments_outlined),
      items: [
        DropdownMenuItem(
          value: _kPaymentUnset,
          child: Text(
            'Ödeme türü seçiniz',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const DropdownMenuItem(value: 'advisor', child: Text('Danışman Ödemesi')),
        const DropdownMenuItem(value: 'training', child: Text('Eğitim Ödemesi')),
      ],
      onChanged: (value) {
        if (value == null) return;
        setState(() => _appliesToSelection = value);
      },
    );
  }

  Widget _buildStatusDropdown() {
    return DropdownButtonFormField<int>(
      value: _selectedStatus,
      isExpanded: true,
      menuMaxHeight: 240,
      icon: Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey.shade500),
      dropdownColor: Colors.white,
      style: _fieldTextStyle,
      decoration: _fieldDecoration(icon: Icons.toggle_on_outlined),
      items: const [
        DropdownMenuItem(value: 1, child: Text('Aktif')),
        DropdownMenuItem(value: 0, child: Text('Pasif')),
      ],
      onChanged: (value) {
        setState(() {
          _selectedStatus = value ?? 1;
        });
      },
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => Navigator.pop(context),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  height: 50,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade300, width: 1.2),
                  ),
                  child: const Text(
                    'İptal',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _text,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _handleSubmit,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  height: 50,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _primary,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Text(
                    'Güncelle',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

