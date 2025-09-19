import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:presensi/models/save-presensi-response.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_maps/maps.dart';
import 'package:http/http.dart' as myHttp;

class SimpanPage extends StatefulWidget {
  const SimpanPage({Key? key}) : super(key: key);

  @override
  State<SimpanPage> createState() => _SimpanPageState();
}

class _SimpanPageState extends State<SimpanPage> {
  bool _isLoading = false;

  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  late Future<String> _token;

  bool get _isAfter14_30 {
    final now = DateTime.now();
    final jam = now.hour;
    final menit = now.minute;
    return (jam > 14 || (jam == 14 && menit >= 30));
  }

  @override
  void initState() {
    super.initState();
    _token = _prefs.then((prefs) => prefs.getString("token") ?? "");
  }

  Future<LocationData?> _currenctLocation() async {
    final location = Location();

    bool serviceEnable = await location.serviceEnabled();
    if (!serviceEnable) {
      serviceEnable = await location.requestService();
      if (!serviceEnable) return null;
    }

    var permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) return null;
    }

    return await location.getLocation();
  }

  Future savePresensi(latitude, longitude) async {
    final token = await _token;

    Map<String, String> body = {
      "latitude": latitude.toString(),
      "longitude": longitude.toString(),
    };

    Map<String, String> headers = {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json'
    };

    var response = await myHttp.post(
      Uri.parse("https://smkmaarif9kebumen.sch.id/guru/public/api/save-presensi"),
      body: body,
      headers: headers,
    );

    final savePresensiResponseModel =
        SavePresensiResponseModel.fromJson(json.decode(response.body));

    if (savePresensiResponseModel.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Sukses simpan Presensi')),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Gagal: ${savePresensiResponseModel.message}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Presensi")),
      body: FutureBuilder<LocationData?>(
        future: _currenctLocation(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final currentLocation = snapshot.data!;
            print("Lokasi: ${currentLocation.latitude} | ${currentLocation.longitude}");

            return SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    SizedBox(
                      height: 300,
                      child: SfMaps(
                        layers: [
                          MapTileLayer(
                            initialFocalLatLng: MapLatLng(
                              currentLocation.latitude!,
                              currentLocation.longitude!,
                            ),
                            initialZoomLevel: 15,
                            initialMarkersCount: 1,
                            urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                            markerBuilder: (context, index) {
                              return MapMarker(
                                latitude: currentLocation.latitude!,
                                longitude: currentLocation.longitude!,
                                child: const Icon(Icons.location_on, color: Colors.red),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: (!_isAfter14_30 || _isLoading)
                          ? null
                          : () async {
                              setState(() => _isLoading = true);
                              await savePresensi(
                                currentLocation.latitude,
                                currentLocation.longitude,
                              );
                              setState(() => _isLoading = false);
                            },
                      child: _isLoading
                          ? const SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(!_isAfter14_30
                              ? "Belum waktunya absen pulang"
                              : "Simpan Presensi"),
                    ),
                  ],
                ),
              ),
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}
