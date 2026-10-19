import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:zecorner/core/location/nominatim_geocoding.dart';

/// Sokak haritası. Carto rastertiles anahtarsız kullanımda karoların üzerine
/// "API KEY REQUIRED" basıyor. Esri World Street Map anahtar istemez.
/// Yedek: tile.openstreetmap.org ([Usage Policy](https://operations.osmfoundation.org/policies/tiles/)).
TileLayer _zecornerStreetTileLayer() {
  return TileLayer(
    urlTemplate:
        'https://server.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer/tile/{z}/{y}/{x}',
    fallbackUrl: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    userAgentPackageName: 'com.zecorner.app',
    maxNativeZoom: 19,
    maxZoom: 19,
  );
}

class MapLocationPicker extends StatefulWidget {
  final LatLng? initialPosition;
  final Function(LatLng) onLocationSelected;
  final String? selectedAddress;

  const MapLocationPicker({
    super.key,
    this.initialPosition,
    required this.onLocationSelected,
    this.selectedAddress,
  });

  @override
  State<MapLocationPicker> createState() => _MapLocationPickerState();
}

class _MapLocationPickerState extends State<MapLocationPicker> {
  MapController? _mapController;
  LatLng? _selectedPosition;
  List<Marker> _markers = [];
  bool _isLoading = true;
  String? _currentAddress;
  String _mapType = 'OpenStreetMap';

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    try {
      if (widget.initialPosition != null) {
        _selectedPosition = widget.initialPosition;
        _currentAddress = widget.selectedAddress;
        _addMarker(_selectedPosition!);
      } else {
        // Default to Istanbul if no initial position
        _selectedPosition = const LatLng(41.0082, 28.9784);
        _currentAddress = "İstanbul, Türkiye";
        _addMarker(_selectedPosition!);
      }
    } catch (e) {
      _selectedPosition = const LatLng(41.0082, 28.9784);
      _currentAddress = "İstanbul, Türkiye";
      _addMarker(_selectedPosition!);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }


  Future<void> _getAddressFromPosition(LatLng position) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks[0];
        setState(() {
          _currentAddress = '${place.street}, ${place.locality}, ${place.administrativeArea}';
        });
      }
    } catch (e) {
      setState(() {
        _currentAddress = 'Adres alınamadı';
      });
    }
  }

  void _addMarker(LatLng position) {
    setState(() {
      _markers.clear();
      _markers.add(
        Marker(
          point: position,
          width: 40,
          height: 40,
          child: GestureDetector(
            onTap: () {
              _selectedPosition = position;
              _getAddressFromPosition(position);
            },
            child: const Icon(
              Icons.location_on,
              color: Color(0xFFE53935),
              size: 40,
            ),
          ),
        ),
      );
    });
  }

  void _onMapTapped(TapPosition tapPosition, LatLng position) {
    setState(() {
      _selectedPosition = position;
      _addMarker(position);
    });
    _getAddressFromPosition(position);
  }


  void _confirmLocation() {
    if (_selectedPosition != null) {
      widget.onLocationSelected(_selectedPosition!);
      Navigator.of(context).pop();
    }
  }

  Widget _buildMapWidget() {
    if (_selectedPosition == null) {
      return Container(
        color: Colors.grey[300],
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.map_outlined, size: 48, color: Colors.grey),
              SizedBox(height: 16),
              Text('Konum yükleniyor...', style: TextStyle(fontSize: 16)),
            ],
          ),
        ),
      );
    }

    try {
      return FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: _selectedPosition!,
          initialZoom: 15.0,
          backgroundColor: Colors.white,
          onTap: _onMapTapped,
          interactionOptions: const InteractionOptions(
            flags: InteractiveFlag.all,
          ),
        ),
        children: [
          if (_mapType == 'OpenStreetMap')
            _zecornerStreetTileLayer()
          else
            TileLayer(
              urlTemplate:
                  'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
              userAgentPackageName: 'zecorner',
              maxNativeZoom: 19,
              maxZoom: 19,
            ),
          MarkerLayer(
            markers: _markers,
          ),
        ],
      );
    } catch (e) {
      return Container(
        color: Colors.grey[300],
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red),
              SizedBox(height: 16),
              Text('Harita yüklenemedi', style: TextStyle(fontSize: 16)),
              Text('Lütfen internet bağlantınızı kontrol edin', style: TextStyle(fontSize: 12)),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Konum Seç'),
        backgroundColor: const Color(0xFFE53935),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE53935)),
              ),
            )
          : Stack(
              children: [
                _buildMapWidget(),
                // Map type toggle button
                Positioned(
                  top: 16,
                  left: 16,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildMapTypeButton('Harita', 'OpenStreetMap'),
                          _buildMapTypeButton('Uydu', 'Satellite'),
                        ],
                    ),
                  ),
                ),
                // Address display and confirm button
                Positioned(
                  bottom: 20,
                  left: 20,
                  right: 20,
                  child: Column(
                    children: [
                      if (_currentAddress != null)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.location_on,
                                color: Color(0xFFE53935),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _currentAddress!,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _confirmLocation,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE53935),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Konumu Seç',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
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

  Widget _buildMapTypeButton(String label, String mapType) {
    final isSelected = _mapType == mapType;
    return GestureDetector(
      onTap: () {
        setState(() {
          _mapType = mapType;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE53935) : Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class MapDisplayWidget extends StatelessWidget {
  final LatLng? position;
  final String? address;
  final VoidCallback? onTap;

  const MapDisplayWidget({
    super.key,
    this.position,
    this.address,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: position != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _buildSafeMap(),
                    Positioned(
                      right: 4,
                      bottom: address != null ? 48 : 4,
                      child: Text(
                        '© Esri',
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.black.withValues(alpha: 0.45),
                          shadows: const [
                            Shadow(
                              color: Colors.white,
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Location info
                    if (address != null)
                      Positioned(
                        bottom: 8,
                        left: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 2,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.location_on,
                                color: Color(0xFFE53935),
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  address!,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              )
            : Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.map_outlined,
                      size: 48,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Harita Konumu",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Ofis konumunu seçmek için tıklayın",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildSafeMap() {
    if (position == null) {
      return Container(
        color: Colors.grey[300],
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.map_outlined, size: 48, color: Colors.grey),
              SizedBox(height: 8),
              Text('Konum bulunamadı', style: TextStyle(fontSize: 14)),
            ],
          ),
        ),
      );
    }

    try {
      return FlutterMap(
        options: MapOptions(
          initialCenter: position!,
          initialZoom: 15.0,
          backgroundColor: Colors.white,
          interactionOptions: const InteractionOptions(
            flags: InteractiveFlag.all,
          ),
        ),
        children: [
          _zecornerStreetTileLayer(),
          MarkerLayer(
            markers: [
              Marker(
                point: position!,
                width: 30,
                height: 30,
                child: const Icon(
                  Icons.location_on,
                  color: Color(0xFFE53935),
                  size: 30,
                ),
              ),
            ],
          ),
        ],
      );
    } catch (e) {
      return Container(
        color: Colors.grey[300],
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.map_outlined, size: 48, color: Colors.grey),
              SizedBox(height: 8),
              Text('Harita yüklenemedi', style: TextStyle(fontSize: 14)),
            ],
          ),
        ),
      );
    }
  }
}
