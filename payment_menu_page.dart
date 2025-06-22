// lib/payment_menu_page.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// WebView mới từ webview_flutter v4+
import 'package:webview_flutter/webview_flutter.dart';

const String basePaymentUrl =
    'https://web-production-9f7d5.up.railway.app/payment';

// [THAY ĐỔI 1] Đổi tên enum cho rõ ràng hơn: Gói cơ bản và Gói VIP
enum PaymentPackage { basic, vip }

class PaymentMenuPage extends StatelessWidget {
  const PaymentMenuPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thanh toán'),
        backgroundColor: const Color(0xFFcde9cc),
        leading: const BackButton(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1e88e5),
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreatePaymentPage()),
              ),
              child: const Text('Tạo thanh toán mới'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF43a047),
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PaymentHistoryPage()),
              ),
              child: const Text('Xem lịch sử thanh toán'),
            ),
          ],
        ),
      ),
    );
  }
}

class CreatePaymentPage extends StatefulWidget {
  const CreatePaymentPage({Key? key}) : super(key: key);

  @override
  State<CreatePaymentPage> createState() => _CreatePaymentPageState();
}

class _CreatePaymentPageState extends State<CreatePaymentPage> {
  PaymentPackage? _selectedPackage;
  final _descCtrl = TextEditingController(text: 'Thanh toán dịch vụ');
  bool _loading = false;
  String? _checkoutUrl;

  void _onPackageChanged(PaymentPackage? value) {
    setState(() => _selectedPackage = value);
  }

  Future<void> _submit() async {
    if (_selectedPackage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn gói thanh toán')),
      );
      return;
    }
    // [THAY ĐỔI 2] Cập nhật logic giá tiền theo enum mới
    final int intAmt = _selectedPackage == PaymentPackage.basic ? 250000 : 500000;

    setState(() {
      _loading = true;
      _checkoutUrl = null;
    });
    final res = await http.post(
      Uri.parse('$basePaymentUrl/create'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'amount': intAmt,
        'description': _descCtrl.text.trim(),
      }),
    );
    setState(() {
      _loading = false;
    });
    debugPrint('CREATE PAYMENT → status=${res.statusCode}, body=${res.body}');
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      setState(() => _checkoutUrl = data['checkoutUrl'] as String);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tạo thanh toán thất bại (${res.statusCode})')),
      );
    }
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tạo thanh toán'),
        backgroundColor: const Color(0xFFcde9cc),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // [THAY ĐỔI 3] Chỉnh sửa RadioListTile để hiển thị nội dung chi tiết
            Card(
              child: RadioListTile<PaymentPackage>(
                title: const Text('Gói cơ bản(250.000đ/tháng)'),
                subtitle: const Text(
                  'Phân tích da AI, gợi ý sản phẩm, theo dõi doanh thu và hoa hồng của nhân viên.',
                ),
                value: PaymentPackage.basic,
                groupValue: _selectedPackage,
                onChanged: _onPackageChanged,
                isThreeLine: true, // Cho phép subtitle hiển thị đủ 2 dòng
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: RadioListTile<PaymentPackage>(
                title: const Text('Gói VIP(500.000/tháng)'),
                subtitle: const Text(
                  'Báo cáo chuyên sâu, gợi ý liệu trình, đặt lịch hẹn, quản lý khách hàng, hỗ trợ ưu tiên và các tính năng của gói cơ bản.',
                ),
                value: PaymentPackage.vip,
                groupValue: _selectedPackage,
                onChanged: _onPackageChanged,
                isThreeLine: true, // Cho phép subtitle hiển thị nhiều dòng hơn
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descCtrl,
              decoration: const InputDecoration(
                labelText: 'Mô tả',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            _loading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1e88e5),
                minimumSize: const Size.fromHeight(50),
              ),
              child: const Text('Thanh toán'),
            ),
            if (_checkoutUrl != null) ...[
              const SizedBox(height: 24),
              Expanded(
                child: WebViewWidget(
                  controller: WebViewController()
                    ..setJavaScriptMode(JavaScriptMode.unrestricted)
                    ..loadRequest(Uri.parse(_checkoutUrl!)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}


class PaymentHistoryPage extends StatefulWidget {
  const PaymentHistoryPage({Key? key}) : super(key: key);

  @override
  State<PaymentHistoryPage> createState() => _PaymentHistoryPageState();
}

class _PaymentHistoryPageState extends State<PaymentHistoryPage> {
  List<dynamic> _history = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _loading = true);
    final res = await http.get(Uri.parse('$basePaymentUrl/history'));
    setState(() => _loading = false);
    if (res.statusCode == 200) {
      _history = jsonDecode(res.body) as List<dynamic>;
      setState(() {});
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lấy lịch sử thất bại (${res.statusCode})')),
      );
    }
  }

  String _formatDate(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    return '${dt.day}/${dt.month}/${dt.year} '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử thanh toán'),
        backgroundColor: const Color(0xFFcde9cc),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _history.length,
        itemBuilder: (ctx, i) {
          final e = _history[i] as Map<String, dynamic>;
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 6),
            child: ListTile(
              title: Text('Mã: ${e['orderCode']} – ${e['amount']} đ'),
              subtitle: Text(
                'Trạng thái: ${e['status']}\n'
                    'Ngày tạo: ${_formatDate(e['createdAt'])}'
                    '${e.containsKey('updatedAt') ? '\nCập nhật: ${_formatDate(e['updatedAt'])}' : ''}',
              ),
              isThreeLine: true,
              trailing: Icon(
                e['statusCode'] == 'SUCCESS'
                    ? Icons.check_circle
                    : e['statusCode'] == 'PENDING'
                    ? Icons.hourglass_top
                    : Icons.error,
                color: e['statusCode'] == 'SUCCESS'
                    ? Colors.green
                    : e['statusCode'] == 'PENDING'
                    ? Colors.orange
                    : Colors.red,
              ),
            ),
          );
        },
      ),
    );
  }
}