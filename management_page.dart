// lib/management_page.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

const String baseUrl = 'https://web-production-9f7d5.up.railway.app';

class Employee {
  final int id;
  final int userId;
  final String name;
  final String title;
  int totalShifts;
  int doneShifts;
  double rating;
  bool onTime;

  Employee({
    required this.id,
    required this.userId,
    required this.name,
    required this.title,
    this.totalShifts = 0,
    this.doneShifts = 0,
    this.rating = 0.0,
    this.onTime = true,
  });

  factory Employee.fromJson(Map<String, dynamic> json) => Employee(
    id: json['id'] as int,
    userId: json['userId'] as int,
    name: json['name'] as String? ?? '',
    title: json['title'] as String? ?? '',
    totalShifts: (json['totalShifts'] as int?) ?? 0,
    doneShifts: (json['doneShifts'] as int?) ?? 0,
    rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
    onTime: json['onTime'] as bool? ?? true,
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'title': title,
    'totalShifts': totalShifts,
    'doneShifts': doneShifts,
    'rating': rating,
    'onTime': onTime,
  };
}

class ManagementPage extends StatefulWidget {
  final int userId;
  final String role;

  const ManagementPage({
    Key? key,
    required this.userId,
    required this.role,
  }) : super(key: key);

  @override
  State<ManagementPage> createState() => _ManagementPageState();
}

class _ManagementPageState extends State<ManagementPage> {
  List<Employee> _employees = [];
  Employee? _myInfo;
  bool _loading = false;

  bool get isAdmin => widget.role == 'admin';

  @override
  void initState() {
    super.initState();
    if (isAdmin) {
      _loadEmployees();
    } else {
      _loadMyInfo();
    }
  }

  Future<void> _loadEmployees() async {
    setState(() => _loading = true);
    final res = await http.get(
      Uri.parse('$baseUrl/employees'),
      headers: {'X-User-Id': widget.userId.toString()},
    );
    setState(() => _loading = false);
    if (res.statusCode == 200) {
      final List<dynamic> data = jsonDecode(res.body);
      _employees = data.map((e) => Employee.fromJson(e)).toList();
      setState(() {});
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lấy nhân viên thất bại: ${res.statusCode}')),
      );
    }
  }

  Future<void> _loadMyInfo() async {
    setState(() => _loading = true);
    final res = await http.get(
      Uri.parse('$baseUrl/employees/${widget.userId}'),
      headers: {'Content-Type': 'application/json'},
    );
    setState(() => _loading = false);
    if (res.statusCode == 200) {
      _myInfo = Employee.fromJson(jsonDecode(res.body));
      setState(() {});
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không tìm thấy thông tin: ${res.statusCode}')),
      );
    }
  }

  Future<void> _addEmployee(
      String username, String password, String name, String title) async {
    final res = await http.post(
      Uri.parse('$baseUrl/employees'),
      headers: {
        'Content-Type': 'application/json',
        'X-User-Id': widget.userId.toString()
      },
      body: jsonEncode({
        'username': username,
        'password': password,
        'name': name,
        'title': title,
      }),
    );
    if (res.statusCode == 201) {
      _loadEmployees();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tạo nhân viên thất bại: ${res.statusCode}')),
      );
    }
  }

  Future<void> _updateEmployee(Employee e) async {
    final res = await http.put(
      Uri.parse('$baseUrl/employees/${e.id}'),
      headers: {
        'Content-Type': 'application/json',
        'X-User-Id': widget.userId.toString()
      },
      body: jsonEncode(e.toJson()),
    );
    if (res.statusCode == 200) {
      if (isAdmin) {
        _loadEmployees();
      } else {
        _loadMyInfo();
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cập nhật thất bại: ${res.statusCode}')),
      );
    }
  }

  Future<void> _deleteEmployee(int id) async {
    final res = await http.delete(
      Uri.parse('$baseUrl/employees/$id'),
      headers: {'X-User-Id': widget.userId.toString()},
    );
    if (res.statusCode == 200) {
      _loadEmployees();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Xóa thất bại: ${res.statusCode}')),
      );
    }
  }

  void _showAddDialog() {
    String username = '',
        password = '',
        name = '',
        title = '';
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Tạo tài khoản Nhân viên'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(labelText: 'Username'),
                onChanged: (v) => username = v,
              ),
              TextField(
                decoration: const InputDecoration(labelText: 'Password'),
                onChanged: (v) => password = v,
                obscureText: true,
              ),
              TextField(
                decoration: const InputDecoration(labelText: 'Họ tên'),
                onChanged: (v) => name = v,
              ),
              TextField(
                decoration: const InputDecoration(labelText: 'Chức danh'),
                onChanged: (v) => title = v,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _addEmployee(username, password, name, title);
            },
            child: const Text('Tạo'),
          ),
        ],
      ),
    );
  }

  void _showDetail(Employee e, {bool canEdit = true, bool canDelete = true}) {
    int tempTotal = e.totalShifts;
    int tempDone = e.doneShifts;
    bool tempOnTime = e.onTime;
    double tempRating = e.rating;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setStateDialog) {
          final percent = tempTotal > 0
              ? (tempDone / tempTotal * 100).toStringAsFixed(1)
              : '0';
          return AlertDialog(
            title: Text('Chi tiết: ${e.name}'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(radius: 30, child: Text(e.name[0])),
                  const SizedBox(height: 8),
                  Text(
                    e.name,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(e.title),
                  const Divider(),
                  ListTile(
                    title: const Text('Tổng ca'),
                    trailing: Text('$tempTotal'),
                    onTap: canEdit
                        ? () async {
                      final input =
                      await _showNumberInput(ctx, 'Tổng ca', tempTotal);
                      if (input != null) {
                        setStateDialog(() {
                          tempTotal = input;
                          if (tempDone > tempTotal) tempDone = tempTotal;
                        });
                      }
                    }
                        : null,
                  ),
                  ListTile(
                    title: const Text('Hoàn thành'),
                    trailing: Text('$tempDone'),
                    onTap: canEdit
                        ? () async {
                      final input = await _showNumberInput(
                          ctx, 'Ca hoàn thành', tempDone);
                      if (input != null && input <= tempTotal) {
                        setStateDialog(() => tempDone = input);
                      }
                    }
                        : null,
                  ),
                  ListTile(
                    title: const Text('Tỉ lệ'),
                    trailing: Text('$percent%'),
                  ),
                  SwitchListTile(
                    title: const Text('Đúng giờ'),
                    value: tempOnTime,
                    onChanged: canEdit
                        ? (v) => setStateDialog(() => tempOnTime = v)
                        : null,
                  ),
                  const SizedBox(height: 12),
                  const Text('Đánh giá sao:'),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: List.generate(5, (i) {
                      final idx = i + 1;
                      final filled = idx <= tempRating;
                      return GestureDetector(
                        onTap: canEdit
                            ? () => setStateDialog(() => tempRating = idx.toDouble())
                            : null,
                        child: Icon(
                          filled ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 32,
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
              if (canEdit)
                ElevatedButton(
                  onPressed: () {
                    e.totalShifts = tempTotal;
                    e.doneShifts = tempDone;
                    e.onTime = tempOnTime;
                    e.rating = tempRating;
                    Navigator.pop(ctx);
                    _updateEmployee(e);
                  },
                  child: const Text('Lưu'),
                ),
              if (canDelete)
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _deleteEmployee(e.id);
                  },
                  child: const Text('Xóa', style: TextStyle(color: Colors.red)),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<int?> _showNumberInput(
      BuildContext context, String title, int initial) async {
    final controller = TextEditingController(text: '$initial');
    int? result;
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Nhập $title'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: title),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () {
              final v = int.tryParse(controller.text.trim());
              if (v != null && v >= 0) result = v;
              Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isAdmin ? 'Quản lý Nhân viên' : 'Thông tin Cá nhân'),
        backgroundColor: const Color(0xFFcde9cc),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : isAdmin
          ? ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _employees.length,
        itemBuilder: (ctx, i) {
          final e = _employees[i];
          final percent = e.totalShifts > 0
              ? (e.doneShifts / e.totalShifts * 100).toStringAsFixed(1)
              : '0';
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 6),
            child: ListTile(
              leading: CircleAvatar(child: Text(e.name[0])),
              title: Text(e.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(e.title),
              trailing: Text('$percent% hoàn thành',
                  style: const TextStyle(color: Colors.green)),
              onTap: () => _showDetail(e, canEdit: true, canDelete: true),
              onLongPress: () => _deleteEmployee(e.id),
            ),
          );
        },
      )
          : _myInfo == null
          ? const Center(child: Text('Không có thông tin'))
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: ListTile(
            leading: CircleAvatar(child: Text(_myInfo!.name[0])),
            title: Text(_myInfo!.name,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(_myInfo!.title),
            onTap: () => _showDetail(_myInfo!, canEdit: true, canDelete: false),
          ),
        ),
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton(
        backgroundColor: const Color(0xFFcde9cc),
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: _showAddDialog,
      )
          : null,
    );
  }
}
