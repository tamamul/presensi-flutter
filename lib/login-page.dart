import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:presensi/home-page.dart';
import 'package:http/http.dart' as myHttp;
import 'package:presensi/models/login-response.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  late Future<String> _name, _token;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _token = _prefs.then((SharedPreferences prefs) {
      return prefs.getString("token") ?? "";
    });

    _name = _prefs.then((SharedPreferences prefs) {
      return prefs.getString("name") ?? "";
    });
    checkToken(_token, _name);
  }

  checkToken(token, name) async {
    String tokenStr = await token;
    String nameStr = await name;
    if (tokenStr != "" && nameStr != "") {
      Future.delayed(Duration(seconds: 1), () async {
        Navigator.of(context)
            .push(MaterialPageRoute(builder: (context) => HomePage()))
            .then((value) {
          setState(() {});
        });
      });
    }
  }

  Future login(email, password) async {
  try {
    Map<String, String> body = {"email": email, "password": password};
    final uri = Uri.parse('https://smkmaarif9kebumen.sch.id/guru/public/api/login');
    final response = await myHttp.post(uri, body: body);

    print("LOGIN STATUS: ${response.statusCode}");
    print("LOGIN BODY: ${response.body}");

    if (response.statusCode == 401) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Email atau password salah")));
      return;
    }

    if (response.statusCode != 200) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Login gagal: ${response.statusCode}")));
      return;
    }

    final Map<String, dynamic> jsonMap = json.decode(response.body);
    final data = jsonMap['data'];

    if (data == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(jsonMap['message'] ?? 'Login gagal')));
      return;
    }

    final token = data['token'] ?? data['access_token'] ?? '';
    final name = data['name'] ?? '';

    if (token == '') {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Token tidak diterima dari server")));
      return;
    }

    await saveUser(token, name);
  } catch (err) {
    print('LOGIN ERROR: $err');
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text("Error koneksi: $err")));
  }
}

Future saveUser(token, name) async {
  try {
    final SharedPreferences pref = await _prefs;
    // PENTING: await supaya benar-benar tersimpan sebelum navigasi
    await pref.setString("name", name);
    await pref.setString("token", token);

    print("SAVED PREFS name=$name token=$token");

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomePage()));
  } catch (err) {
    print('ERROR saveUser: $err');
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(err.toString())));
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
          child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Center(child: Text("LOGIN")),
              SizedBox(height: 20),
              Text("Email"),
              TextField(
                controller: emailController,
              ),
              SizedBox(height: 20),
              Text("Password"),
              TextField(
                controller: passwordController,
                obscureText: true,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                  onPressed: () {
                    login(emailController.text, passwordController.text);
                  },
                  child: Text("Masuk"))
            ],
          ),
        ),
      )),
    );
  }
}
