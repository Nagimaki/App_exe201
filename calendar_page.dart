import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

const String baseUrl = 'https://web-production-9f7d5.up.railway.app';

class Appointment {
  final int id;
  final int userId;
  final DateTime date;
  final String service;
  final String time;

  Appointment({
    required this.id,
    required this.userId,
    required this.date,
    required this.service,
    required this.time,
  });
}

class BookingPage extends StatefulWidget {
  final int userId;
  const BookingPage({Key? key, required this.userId}) : super(key: key);

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  DateTime _focused = DateTime.now();
  DateTime? _selected;
  CalendarFormat _format = CalendarFormat.month;
  List<Appointment> _allAppts = [];
  final Map<DateTime, List<Appointment>> _apptMap = {};

  final List<String> services = [
    'Khám da',
    'Điều trị mụn',
    'Tư vấn chăm sóc da',
  ];
  final List<String> times = [
    '9:00',
    '10:30',
    '13:00',
    '14:30',
    '16:00',
    '17:30',
  ];
  String? _selService;
  String? _selTime;

  @override
  void initState() {
    super.initState();
    _fetchAppointments();
  }

  Future<void> _fetchAppointments() async {
    final res = await http.get(Uri.parse('$baseUrl/appointments'));
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as List;
      _allAppts = data.map((e) => Appointment(
        id: e['id'],
        userId: e['userId'],      // Sửa key từ 'user_id' thành 'userId'
        date: DateTime.parse(e['date']),
        service: e['service'],
        time: e['time'],
      )).toList();
      _buildMap();
    }
  }

  void _buildMap() {
    _apptMap.clear();
    for (var a in _allAppts.where((e) => e.userId == widget.userId)) {
      final d = DateTime(a.date.year, a.date.month, a.date.day);
      if (_apptMap[d] == null) _apptMap[d] = [];
      _apptMap[d]!.add(a);
    }
    setState(() {});
  }

  List<Appointment> _getAppointments(DateTime day) {
    return _apptMap[DateTime(day.year, day.month, day.day)] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đặt chỗ'),
        backgroundColor: Colors.teal,
      ),
      body: Column(
        children: [
          // Format selector
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: CalendarFormat.values.map((f) {
                final isSelected = _format == f;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text(
                      f.name,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: Colors.teal,
                    onSelected: (v) {
                      if (v) setState(() => _format = f);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          // Calendar
          Expanded(
            child: TableCalendar<Appointment>(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2100, 12, 31),
              focusedDay: _focused,
              calendarFormat: _format,
              selectedDayPredicate: (d) => isSameDay(_selected, d),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selected = selectedDay;
                  _focused = focusedDay;
                });
                _showBookingDialog(selectedDay);
              },
              eventLoader: _getAppointments,
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, day, appts) {
                  if (appts.isNotEmpty) {
                    return const Positioned(
                      bottom: 1,
                      child: Icon(
                        Icons.circle,
                        size: 6,
                        color: Colors.grey,
                      ),
                    );
                  }
                  return const SizedBox();
                },
              ),
            ),
          ),
          // List appointments for selected day
          if (_selected != null)
            ..._getAppointments(_selected!).map((a) {
              return ListTile(
                title: Text('${a.service} - ${a.time}'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () async {
                    await http.delete(Uri.parse('$baseUrl/appointments/${a.id}'));
                    _fetchAppointments();
                  },
                ),
              );
            }).toList(),
        ],
      ),
    );
  }

  void _showBookingDialog(DateTime day) {
    final dayAppts = _getAppointments(day);
    _selService = null;
    _selTime = null;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: Text('Lịch ngày ${day.day}/${day.month}/${day.year}'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Chọn dịch vụ:'),
                Wrap(
                  spacing: 8,
                  children: services.map((s) {
                    final color = Colors.teal;
                    return ChoiceChip(
                      avatar: _selService == s ? const Icon(Icons.check, color: Colors.white) : null,
                      label: Text(s, style: const TextStyle(color: Colors.white)),
                      selected: _selService == s,
                      onSelected: (v) => setStateDialog(() => _selService = v ? s : null),
                      selectedColor: color,
                      backgroundColor: color.withOpacity(0.4),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                const Text('Chọn giờ:'),
                Wrap(
                  spacing: 8,
                  children: times.map((t) {
                    return ChoiceChip(
                      avatar: _selTime == t ? const Icon(Icons.check, color: Colors.white) : null,
                      label: Text(t, style: const TextStyle(color: Colors.white)),
                      selected: _selTime == t,
                      onSelected: (v) => setStateDialog(() => _selTime = v ? t : null),
                      selectedColor: Colors.teal,
                      backgroundColor: Colors.teal.withOpacity(0.4),
                    );
                  }).toList(),
                ),
                const Divider(height: 24),
                const Text('Lịch đã đặt:', style: TextStyle(fontWeight: FontWeight.bold)),
                ...dayAppts.map((a) => ListTile(
                  title: Text('${a.service} - ${a.time}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      await http.delete(Uri.parse('$baseUrl/appointments/${a.id}'));
                      Navigator.pop(context);
                      _fetchAppointments();
                    },
                  ),
                )),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Đóng')),
            ElevatedButton(
              onPressed: (_selService != null && _selTime != null)
                  ? () async {
                await http.post(
                  Uri.parse('$baseUrl/appointments'),
                  headers: {'Content-Type': 'application/json'},
                  body: jsonEncode({
                    'userId': widget.userId, // Sửa key từ 'user_id' thành 'userId'
                    'date': day.toIso8601String(),
                    'service': _selService,
                    'time': _selTime,
                  }),
                );
                Navigator.pop(context);
                _fetchAppointments();
              }
                  : null,
              child: const Text('Thêm mới'),
            ),
          ],
        ),
      ),
    );
  }
}
