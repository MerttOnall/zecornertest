import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:zecorner/core/location/nominatim_geocoding.dart';
import 'package:image_picker/image_picker.dart';
import 'package:zecorner/models/myoffice/myoffice_api_model.dart';

class MyeditOfficeScreen extends StatefulWidget {
  const MyeditOfficeScreen({super.key});

  @override
  State<MyeditOfficeScreen> createState() => _MyeditOfficeScreenState();
}

class _MyeditOfficeScreenState extends State<MyeditOfficeScreen> {
  static const Color _brand = Color(0xFFEE2E24);
  static const Color _ink = Color(0xFF1C2430);
  static const Color _muted = Color(0xFF6B7280);
  static const Color _fill = Color(0xFFF5F6F8);
  static const Color _line = Color(0xFFE6E9EF);
  static const Color _page = Color(0xFFF3F4F7);

  bool _isActive = true;

  // Controller'lar
  late TextEditingController _companyNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _taxNoController;
  late TextEditingController _taxOfficeController;
  late TextEditingController _addressController;

  String? _selectedPersonType;
  String? _selectedRegion;
  String? _selectedCity;
  String? _selectedDistrict;
  String? _selectedNeighborhood;
  
  // Media
  File? _selectedOfficePhoto;
  File? _selectedLogo;
  final ImagePicker _imagePicker = ImagePicker();
  // Dynamic lists for dropdowns
  List<String> _cityList = ["İstanbul", "Ankara", "İzmir"];
  List<String> _districtList = ["Kadıköy", "Beşiktaş", "Üsküdar"];
  List<String> _neighborhoodList = ["Caferağa", "Göztepe", "Fenerbahçe"];

  // Map state
  final MapController _mapController = MapController();
  LatLng _mapCenter = LatLng(39.9334, 32.8597); // Ankara default
  double _mapZoom = 10.0;
  bool _isSatelliteView = false;
  LatLng? _selectedLocation;
  Marker? _locationMarker;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    String companyName = "";
    String email = "";
    String phone = "";
    String taxNo = "";
    String taxOffice = "";
    String address = "";
    String? personType;
    bool isActive = true;
    String? city;
    String? district;
    String? neighborhood;
    double? latitude;
    double? longitude;
    
    if (args != null) {
      if (args is MyOfficeApiModel) {
        // Direct MyOfficeApiModel
        companyName = args.title;
        email = args.eMail;
        phone = args.tel;
        taxNo = args.taxNo;
        taxOffice = args.taxOffice;
        address = args.address.address;
        personType = args.typeDescription;
        isActive = args.isActive;
        city = args.address.uavtAddress.provinceName;
        district = args.address.uavtAddress.districtName;
        neighborhood = args.address.uavtAddress.quarterName;
        latitude = args.address.lat;
        longitude = args.address.lon;
      } else if (args is Map) {
        companyName = args['office'] ?? args['companyName'] ?? "";
        email = args['email'] ?? "";
        phone = args['phone'] ?? "";
        taxNo = args['vn'] ?? args['taxNo'] ?? "";
        taxOffice = args['vd'] ?? args['taxOffice'] ?? "";
        address = args['address'] ?? "";
        personType = args['userType'] ?? args['personType'];
        isActive = args['isActive'] ?? true;
        city = args['city'] ?? args['il'];
        district = args['district'] ?? args['ilce'];
        neighborhood = args['neighborhood'] ?? args['mahalle'];
        latitude = args['latitude'] ?? args['lat'];
        longitude = args['longitude'] ?? args['lng'] ?? args['lon'];
      } else if (args.runtimeType.toString().contains('OfficePerson')) {
        final officePerson = args as dynamic;
        try {
          companyName = officePerson.office ?? officePerson.fullName ?? "";
        } catch (_) {}
        try {
          email = officePerson.email ?? "";
        } catch (_) {}
        try {
          phone = officePerson.phone ?? "";
        } catch (_) {}
        try {
          taxNo = officePerson.personNo ?? "";
        } catch (_) {}
        try {
          taxOffice = officePerson.office ?? "";
        } catch (_) {}
        try {
          address = officePerson.address ?? "";
        } catch (_) {}
        try {
          personType = officePerson.userType;
        } catch (_) {}
        try {
          isActive = officePerson.isActive ?? true;
        } catch (_) {}
        try {
          city = officePerson.city ?? officePerson.il;
        } catch (_) {}
        try {
          district = officePerson.district ?? officePerson.ilce;
        } catch (_) {}
        try {
          neighborhood = officePerson.neighborhood ?? officePerson.mahalle;
        } catch (_) {}
        try {
          latitude = officePerson.latitude ?? officePerson.lat;
        } catch (_) {}
        try {
          longitude = officePerson.longitude ?? officePerson.lng ?? officePerson.lon;
        } catch (_) {}
      }
    }
    _companyNameController = TextEditingController(text: companyName);
    _emailController = TextEditingController(text: email);
    _phoneController = TextEditingController(text: phone);
    _taxNoController = TextEditingController(text: taxNo);
    _taxOfficeController = TextEditingController(text: taxOffice);
    _addressController = TextEditingController(text: address);
    _selectedPersonType = personType;
    _isActive = isActive;
    
    // Set location dropdowns if available and add to lists if not present
    if (city != null && city.isNotEmpty) {
      _selectedCity = city;
      if (!_cityList.contains(city)) {
        _cityList.insert(0, city);
      }
    }
    if (district != null && district.isNotEmpty) {
      _selectedDistrict = district;
      if (!_districtList.contains(district)) {
        _districtList.insert(0, district);
      }
    }
    if (neighborhood != null && neighborhood.isNotEmpty) {
      _selectedNeighborhood = neighborhood;
      if (!_neighborhoodList.contains(neighborhood)) {
        _neighborhoodList.insert(0, neighborhood);
      }
    }
    
    // Initialize map location
    _initializeMapLocation(latitude, longitude, city, district, neighborhood, address);
  }
  
  void _initializeMapLocation(double? lat, double? lng, String? city, String? district, String? neighborhood, String? address) {
    // If we have latitude and longitude, use them directly
    if (lat != null && lng != null) {
      final location = LatLng(lat, lng);
      setState(() {
        _mapCenter = location;
        _selectedLocation = location;
        _mapZoom = _selectedNeighborhood != null
            ? 15.0
            : _selectedDistrict != null
                ? 13.0
                : 11.0;
        _locationMarker = Marker(
          point: location,
          width: 40,
          height: 40,
          child: const Icon(
            Icons.location_on,
            color: Color(0xFFE53935),
            size: 40,
          ),
        );
      });
      // Wait for FlutterMap to render before using MapController
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _mapController.move(location, _selectedNeighborhood != null ? 15.0 : _selectedDistrict != null ? 13.0 : 11.0);
        }
      });
    } else {
      // Otherwise, try to geocode from address information
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _updateMapLocation();
        }
      });
    }
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _taxNoController.dispose();
    _taxOfficeController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget _fieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 7),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Color(0xFF3A4352),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({String? hint}) {
    const radius = BorderRadius.all(Radius.circular(14));
    const idle = BorderSide(color: _line);
    const focus = BorderSide(color: _brand, width: 1.4);
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: _fill,
      hintStyle: const TextStyle(
        color: Color(0xFFB0B7C3),
        fontSize: 14.5,
        fontWeight: FontWeight.w400,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: const OutlineInputBorder(borderRadius: radius, borderSide: idle),
      enabledBorder:
          const OutlineInputBorder(borderRadius: radius, borderSide: idle),
      focusedBorder:
          const OutlineInputBorder(borderRadius: radius, borderSide: focus),
    );
  }

  Widget _textField({
    required String label,
    required TextEditingController controller,
    String? hint,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(label),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: _ink,
          ),
          cursorColor: _brand,
          decoration: _inputDecoration(hint: hint),
        ),
      ],
    );
  }

  Widget _dropdown({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(label),
        DropdownButtonFormField<String>(
          value: value != null && items.contains(value) ? value : null,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _ink),
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(14),
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: _ink,
          ),
          decoration: _inputDecoration(hint: "Seçiniz"),
          hint: const Text(
            "Seçiniz",
            style: TextStyle(
              color: Color(0xFFB0B7C3),
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          items: items
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _mediaTile({
    required String label,
    required IconData icon,
    required File? file,
    required VoidCallback onTap,
  }) {
    return Material(
      color: _fill,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 10, 12, 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _line),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: Colors.white,
                backgroundImage: file != null ? FileImage(file) : null,
                child: file == null
                    ? Icon(icon, color: _brand, size: 20)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      file != null ? "Seçildi" : "Dosya seçiniz",
                      style: const TextStyle(fontSize: 12, color: _muted),
                    ),
                  ],
                ),
              ),
              Icon(
                file != null ? Icons.edit_outlined : Icons.add_rounded,
                color: _brand,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusChoice(bool active, String label, Color color) {
    final selected = _isActive == active;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _isActive = active),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: const Color(0xFF1C2430).withOpacity(0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: selected ? color : const Color(0xFFC5CAD3),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 7),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: selected ? color : _muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _section({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1C2430).withOpacity(0.045),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFFFF4F3), Color(0xFFFFE4E1)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 18, color: _brand),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _ink,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _page,
      appBar: AppBar(
        backgroundColor: const Color(0xFFE53935),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: Colors.white,
            size: 24,
          ),
          splashRadius: 24,
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Ofis Düzenle",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFEEEFF3))),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF4B43), Color(0xFFE11D18)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: _brand.withOpacity(0.28),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: SizedBox(
                height: 52,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    "Kaydet",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1C2430).withOpacity(0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Kayıt durumu",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _muted,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: _fill,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          _statusChoice(true, "Aktif", const Color(0xFF128A52)),
                          _statusChoice(false, "Pasif", const Color(0xFF5C6570)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              _section(
                title: "Şirket bilgileri",
                icon: Icons.storefront_outlined,
                children: [
                  _mediaTile(
                    label: "Fotoğraf",
                    icon: Icons.photo_camera_outlined,
                    file: _selectedOfficePhoto,
                    onTap: () => _showImageSourceBottomSheet(isLogo: false),
                  ),
                  const SizedBox(height: 12),
                  _mediaTile(
                    label: "Logo",
                    icon: Icons.apartment_rounded,
                    file: _selectedLogo,
                    onTap: () => _showImageSourceBottomSheet(isLogo: true),
                  ),
                  const SizedBox(height: 16),
                  _textField(
                    label: "Telefon",
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    hint: "0 (___) ___ __ __",
                  ),
                  const SizedBox(height: 16),
                  _textField(
                    label: "Şirket adı",
                    controller: _companyNameController,
                    hint: "Ofis / şirket unvanı",
                  ),
                  const SizedBox(height: 16),
                  _textField(
                    label: "E-posta",
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    hint: "ofis@ornek.com",
                  ),
                  const SizedBox(height: 16),
                  _textField(
                    label: "Vergi no",
                    controller: _taxNoController,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  _textField(
                    label: "Vergi dairesi",
                    controller: _taxOfficeController,
                  ),
                ],
              ),
              _section(
                title: "Adres bilgileri",
                icon: Icons.location_on_outlined,
                children: [
                  _dropdown(
                    label: "İl",
                    value: _selectedCity,
                    items: _cityList,
                    onChanged: (value) {
                      setState(() {
                        _selectedCity = value;
                        _selectedDistrict = null;
                        _selectedNeighborhood = null;
                      });
                      _updateMapLocation();
                    },
                  ),
                  const SizedBox(height: 16),
                  _dropdown(
                    label: "İlçe",
                    value: _selectedDistrict,
                    items: _districtList,
                    onChanged: (value) {
                      setState(() {
                        _selectedDistrict = value;
                        _selectedNeighborhood = null;
                      });
                      _updateMapLocation();
                    },
                  ),
                  const SizedBox(height: 16),
                  _dropdown(
                    label: "Mahalle",
                    value: _selectedNeighborhood,
                    items: _neighborhoodList,
                    onChanged: (value) {
                      setState(() => _selectedNeighborhood = value);
                      _updateMapLocation();
                    },
                  ),
                  const SizedBox(height: 16),
                  _textField(
                    label: "Ofis adresi",
                    controller: _addressController,
                    hint: "Sokak, no, daire, ilçe / il",
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  _buildMapWidget(),
                ],
              ),
              _section(
                title: "Belgeler",
                icon: Icons.folder_open_outlined,
                children: [
                  _buildDocumentRow(
                    label: "Findeks Notu",
                    icon: Icons.credit_score_rounded,
                  ),
                  const SizedBox(height: 10),
                  _buildDocumentRow(
                    label: "Şirket İmza Sirküsü",
                    icon: Icons.border_color_rounded,
                  ),
                  const SizedBox(height: 10),
                  _buildDocumentRow(
                    label: "Vergi Levhası",
                    icon: Icons.receipt_rounded,
                  ),
                  const SizedBox(height: 10),
                  _buildDocumentRow(
                    label: "Faaliyet Belgesi",
                    icon: Icons.description_rounded,
                  ),
                  const SizedBox(height: 10),
                  _buildDocumentRow(
                    label: "Son Üç Aya Ait KDV Tahakkuk Fişi",
                    icon: Icons.calendar_month_rounded,
                  ),
                  const SizedBox(height: 10),
                  _buildDocumentRow(
                    label: "Ticaret Sicil Gazetesi",
                    icon: Icons.article_rounded,
                  ),
                  const SizedBox(height: 10),
                  _buildDocumentRow(
                    label: "Taşınmaz Yetki Belgesi",
                    icon: Icons.verified_rounded,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _updateMapLocation() async {
    try {
      String address = '';
      if (_selectedNeighborhood != null &&
          _selectedDistrict != null &&
          _selectedCity != null) {
        address =
            '$_selectedNeighborhood, $_selectedDistrict, $_selectedCity, Türkiye';
      } else if (_selectedDistrict != null && _selectedCity != null) {
        address = '$_selectedDistrict, $_selectedCity, Türkiye';
      } else if (_selectedCity != null) {
        address = '$_selectedCity, Türkiye';
      } else {
        return;
      }

      final locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        final location = locations.first;
        final newCenter = LatLng(location.latitude, location.longitude);

        setState(() {
          _mapCenter = newCenter;
          _selectedLocation = newCenter;
          _locationMarker = Marker(
            point: newCenter,
            width: 40,
            height: 40,
            child: const Icon(
              Icons.location_on,
              color: Color(0xFFE53935),
              size: 40,
            ),
          );
        });

        // Animate map to new location (only if widget is still mounted)
        if (mounted) {
          _mapController.move(
              newCenter,
              _selectedNeighborhood != null
                  ? 15.0
                  : _selectedDistrict != null
                      ? 13.0
                      : 11.0);
        }
      }
    } catch (e) {
      debugPrint('❌ Error updating map location: $e');
    }
  }

  void _showImageSourceBottomSheet({required bool isLogo}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    isLogo ? 'Logo Seç' : 'Fotoğraf Seç',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color.fromRGBO(238, 46, 36, 1)
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.photo_library,
                      color: Color.fromRGBO(238, 46, 36, 1),
                      size: 24,
                    ),
                  ),
                  title: const Text(
                    'Galeriden Seç',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery, isLogo: isLogo);
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color.fromRGBO(238, 46, 36, 1)
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Color.fromRGBO(238, 46, 36, 1),
                      size: 24,
                    ),
                  ),
                  title: const Text(
                    'Kamera ile Çek',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera, isLogo: isLogo);
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDocumentRow({required String label, required IconData icon}) {
    return Material(
      color: _fill,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _line),
          ),
          child: Row(
            children: [
              Icon(icon, color: _muted, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _ink,
                  ),
                ),
              ),
              const Icon(Icons.add_rounded, color: _brand, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source, {required bool isLogo}) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          if (isLogo) {
            _selectedLogo = File(pickedFile.path);
          } else {
            _selectedOfficePhoto = File(pickedFile.path);
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                isLogo ? 'Logo başarıyla seçildi!' : 'Fotoğraf başarıyla seçildi!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            source == ImageSource.camera
                ? 'Kamera açılırken bir hata oluştu: $e'
                : 'Fotoğraf seçilirken bir hata oluştu: $e',
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Widget _mapModeChip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? _brand : Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : _muted,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildMapWidget() {
    return Container(
      height: 300,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: _fill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _line),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
            child: Row(
              children: [
                _mapModeChip("Harita", !_isSatelliteView, () {
                  setState(() => _isSatelliteView = false);
                }),
                const SizedBox(width: 6),
                _mapModeChip("Uydu", _isSatelliteView, () {
                  setState(() => _isSatelliteView = true);
                }),
                const Spacer(),
                Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    onTap: _showFullScreenMap,
                    borderRadius: BorderRadius.circular(10),
                    child: const Padding(
                      padding: EdgeInsets.all(7),
                      child: Icon(Icons.fullscreen_rounded, size: 20, color: _ink),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _mapCenter,
                  initialZoom: _mapZoom,
                  onTap: (tapPosition, point) {
                    setState(() {
                      _mapCenter = point;
                      _selectedLocation = point;
                      _locationMarker = Marker(
                        point: point,
                        width: 40,
                        height: 40,
                        child: const Icon(
                          Icons.location_on,
                          color: Color(0xFFE53935),
                          size: 40,
                        ),
                      );
                    });
                    _mapController.move(point, _mapZoom);
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate: _isSatelliteView
                        ? 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'
                        : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.zecorner.app',
                    maxZoom: 19,
                  ),
                  if (_locationMarker != null)
                    MarkerLayer(
                      markers: [_locationMarker!],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Show fullscreen map (similar behavior to portfolio edit screen)
  void _showFullScreenMap() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: EdgeInsets.zero,
        child: Container(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          child: Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _mapCenter,
                  initialZoom: _mapZoom,
                  onTap: (tapPosition, point) {
                    setState(() {
                      _mapCenter = point;
                      _selectedLocation = point;
                      _locationMarker = Marker(
                        point: point,
                        width: 40,
                        height: 40,
                        child: const Icon(
                          Icons.location_on,
                          color: Color(0xFFE53935),
                          size: 40,
                        ),
                      );
                    });
                    _mapController.move(point, _mapZoom);
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate: _isSatelliteView
                        ? 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'
                        : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.zecorner.app',
                    maxZoom: 19,
                  ),
                  if (_locationMarker != null)
                    MarkerLayer(
                      markers: [_locationMarker!],
                    ),
                ],
              ),
              // Close button
              Positioned(
                top: 40,
                right: 16,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
                  onPressed: () => Navigator.of(context).pop(),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black54,
                    shape: const CircleBorder(),
                  ),
                ),
              ),
              // Map type selector
              Positioned(
                top: 40,
                left: 16,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _isSatelliteView = false;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: _isSatelliteView
                                ? Colors.transparent
                                : const Color(0xFFE53935),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(8),
                              bottomLeft: Radius.circular(8),
                            ),
                          ),
                          child: Text(
                            "Harita",
                            style: TextStyle(
                              color: _isSatelliteView
                                  ? Colors.grey[600]
                                  : Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _isSatelliteView = true;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: _isSatelliteView
                                ? const Color(0xFFE53935)
                                : Colors.transparent,
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(8),
                              bottomRight: Radius.circular(8),
                            ),
                          ),
                          child: Text(
                            "Uydu",
                            style: TextStyle(
                              color: _isSatelliteView
                                  ? Colors.white
                                  : Colors.grey[600],
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
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