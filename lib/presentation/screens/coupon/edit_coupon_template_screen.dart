import 'package:flutter/material.dart';
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
  static const double _kFieldHeight = 52.0;

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
    _appliesToSelection = widget.template.appliesTo ?? _kPaymentUnset;
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
      backgroundColor: Colors.white,
      appBar: AdminPanelInAppBar(
        title: 'Kupon Şablonu Düzenle',
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
                  
                  _buildSectionTitle('Kupon Türü'),
                  const SizedBox(height: 12),
                  _buildTypeDropdown(),
                  const SizedBox(height: 28),

                  _buildSectionTitle('Kuponun geçerli olduğu ödeme türü'),
                  const SizedBox(height: 12),
                  _buildAppliesToDropdown(),
                  const SizedBox(height: 28),
                  
                  if (_selectedType == 'DISCOUNT') ...[
                    _buildSectionTitle('İndirim yüzdesi'),
                    const SizedBox(height: 12),
                    _buildDiscountPercentField(),
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
                  
                  _buildSectionTitle('Durum'),
                  const SizedBox(height: 12),
                  _buildStatusDropdown(),
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

  Widget _buildTypeDropdown() {
    return SizedBox(
      height: _kFieldHeight,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8),
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
        child: DropdownButtonFormField<String>(
          value: _selectedType,
          isExpanded: true,
          menuMaxHeight: 280,
          itemHeight: 48,
          decoration: const InputDecoration(
            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
            border: InputBorder.none,
            isDense: true,
          ),
          hint: Text(
            'Kupon türü seçiniz',
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Colors.grey.shade400,
            size: 24,
          ),
          dropdownColor: Colors.white,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1F2937),
          ),
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
        ),
      ),
    );
  }

  Widget _buildDiscountPercentField() {
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
            hintText: 'Örn: 30',
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

  Widget _buildAppliesToDropdown() {
    return SizedBox(
      height: _kFieldHeight,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8),
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
        child: DropdownButtonFormField<String>(
          value: _appliesToSelection,
          isExpanded: true,
          menuMaxHeight: 280,
          itemHeight: 48,
          decoration: const InputDecoration(
            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
            border: InputBorder.none,
            isDense: true,
          ),
          hint: Text(
            'Ödeme türü seçiniz',
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Colors.grey.shade400,
            size: 24,
          ),
          dropdownColor: Colors.white,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1F2937),
          ),
          items: [
            DropdownMenuItem(
              value: _kPaymentUnset,
              child: Text(
                'Ödeme türü seçiniz',
                style: TextStyle(color: Colors.grey.shade500),
              ),
            ),
            const DropdownMenuItem(value: 'advisor', child: Text('Danışman Ödemesi')),
            const DropdownMenuItem(value: 'training', child: Text('Eğitim Ödemesi')),
          ],
          onChanged: (value) {
            if (value == null) return;
            setState(() => _appliesToSelection = value);
          },
        ),
      ),
    );
  }

  Widget _buildStatusDropdown() {
    return SizedBox(
      height: _kFieldHeight,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8),
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
        child: DropdownButtonFormField<int>(
          value: _selectedStatus,
          isExpanded: true,
          menuMaxHeight: 240,
          itemHeight: 48,
          decoration: const InputDecoration(
            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
            border: InputBorder.none,
            isDense: true,
          ),
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Colors.grey.shade400,
            size: 24,
          ),
          dropdownColor: Colors.white,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1F2937),
          ),
          items: const [
            DropdownMenuItem(value: 1, child: Text('Aktif')),
            DropdownMenuItem(value: 0, child: Text('Pasif')),
          ],
          onChanged: (value) {
            setState(() {
              _selectedStatus = value ?? 1;
            });
          },
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
                    'Güncelle',
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

