import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class ResultPage extends StatefulWidget {
  final String imagePath;
  const ResultPage({Key? key, required this.imagePath}) : super(key: key);

  @override
  State<ResultPage> createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage> {
  bool _loading = false;
  Map<String, dynamic>? _result;

  @override
  void initState() {
    super.initState();
    _fetchResult();
  }

  Future<void> _fetchResult() async {
    setState(() => _loading = true);

    final uri = Uri.parse('http://13.215.161.51/predict');
    final request = http.MultipartRequest('POST', uri)
      ..files.add(await http.MultipartFile.fromPath('image', widget.imagePath));

    try {
      final streamed = await request.send().timeout(Duration(seconds: 30));
      final response = await http.Response.fromStream(streamed);
      if (response.statusCode == 200) {
        setState(() => _result = jsonDecode(response.body));
      } else {
        _showError('Server trả về mã ${response.statusCode}');
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Lỗi: $msg')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Kết quả phân tích da')),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : _result == null
          ? Center(child: Text('Không có dữ liệu'))
          : ResultContent(result: _result!, imagePath: widget.imagePath),
    );
  }
}

class ResultContent extends StatelessWidget {
  final Map<String, dynamic> result;
  final String imagePath;
  const ResultContent({Key? key, required this.result, required this.imagePath}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final skin = result['skin_prediction'] as Map<String, dynamic>;
    final products = result['recommended_products'] as List<dynamic>;

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ImageSection(imagePath: imagePath),
          SizedBox(height: 16),
          SkinAnalysisSection(skin: skin),
          SizedBox(height: 16),
          ProductListSection(products: products),
        ],
      ),
    );
  }
}

class ImageSection extends StatelessWidget {
  final String imagePath;
  const ImageSection({Key? key, required this.imagePath}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          height: 200,
          child: Image.file(
            File(imagePath),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stack) =>
                Center(child: Icon(Icons.broken_image, size: 48)),
          ),
        ),
      ),
    );
  }
}

class SkinAnalysisSection extends StatelessWidget {
  final Map<String, dynamic> skin;
  const SkinAnalysisSection({Key? key, required this.skin}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final verbal = skin['verbal_analysis'] as String? ?? '';
    final types = (skin['skin_types'] as List<dynamic>).join(', ');
    final concerns = (skin['skin_concern_keywords'] as List<dynamic>).join(', ');

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Đánh giá:',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            MarkdownBody(data: verbal),
            SizedBox(height: 8),
            Text('Loại da: $types'),
            Text('Vấn đề da: $concerns'),
          ],
        ),
      ),
    );
  }
}

class ProductListSection extends StatelessWidget {
  final List<dynamic> products;
  const ProductListSection({Key? key, required this.products}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sản phẩm đề xuất',
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        ...products.map((data) {
          final prod = data as Map<String, dynamic>;
          return Card(
            margin: EdgeInsets.symmetric(vertical: 6),
            elevation: 2,
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () async {
                final url = prod['product_link'] as String?;
                if (url != null) {
                  final uri = Uri.parse(url);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri,
                        mode: LaunchMode.externalApplication);
                  }
                }
              },
              child: Padding(
                padding: EdgeInsets.all(8),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: SizedBox(
                        width: 80,
                        height: 80,
                        child: Image.network(
                          prod['product_image'] ?? '',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stack) =>
                              Center(child: Icon(Icons.broken_image)),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            prod['product_name'] ?? '',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          SizedBox(height: 4),
                          Text(
                            prod['product_description'] ?? '',
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
