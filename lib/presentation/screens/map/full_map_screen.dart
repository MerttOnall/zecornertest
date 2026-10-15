// import 'package:flutter/material.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:geolocator/geolocator.dart';

// class FullMapScreen extends StatefulWidget {
//   const FullMapScreen({super.key});

//   @override
//   State<FullMapScreen> createState() => _FullMapScreenState();
// }

// class _FullMapScreenState extends State<FullMapScreen> {
//   GoogleMapController? _mapController;
//   final LatLng _defaultLocation = const LatLng(41.0082, 28.9784); // İstanbul
//   Set<Marker> _markers = {};
  
//   @override
//   void initState() {
//     super.initState();
//     _loadMarkers();
//   }
  
//   void _loadMarkers() {
//     _markers = {
//       Marker(
//         markerId: const MarkerId('property_1'),
//         position: const LatLng(41.0082, 28.9784),
//         infoWindow: const InfoWindow(
//           title: 'Lüks Daire',
//           snippet: '2.500.000 TL - Satılık',
//         ),
//         icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
//         onTap: () => _showPropertyInfo('Lüks Daire', '2.500.000 TL - Satılık'),
//       ),
//       Marker(
//         markerId: const MarkerId('property_2'),
//         position: const LatLng(41.0122, 28.9734),
//         infoWindow: const InfoWindow(
//           title: 'Modern Ofis',
//           snippet: '15.000 TL/ay - Kiralık',
//         ),
//         icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
//         onTap: () => _showPropertyInfo('Modern Ofis', '15.000 TL/ay - Kiralık'),
//       ),
//       Marker(
//         markerId: const MarkerId('property_3'),
//         position: const LatLng(41.0052, 28.9814),
//         infoWindow: const InfoWindow(
//           title: 'Villa',
//           snippet: '5.200.000 TL - Satılık',
//         ),
//         icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
//         onTap: () => _showPropertyInfo('Villa', '5.200.000 TL - Satılık'),
//       ),
//     };
//   }
  
//   void _showPropertyInfo(String title, String info) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text('$title\n$info'),
//         backgroundColor: const Color(0xFFE53935),
//         duration: const Duration(seconds: 3),
//       ),
//     );
//   }
  
//   void _goToCurrentLocation() async {
//     try {
//       LocationPermission permission = await Geolocator.checkPermission();
//       if (permission == LocationPermission.denied) {
//         permission = await Geolocator.requestPermission();
//         if (permission == LocationPermission.denied) {
//           _showMessage('Konum izni verilmedi');
//           return;
//         }
//       }
      
//       Position position = await Geolocator.getCurrentPosition();
//       final LatLng currentLocation = LatLng(position.latitude, position.longitude);
      
//       _mapController?.animateCamera(
//         CameraUpdate.newLatLngZoom(currentLocation, 15),
//       );
//       _showMessage('Mevcut konumunuza gidildi');
//     } catch (e) {
//       _showMessage('Konum alınamadı');
//     }
//   }
  
//   void _showMessage(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: const Color(0xFFE53935),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Harita'),
//         backgroundColor: const Color(0xFFE53935),
//         foregroundColor: Colors.white,
//         elevation: 0,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back),
//           onPressed: () => Navigator.pop(context),
//         ),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.my_location),
//             onPressed: _goToCurrentLocation,
//           ),
//         ],
//       ),
//       body: GoogleMap(
//         onMapCreated: (GoogleMapController controller) {
//           _mapController = controller;
//         },
//         initialCameraPosition: CameraPosition(
//           target: _defaultLocation,
//           zoom: 12.0,
//         ),
//         markers: _markers,
//         myLocationEnabled: true,
//         myLocationButtonEnabled: false,
//         zoomControlsEnabled: false,
//         mapType: MapType.normal,
//       ),
//       floatingActionButton: Column(
//         mainAxisAlignment: MainAxisAlignment.end,
//         children: [
//           FloatingActionButton(
//             heroTag: "zoom_in",
//             mini: true,
//             backgroundColor: const Color(0xFFE53935),
//             foregroundColor: Colors.white,
//             onPressed: () {
//               _mapController?.animateCamera(CameraUpdate.zoomIn());
//             },
//             child: const Icon(Icons.zoom_in),
//           ),
//           const SizedBox(height: 8),
//           FloatingActionButton(
//             heroTag: "zoom_out",
//             mini: true,
//             backgroundColor: const Color(0xFFE53935),
//             foregroundColor: Colors.white,
//             onPressed: () {
//               _mapController?.animateCamera(CameraUpdate.zoomOut());
//             },
//             child: const Icon(Icons.zoom_out),
//           ),
//           const SizedBox(height: 8),
//           FloatingActionButton(
//             heroTag: "home",
//             backgroundColor: const Color(0xFFE53935),
//             foregroundColor: Colors.white,
//             onPressed: () {
//               _mapController?.animateCamera(
//                 CameraUpdate.newLatLngZoom(_defaultLocation, 12),
//               );
//               _showMessage('İstanbul\'a gidildi');
//             },
//             child: const Icon(Icons.home),
//           ),
//         ],
//       ),
//     );
//   }
// } 