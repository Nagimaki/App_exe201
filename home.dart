// lib/home.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'camera_page.dart';
import 'calendar_page.dart' as cal;
import 'management_page.dart';
import 'payment_menu_page.dart';
import 'login.dart';

class HomePage extends StatelessWidget {
  final int userId;
  final String userName;
  final String role;

  const HomePage({
    Key? key,
    required this.userId,
    required this.userName,
    required this.role,
  }) : super(key: key);

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          SafeArea(
            child: Container(
              color: const Color(0xFFcde9cc),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  const CircleAvatar(radius: 24, backgroundColor: Colors.purple),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      userName,
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout, color: Colors.white),
                    onPressed: () => _logout(context),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _HomeTile(
                    label: 'AI Phân tích da',
                    icon: Icons.camera_alt,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => CameraPage()),
                    ),
                  ),
                  _HomeTile(
                    label: 'Đặt chỗ',
                    icon: Icons.calendar_today,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => cal.BookingPage(userId: userId),
                      ),
                    ),
                  ),
                  _HomeTile(
                    label: 'Quản lý',
                    icon: Icons.group,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ManagementPage(
                          userId: userId,
                          role: role,
                        ),
                      ),
                    ),
                  ),
                  _HomeTile(
                    label: 'Thanh toán',
                    icon: Icons.payment,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PaymentMenuPage()),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _HomeTile({
    Key? key,
    required this.label,
    required this.icon,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 40, color: Colors.grey[700]),
              const SizedBox(height: 8),
              Text(label, style: const TextStyle(fontSize: 16)),
            ],
          ),
        ),
      ),
    );
  }
}
