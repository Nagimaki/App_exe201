import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AIAssistantPage extends StatefulWidget {
  final int userId;
  const AIAssistantPage({Key? key, required this.userId}) : super(key: key);

  @override
  State<AIAssistantPage> createState() => _AIAssistantPageState();
}

class _AIAssistantPageState extends State<AIAssistantPage> {
  List<_Message> _msgs = [];
  final TextEditingController _ctrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchMessages();
  }

  Future<void> _fetchMessages() async {
    final res = await http.get(Uri.parse('https://web-production-9f7d5.up.railway.app/messages'));
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as List;
      _msgs = data.map((m) => _Message(
        id: m['id'],
        sender: m['sender_id'],
        text: m['content'],
      )).toList();
      setState(() {});
    }
  }

  Future<void> _send() async {
    final txt = _ctrl.text.trim();
    if (txt.isEmpty) return;
    await http.post(
      Uri.parse('https://web-production-9f7d5.up.railway.app/messages'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'sender_id': widget.userId, 'content': txt}),
    );
    _ctrl.clear();
    _fetchMessages();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat box'),
        backgroundColor: const Color(0xFFcde9cc),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _msgs.length,
              itemBuilder: (c, i) {
                final m = _msgs[i];
                return Align(
                  alignment: m.sender == widget.userId
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(12),
                    constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.7),
                    decoration: BoxDecoration(
                      color: m.sender == widget.userId
                          ? Colors.blue[200]
                          : Colors.grey[300],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(m.text),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    decoration: InputDecoration(
                      hintText: 'Nhập tin nhắn...',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24)),
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.green),
                  onPressed: _send,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Message {
  final int id;
  final int sender;
  final String text;
  _Message({required this.id, required this.sender, required this.text});
}
