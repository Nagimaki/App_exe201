// lib/login.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'home.dart';

const String baseUrl = 'https://web-production-9f7d5.up.railway.app';

/// Trang Đăng nhập
class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _login() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final res = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': _userCtrl.text.trim(),
        'password': _passCtrl.text.trim(),
      }),
    );

    setState(() => _loading = false);

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      if (data['success'] == true) {
        final userId   = data['userId']   as int;
        final userName = data['userName'] as String? ?? _userCtrl.text.trim();
        final role     = data['role']     as String? ?? 'employee';

        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        await prefs.setInt('userId', userId);
        await prefs.setString('userName', userName);
        await prefs.setString('role', role);

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => HomePage(
              userId: userId,
              userName: userName,
              role: role,
            ),
          ),
        );
      } else {
        setState(() => _error = data['error'] ?? 'Đăng nhập thất bại');
      }
    } else {
      setState(() => _error = 'Tên đăng nhập hoặc mật khẩu không đúng');
    }
  }

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đăng nhập'),
        backgroundColor: const Color(0xFFcde9cc),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 40),
            const CircleAvatar(
              radius: 60,
              backgroundColor: Color(0xFF1e88e5),
              child: Icon(Icons.person, size: 60, color: Colors.white),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _userCtrl,
              decoration: const InputDecoration(hintText: 'Tên đăng nhập'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passCtrl,
              obscureText: true,
              decoration: const InputDecoration(hintText: 'Mật khẩu'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 24),
            _loading
                ? const CircularProgressIndicator()
                : ElevatedButton(
              onPressed: _login,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFcde9cc),
                minimumSize: const Size.fromHeight(48),
              ),
              child: const Text('Đăng nhập'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RegisterAdminPage()),
                );
              },
              child: const Text('Đăng ký Admin mới'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Trang Đăng ký Admin mới
class RegisterAdminPage extends StatefulWidget {
  const RegisterAdminPage({Key? key}) : super(key: key);
  @override
  State<RegisterAdminPage> createState() => _RegisterAdminPageState();
}

class _RegisterAdminPageState extends State<RegisterAdminPage> {
  final _userCtrl  = TextEditingController();
  final _passCtrl  = TextEditingController();
  final _pass2Ctrl = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _registerAdmin() async {
    final username = _userCtrl.text.trim();
    final p1 = _passCtrl.text.trim();
    final p2 = _pass2Ctrl.text.trim();
    if (username.isEmpty || p1.isEmpty || p1 != p2) {
      setState(() => _error = 'Kiểm tra lại thông tin');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });

    final res = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': p1,
      }),
    );
    setState(() => _loading = false);

    if (res.statusCode == 201) {
      final data = jsonDecode(res.body);
      final userId   = data['userId']   as int;
      final userName = data['userName'] as String? ?? username;
      final role     = data['role']     as String? ?? 'admin';

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => HomePage(
            userId: userId,
            userName: userName,
            role: role,
          ),
        ),
      );
    } else {
      setState(() => _error = 'Đăng ký thất bại, vui lòng nhập email khác (${res.statusCode})');
    }
  }

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    _pass2Ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đăng ký Admin'),
        backgroundColor: const Color(0xFFcde9cc),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 40),
            TextField(
              controller: _userCtrl,
              decoration: const InputDecoration(hintText: 'Username Admin'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passCtrl,
              obscureText: true,
              decoration: const InputDecoration(hintText: 'Mật khẩu'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _pass2Ctrl,
              obscureText: true,
              decoration:
              const InputDecoration(hintText: 'Xác nhận mật khẩu'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 24),
            _loading
                ? const CircularProgressIndicator()
                : ElevatedButton(
              onPressed: _registerAdmin,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFcde9cc),
                minimumSize: const Size.fromHeight(48),
              ),
              child: const Text('Tạo tài khoản Admin'),
            ),
          ],
        ),
      ),
    );
  }
}
