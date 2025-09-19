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
    super.initState();
    _token = _prefs.then((prefs) => prefs.getString("token") ?? "");
    _name = _prefs.then((prefs) => prefs.getString("name") ?? "");
    checkToken();
  }

  void checkToken() async {
    String tokenStr = await _token;
    String nameStr = await _name;
    if (tokenStr.isNotEmpty && nameStr.isNotEmpty) {
      Future.delayed(const Duration(seconds: 1), () {
        Navigator.of(context)
            .pushReplacement(MaterialPageRoute(builder: (_) => const HomePage()));
      });
    }
  }

  Future<void> login(String email, String password) async {
    try {
      if (email.isEmpty || password.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Email dan password wajib diisi")),
        );
        return;
      }

      final uri = Uri.parse(
          'https://smkmaarif9kebumen.sch.id/guru/public/api/login');
      final response = await myHttp.post(uri, body: {
        "email": email,
        "password": password,
      });

      print("LOGIN STATUS: ${response.statusCode}");
      print("LOGIN BODY: ${response.body}");

      if (response.statusCode == 200) {
        LoginResponseModel loginResponseModel =
            LoginResponseModel.fromJson(json.decode(response.body));
        await saveUser(
            loginResponseModel.data.token, loginResponseModel.data.name);
      } else if (response.statusCode == 401) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Email atau password salah")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Login gagal: ${response.statusCode}")),
        );
      }
    } catch (e) {
      print("ERROR LOGIN: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal koneksi ke server: $e")),
      );
    }
  }

  Future<void> saveUser(String token, String name) async {
    try {
      final SharedPreferences prefs = await _prefs;
      await prefs.setString("token", token);
      await prefs.setString("name", name);
      Navigator.of(context)
          .pushReplacement(MaterialPageRoute(builder: (_) => const HomePage()));
    } catch (e) {
      print("ERROR SAVE USER: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal menyimpan data user: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(
                      child: Text("LOGIN",
                          style: TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold))),
                  const SizedBox(height: 20),
                  const Text("Email"),
                  TextField(controller: emailController),
                  const SizedBox(height: 20),
                  const Text("Password"),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                  ),
                  const SizedBox(height: 30),
                  Center(
                    child: ElevatedButton(
                      onPressed: () {
                        login(emailController.text, passwordController.text);
                      },
                      child: const Text("Masuk"),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
