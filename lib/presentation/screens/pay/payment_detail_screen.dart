import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zecorner/infrastructure/coupon/coupon_repository.dart';
import 'package:zecorner/models/coupon/coupon_model.dart';

class PaymentDetailScreen extends StatefulWidget {
  final int? contactNo;
  final String? contactName;
  
  const PaymentDetailScreen({
    Key? key,
    this.contactNo,
    this.contactName,
  }) : super(key: key);

  @override
  State<PaymentDetailScreen> createState() => _PaymentDetailScreenState();
}

class _PaymentDetailScreenState extends State<PaymentDetailScreen> {
  // Repository
  final CouponRepository _couponRepository = CouponRepository();
  
  // Payment details - Original amounts
  final double _baseAmount = 7500.00;
  final double _kdvRate = 0.20;
  double get _kdvAmount => _baseAmount * _kdvRate;
  double get _totalAmount => _baseAmount + _kdvAmount;
  
  // Coupon
  String? _selectedCouponId;
  CouponModel? _selectedCoupon;
  List<CouponModel> _coupons = [];
  bool _isLoadingCoupons = true;
  String? _couponError;
  
  // Discounted amounts (calculated when coupon selected)
  double get _discountedBaseAmount {
    if (_selectedCoupon == null) return _baseAmount;
    
    if (_selectedCoupon!.isFree) {
      return 0; // Ücretsiz kupon
    }
    
    if (_selectedCoupon!.isDiscount && _selectedCoupon!.discountData != null) {
      if (_selectedCoupon!.discountData!.discountType == 'percent') {
        // Yüzde indirim
        return _baseAmount * (1 - _selectedCoupon!.discountData!.amount / 100);
      } else {
        // Sabit tutar indirim
        return (_baseAmount - _selectedCoupon!.discountData!.amount).clamp(0, _baseAmount);
      }
    }
    return _baseAmount;
  }
  
  double get _discountedKdvAmount => _discountedBaseAmount * _kdvRate;
  double get _discountedTotalAmount => _discountedBaseAmount + _discountedKdvAmount;
  bool get _hasCouponApplied => _selectedCoupon != null;
  
  // Payment method
  String _selectedPaymentMethod = 'Havale/EFT';
  final List<String> _paymentMethods = ['Havale/EFT', 'Kredi Kartı'];
  
  // Bank info
  final String _companyName = 'HAUSBERRY GAYRİMENKUL VE BİLGİ TEKNOLOJİLERİ AŞ.';
  final String _bankName = 'FİNANSBANK / KAYSERİ TİCARİ ŞUBE';
  final String _iban = 'TR17 0011 1000 0000 0127 0057 94';
  
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadCoupons();
  }

  Future<void> _loadCoupons() async {
    setState(() {
      _isLoadingCoupons = true;
      _couponError = null;
    });

    final result = await _couponRepository.getCoupons(
      contactNo: widget.contactNo,
    );

    if (mounted) {
      result.fold(
        (failure) {
          setState(() {
            _isLoadingCoupons = false;
            _couponError = failure.message;
            _coupons = [];
          });
        },
        (coupons) {
          // Filtreleme: 
          // 1. Aktif ve kullanılabilir olmalı
          // 2. applies_to null olmamalı (sadece belirli bir tipe atanmış kuponlar)
          final filteredCoupons = coupons.where((c) => 
            c.isUsable && c.isActive && c.appliesTo != null && c.appliesTo!.isNotEmpty
          ).toList();
          
          print('🎫 ${coupons.length} kupondan ${filteredCoupons.length} tanesi gösterilecek');
          
          print('✅ Filtreleme sonrası ${filteredCoupons.length} kupon gösterilecek');
          
          setState(() {
            _isLoadingCoupons = false;
            _coupons = filteredCoupons;
          });
        },
      );
    }
  }

  void _onCouponSelected(String? couponId) {
    setState(() {
      _selectedCouponId = couponId;
      if (couponId != null) {
        _selectedCoupon = _coupons.firstWhere(
          (c) => c.id == couponId,
          orElse: () => _coupons.first,
        );
      } else {
        _selectedCoupon = null;
      }
    });
  }

  double get _finalAmount => _hasCouponApplied ? _discountedTotalAmount : _totalAmount;

  Future<void> _submitPayment() async {
    setState(() => _isSubmitting = true);
    
    await Future.delayed(const Duration(seconds: 2));
    
    setState(() => _isSubmitting = false);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('Ödeme bildirimi başarıyla gönderildi!'),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
      Navigator.pop(context, true);
    }
  }

  void _copyIban() {
    Clipboard.setData(ClipboardData(text: _iban.replaceAll(' ', '')));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: const [
            Icon(Icons.copy, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text('IBAN kopyalandı!'),
          ],
        ),
        backgroundColor: const Color(0xFF3B82F6),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // Modern App Bar
          _buildSliverAppBar(),
          
          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              child: Column(
                children: [
                  // Amount Card with Gradient
                  _buildAmountCard(),
                  
                  const SizedBox(height: 16),
                  
                  // Coupon Section
                  _buildModernCouponSection(),
                  
                  const SizedBox(height: 16),
                  
                  // Payment Method
                  _buildModernPaymentMethod(),
                  
                  const SizedBox(height: 16),
                  
                  // Info Card
                  _buildInfoCard(),
                  
                  const SizedBox(height: 16),
                  
                  // Bank Details
                  _buildModernBankDetails(),
                ],
              ),
            ),
          ),
        ],
      ),
      // Bottom Action Bar
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: const Color(0xFFE53935),
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: const Text(
          'Ödeme Yap',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFE53935), Color(0xFFC62828)],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -30,
                top: -30,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              ),
              Positioned(
                left: -20,
                bottom: -40,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.05),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAmountCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Color(0xFFFAFAFA)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFFEEEEEE), width: 1),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE53935).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.receipt_long_rounded,
                    color: Color(0xFFE53935),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Text(
                    'Danışman Kayıt Ücreti',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Fee Details - Original Amounts
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildModernFeeRow(
                  'Danışman Kayıt Ücreti (KDV Hariç)',
                  _baseAmount,
                  icon: Icons.person_add_alt_1_rounded,
                ),
                const SizedBox(height: 14),
                _buildModernFeeRow(
                  'KDV (%${(_kdvRate * 100).toInt()})',
                  _kdvAmount,
                  icon: Icons.percent_rounded,
                ),
                
                const SizedBox(height: 20),
                
                // Original Total Section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFE53935).withOpacity(0.08),
                        const Color(0xFFE53935).withOpacity(0.03),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE53935),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.payments_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _hasCouponApplied ? 'Toplam' : 'Toplam Tutar',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF374151),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${_totalAmount.toStringAsFixed(2)} ₺',
                        style: TextStyle(
                          fontSize: _hasCouponApplied ? 18 : 24,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFFE53935),
                          decoration: _hasCouponApplied ? TextDecoration.lineThrough : null,
                          decorationColor: const Color(0xFFE53935),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Kupon Uygulandı Section - Only show when coupon is applied
          if (_hasCouponApplied) ...[
            Container(
              margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF10B981).withOpacity(0.08),
                    const Color(0xFF10B981).withOpacity(0.03),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF10B981).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.check_circle_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Kupon Uygulandı',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Discounted Base Amount
                  _buildDiscountedFeeRow(
                    'Danışman Kayıt Ücreti (KDV Hariç)',
                    _discountedBaseAmount,
                  ),
                  const SizedBox(height: 12),
                  
                  // Discounted KDV
                  _buildDiscountedFeeRow(
                    'KDV (%${(_kdvRate * 100).toInt()})',
                    _discountedKdvAmount,
                  ),
                  
                  const SizedBox(height: 16),
                  const Divider(color: Color(0xFF10B981), thickness: 0.5),
                  const SizedBox(height: 16),
                  
                  // Discounted Total
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Toplam',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      Text(
                        '${_discountedTotalAmount.toStringAsFixed(2)} ₺',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildModernFeeRow(String label, double amount, {IconData? icon, bool isDiscount = false}) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(
            icon,
            size: 18,
            color: isDiscount ? const Color(0xFF10B981) : Colors.grey[500],
          ),
          const SizedBox(width: 10),
        ],
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 15,
              color: isDiscount ? const Color(0xFF10B981) : const Color(0xFF6B7280),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          '${isDiscount ? '-' : ''}${amount.abs().toStringAsFixed(2)} ₺',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDiscount ? const Color(0xFF10B981) : const Color(0xFF1F2937),
          ),
        ),
      ],
    );
  }
  
  Widget _buildDiscountedFeeRow(String label, double amount) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '${amount.toStringAsFixed(2)} ₺',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1F2937),
          ),
        ),
      ],
    );
  }

  Widget _buildModernCouponSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.local_offer_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Kupon Kodu',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F2937),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Opsiyonel',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          _isLoadingCoupons
              ? Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 12),
                      Text('Kuponlar yükleniyor...', style: TextStyle(color: Color(0xFF6B7280))),
                    ],
                  ),
                )
              : _couponError != null
                  ? Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFFCA5A5)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _couponError!,
                              style: const TextStyle(color: Color(0xFFDC2626), fontSize: 14),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.refresh, color: Color(0xFFDC2626)),
                            onPressed: _loadCoupons,
                          ),
                        ],
                      ),
                    )
                  : Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedCouponId,
                          hint: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              _coupons.isEmpty ? 'Kullanılabilir kupon yok' : 'Kupon seçiniz...',
                              style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 15),
                            ),
                          ),
                          isExpanded: true,
                          icon: const Padding(
                            padding: EdgeInsets.only(right: 16),
                            child: Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF6B7280)),
                          ),
                          dropdownColor: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          items: [
                            const DropdownMenuItem<String>(
                              value: null,
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                child: Text('Kupon kullanma', style: TextStyle(color: Color(0xFF6B7280))),
                              ),
                            ),
                            ..._coupons.map((coupon) => DropdownMenuItem<String>(
                              value: coupon.id,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Row(
                                  children: [
                                    Icon(
                                      coupon.isFree ? Icons.card_giftcard : Icons.confirmation_number_rounded,
                                      size: 18,
                                      color: coupon.isFree ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        coupon.displayDescription,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (coupon.amount > 0)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE5E7EB),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          '${coupon.amount} hak',
                                          style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            )).toList(),
                          ],
                          onChanged: _coupons.isEmpty ? null : _onCouponSelected,
                        ),
                      ),
                    ),
        ],
      ),
    );
  }

  Widget _buildModernPaymentMethod() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.credit_card_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Ödeme Yöntemi',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedPaymentMethod,
                isExpanded: true,
                icon: const Padding(
                  padding: EdgeInsets.only(right: 16),
                  child: Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF6B7280)),
                ),
                dropdownColor: Colors.white,
                borderRadius: BorderRadius.circular(14),
                items: _paymentMethods.map((method) => DropdownMenuItem<String>(
                  value: method,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Icon(
                          method == 'Havale/EFT' ? Icons.account_balance_rounded : Icons.credit_card,
                          size: 18,
                          color: const Color(0xFF3B82F6),
                        ),
                        const SizedBox(width: 10),
                        Text(method),
                      ],
                    ),
                  ),
                )).toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _selectedPaymentMethod = value);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFEF3C7),
            const Color(0xFFFEF9E7).withOpacity(0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFCD34D).withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.info_rounded, color: Color(0xFFD97706), size: 20),
              ),
              const SizedBox(width: 10),
              const Text(
                'Önemli Bilgi',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFB45309),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            '• Açıklama kısmına "${widget.contactNo ?? "fatura numaranızı"}" yazmayı unutmayın.\n'
            '• ${_finalAmount.toStringAsFixed(2)} TL tutarı aşağıdaki IBAN\'a gönderin.\n'
            '• "Ödeme Bildirimi Yap" butonuna basarak işlemi tamamlayın.',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF92400E),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernBankDetails() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6))),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF10B981), Color(0xFF059669)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.account_balance_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Banka Bilgileri',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ],
            ),
          ),
          
          // Bank Info
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _companyName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _bankName,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // IBAN Box
                GestureDetector(
                  onTap: _copyIban,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF10B981).withOpacity(0.08),
                          const Color(0xFF10B981).withOpacity(0.03),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF10B981).withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'TL',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            _iban,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1F2937),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.copy_rounded,
                            size: 18,
                            color: Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 10),
                
                Center(
                  child: Text(
                    'IBAN\'ı kopyalamak için dokunun',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).padding.bottom + 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          // Cancel Button
          Expanded(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
              ),
              child: const Text(
                'İptal',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6B7280),
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Submit Button
          Expanded(
            flex: 2,
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE53935), Color(0xFFC62828)],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFE53935).withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.send_rounded, size: 20, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            'Ödeme Bildirimi Yap',
                            style: TextStyle(
                              fontSize: 16, 
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
