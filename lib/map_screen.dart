import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  LatLng? selectedLocation;
  String? selectedplace;
  GoogleMapController? mapController;
  TextEditingController searchController = TextEditingController();
  final TextEditingController placeNameController = TextEditingController();

  void _onTap(LatLng position) async {
    String place = placeNameController.text;
    setState(() {
      selectedLocation = position;
      selectedplace = place;
    });
    print('위치: $position, 주소: $place');
  }

  Future<void> _searchLocation() async {
    String input = searchController.text.trim();
    if (input.isEmpty) return;

    try {
      List<Location> locations = await locationFromAddress(
        input,
        localeIdentifier: 'ko',
      );
      if (locations.isNotEmpty) {
        final location = locations.first;
        LatLng newLatLng = LatLng(location.latitude, location.longitude);

        String place = placeNameController.text;

        setState(() {
          selectedLocation = newLatLng;
          selectedplace = place;
        });

        mapController?.animateCamera(CameraUpdate.newLatLngZoom(newLatLng, 16));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('주소를 찾을 수 없습니다.')),
      );
    }
  }

  void _confirmLocation() {
    if (selectedLocation != null && selectedplace != null) {
      print('좌표: ${selectedLocation!.latitude}, ${selectedLocation!.longitude}');
      print('주소: $selectedplace');
      Navigator.pop(context, {
        'lat': selectedLocation!.latitude,
        'lng': selectedLocation!.longitude,
        'placeName': placeNameController.text,
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('위치를 선택하고 장소명을 입력하세요')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("지도에서 위치 선택")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: '주소 또는 장소명을 입력하세요',
                      border: OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(Icons.search),
                        onPressed: _searchLocation,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: TextField(
              controller: placeNameController,
              decoration: InputDecoration(
                labelText: '장소 별명을 입력하세요',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: _confirmLocation,
            child: Text('장소 설정'),
          ),
          if (selectedplace != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                '선택된 주소: $selectedplace',
                style: TextStyle(fontSize: 16),
              ),
            ),
          Expanded(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(37.5665, 126.9780),
                zoom: 14,
              ),
              onMapCreated: (controller) => mapController = controller,
              onTap: _onTap,
              markers: selectedLocation != null
                  ? {
                Marker(
                  markerId: MarkerId("selected"),
                  position: selectedLocation!,
                )
              }
                  : {},
            ),
          ),
        ],
      ),
    );
  }
}
