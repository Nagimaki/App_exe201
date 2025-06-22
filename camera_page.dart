import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'result_page.dart';

class CameraPage extends StatefulWidget {
  @override
  _CameraPageState createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> with WidgetsBindingObserver {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  int _selectedCameraIndex = 0; // Mặc định là rear, sẽ thay đổi sau khi lấy danh sách camera
  bool _isFlashOn = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Xử lý vòng đời ứng dụng
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      _cameraController!.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera(_selectedCameraIndex);
    }
  }

  /// Khởi tạo danh sách camera và chọn camera mặc định (nếu có camera trước thì chọn camera trước)
  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        // Nếu có camera trước (thường là index 1), thì chọn camera trước làm mặc định
        _selectedCameraIndex = _cameras!.length > 1 ? 1 : 0;
        await _initializeCamera(_selectedCameraIndex);
      }
    } catch (e) {
      print("Lỗi khi khởi tạo camera: $e");
    }
  }

  /// Khởi tạo camera với index cụ thể
  Future<void> _initializeCamera(int cameraIndex) async {
    // Giải phóng controller cũ nếu có
    await _cameraController?.dispose();
    _cameraController = CameraController(
      _cameras![cameraIndex],
      ResolutionPreset.medium, // Sử dụng preset medium cho tỷ lệ 3:4
      imageFormatGroup: ImageFormatGroup.yuv420, // Đảm bảo tương thích trên Android
    );

    try {
      await _cameraController!.initialize();

      // Nếu camera hiện tại là camera sau, thiết lập flash mặc định là off
      if (_cameras![cameraIndex].lensDirection == CameraLensDirection.back) {
        await _cameraController!.setFlashMode(FlashMode.off);
        _isFlashOn = false;
      }

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      print("Lỗi khi khởi tạo camera: $e");
    }
  }

  /// Chuyển đổi giữa camera trước và sau
  Future<void> _toggleCamera() async {
    if (_cameras != null && _cameras!.length > 1) {
      _selectedCameraIndex = (_selectedCameraIndex == 0) ? 1 : 0;
      await _initializeCamera(_selectedCameraIndex);
    }
  }

  /// Chuyển đổi chế độ flash (chỉ áp dụng cho camera sau)
  Future<void> _toggleFlash() async {
    if (_cameraController != null &&
        _cameraController!.value.isInitialized &&
        _cameras![_selectedCameraIndex].lensDirection == CameraLensDirection.back) {
      try {
        if (_isFlashOn) {
          await _cameraController!.setFlashMode(FlashMode.off);
        } else {
          await _cameraController!.setFlashMode(FlashMode.torch);
        }
        setState(() {
          _isFlashOn = !_isFlashOn;
        });
      } catch (e) {
        print("Lỗi khi chuyển flash: $e");
      }
    }
  }

  /// Chụp ảnh và chuyển sang màn hình kết quả
  void _captureImage(BuildContext context) async {
    if (_cameraController != null && _cameraController!.value.isInitialized) {
      try {
        final image = await _cameraController!.takePicture();
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ResultPage(imagePath: image.path),
            ),
          );
        }
      } catch (e) {
        print("Lỗi khi chụp ảnh: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    // Circle diameter cho overlay nếu cần (ở đây không ảnh hưởng trực tiếp đến preview)
    final circleDiameter = screenWidth * 0.9;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Nếu camera chưa khởi tạo, hiển thị loading indicator
          if (!_isCameraInitialized)
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),

          // Hiển thị Camera Preview với tỷ lệ 3:4
          if (_isCameraInitialized && _cameraController != null)
            Center(
              child: AspectRatio(
                aspectRatio: 3 / 4,
                child: CameraPreview(_cameraController!),
              ),
            ),

          // Overlay làm mờ vùng ngoài (nếu cần)
          Positioned.fill(
            child: CustomPaint(
              painter: CircleOverlayPainter(circleDiameter),
            ),
          ),

          // Nút chuyển đổi camera (góc trên bên phải)
          Positioned(
            top: 40,
            right: 20,
            child: IconButton(
              icon: const Icon(Icons.switch_camera, color: Colors.white, size: 32),
              onPressed: _toggleCamera,
            ),
          ),

          // Nút flash (chỉ hiển thị nếu camera hiện tại là rear)
          if (_cameras != null &&
              _cameras!.isNotEmpty &&
              _cameras![_selectedCameraIndex].lensDirection == CameraLensDirection.back)
            Positioned(
              bottom: 40,
              left: 20,
              child: IconButton(
                icon: Icon(
                  _isFlashOn ? Icons.flash_on : Icons.flash_off,
                  color: Colors.white,
                  size: 32,
                ),
                onPressed: _toggleFlash,
              ),
            ),

          // Nút chụp ảnh và hướng dẫn (ở dưới cùng, căn giữa)
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () => _captureImage(context),
                  child: const Icon(Icons.camera, size: 48, color: Colors.white),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Xin hãy định vị mình vào ống kính máy ảnh",
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Painter để tạo overlay (vùng tròn trong suốt, vùng ngoài mờ)
class CircleOverlayPainter extends CustomPainter {
  final double diameter;
  CircleOverlayPainter(this.diameter);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withOpacity(0.7);
    final center = Offset(size.width / 2, size.height / 2);
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addOval(Rect.fromCircle(center: center, radius: diameter / 2))
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
