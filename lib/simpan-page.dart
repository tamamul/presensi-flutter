import 'dart:convert'; // WAJIB buat json.decode
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
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  late Future<String> _token;

  @override
  void initState() {
    super.initState();
    _token = _prefs.then((SharedPreferences prefs) {
      return prefs.getString("token") ?? "";
    });
  }

  Future<LocationData?> _currenctLocation() async {
    bool serviceEnable;
    PermissionStatus permissionGranted;

    Location location = Location();

    serviceEnable = await location.serviceEnabled();
    if (!serviceEnable) {
      serviceEnable = await location.requestService();
      if (!serviceEnable) {
        return null;
      }
    }

    permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        return null;
      }
    }

    return await location.getLocation();
  }

  Future savePresensi(latitude, longitude) async {
    final token = await _token; // ambil token dari shared prefs

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

    print("PRESENSI STATUS: ${response.statusCode}");
    print("PRESENSI BODY: ${response.body}");

    if (response.statusCode == 200) {
      SavePresensiResponseModel savePresensiResponseModel =
          SavePresensiResponseModel.fromJson(json.decode(response.body));

      if (savePresensiResponseModel.success) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Sukses simpan Presensi')));
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('❌ Gagal: ${savePresensiResponseModel.message}')));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error: ${response.statusCode}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Presensi"),
      ),
      body: FutureBuilder<LocationData?>(
        future: _currenctLocation(),
        builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
          if (snapshot.hasData) {
            final LocationData currentLocation = snapshot.data;
            print("Lokasi: ${currentLocation.latitude} | ${currentLocation.longitude}");

            return SafeArea(
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
  initialMarkersCount: 2,
  urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
  markerBuilder: (BuildContext context, int index) {
    if (index == 0) {
      return const MapMarker(
        latitude: 0,
        longitude: 0,
        child: Icon(Icons.location_on, color: Colors.red),
      );
    } else {
      return MapMarker(
        latitude: currentLocation.latitude!,
        longitude: currentLocation.longitude!,
        child: const Icon(
          Icons.location_on,
          color: Colors.red,
        ),
      );
    }
  },
),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      savePresensi(
                        currentLocation.latitude,
                        currentLocation.longitude,
                      );
                    },
                    child: const Text("Simpan Presensi"),
                  ),
                ],
              ),
            );
          } else {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
        },
      ),
    );
  }
}
