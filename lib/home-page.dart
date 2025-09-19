import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:presensi/models/home-response.dart';
import 'package:presensi/simpan-page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as myHttp;

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  late Future<String> _name, _token;
  HomeResponseModel? homeResponseModel;
  Datum? hariIni;
  List<Datum> riwayat = [];

  @override
  void initState() {
    super.initState();
    _token = _prefs.then((prefs) => prefs.getString("token") ?? "");
    _name = _prefs.then((prefs) => prefs.getString("name") ?? "");
  }

  Future<void> getData() async {
    try {
      String token = await _token;
      print("DEBUG TOKEN: '$token'");

      final headers = {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      };

      final uri = Uri.parse(
          'https://smkmaarif9kebumen.sch.id/guru/public/api/get-presensi');
      final response = await myHttp.get(uri, headers: headers);

      print("GET-PRESENSI STATUS: ${response.statusCode}");
      print("GET-PRESENSI BODY: ${response.body}");

      if (response.statusCode != 200) {
        throw Exception('Server error: ${response.statusCode}');
      }

      final Map<String, dynamic> jsonMap = json.decode(response.body);
      homeResponseModel = HomeResponseModel.fromJson(jsonMap);

      riwayat.clear();
      hariIni = null;
      for (var element in homeResponseModel!.data) {
        if (element.isHariIni) {
          hariIni = element;
        } else {
          riwayat.add(element);
        }
      }
    } catch (e) {
      print("ERROR GETDATA: $e");
      hariIni = null;
      riwayat.clear();
      throw e;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Presensi"),
      ),
      body: FutureBuilder(
        future: getData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Gagal memuat data:\n${snapshot.error}',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {}); // trigger ulang future
                    },
                    child: const Text('Coba lagi'),
                  ),
                ],
              ),
            );
          } else {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FutureBuilder(
                      future: _name,
                      builder:
                          (BuildContext context, AsyncSnapshot<String> snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const CircularProgressIndicator();
                        } else {
                          return Text(
                            snapshot.data ?? "-",
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      decoration:
                          BoxDecoration(color: Colors.blue[800], borderRadius: BorderRadius.circular(8)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Text(hariIni?.tanggal ?? '-',
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 16)),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Column(
                                  children: [
                                    Text(hariIni?.masuk ?? '-',
                                        style: const TextStyle(
                                            color: Colors.white, fontSize: 24)),
                                    const Text("Masuk",
                                        style: TextStyle(
                                            color: Colors.white, fontSize: 16))
                                  ],
                                ),
                                Column(
                                  children: [
                                    Text(hariIni?.pulang ?? '-',
                                        style: const TextStyle(
                                            color: Colors.white, fontSize: 24)),
                                    const Text("Pulang",
                                        style: TextStyle(
                                            color: Colors.white, fontSize: 16))
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text("Riwayat Presensi",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    Expanded(
                      child: riwayat.isEmpty
                          ? const Center(child: Text("Belum ada riwayat"))
                          : ListView.builder(
                              itemCount: riwayat.length,
                              itemBuilder: (context, index) => Card(
                                child: ListTile(
                                  leading: Text(riwayat[index].tanggal),
                                  title: Row(
                                    children: [
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(riwayat[index].masuk,
                                              style:
                                                  const TextStyle(fontSize: 16)),
                                          const Text("Masuk",
                                              style: TextStyle(fontSize: 12))
                                        ],
                                      ),
                                      const SizedBox(width: 20),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(riwayat[index].pulang,
                                              style:
                                                  const TextStyle(fontSize: 16)),
                                          const Text("Pulang",
                                              style: TextStyle(fontSize: 12))
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => const SimpanPage()))
              .then((value) {
            setState(() {});
          });
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
