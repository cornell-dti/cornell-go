import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:game/gameplay/challenge_completed.dart';


// Camera capture for a challenge completion photo.
// On success, the primary action continues to [ChallengeCompletedPage]

class TakePhotoPage extends StatefulWidget {
  final String challengeId;

  const TakePhotoPage({
    super.key,
    required this.challengeId,
  });

  @override
  State<TakePhotoPage> createState() => _TakePhotoPageState();
}

class _TakePhotoPageState extends State<TakePhotoPage> {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  String? _capturedImagePath;
  bool _isLoadingCamera = true;
  bool _cameraPermissionDenied = false;
  String? _cameraError;

  @override
  void initState() {
    super.initState();
    _setupCamera();
  }

  Future<void> _setupCamera() async {
    setState(() {
      _isLoadingCamera = true;
      _cameraPermissionDenied = false;
      _cameraError = null;
    });

    final status = await Permission.camera.request();
    if (!status.isGranted) {
      if (!mounted) return;
      setState(() {
        _isLoadingCamera = false;
        _cameraPermissionDenied = true;
      });
      return;
    }

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (!mounted) return;
        setState(() {
          _isLoadingCamera = false;
          _cameraError = 'No camera is available on this device.';
        });
        return;
      }

      final selectedCamera = cameras.first;
      final controller = CameraController(
        selectedCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      final initializeFuture = controller.initialize();

      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _controller = controller;
        _initializeControllerFuture = initializeFuture;
        _capturedImagePath = null;
      });

      await initializeFuture;
      if (!mounted) return;

      setState(() {
        _isLoadingCamera = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingCamera = false;
        _cameraError = 'Unable to open the camera. Please try again.';
      });
    }
  }

  Future<void> _capturePhoto() async {
    final controller = _controller;
    final initializeFuture = _initializeControllerFuture;
    if (controller == null || initializeFuture == null) return;

    try {
      await initializeFuture;
      final image = await controller.takePicture();
      if (!mounted) return;
      setState(() {
        _capturedImagePath = image.path;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not capture photo. Please retry.')),
      );
    }
  }

  void _retakePhoto() {
    setState(() {
      _capturedImagePath = null;
    });
  }

  void _saveAndContinue() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ChallengeCompletedPage(
          challengeId: widget.challengeId,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F5F1),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text(
          'Take a picture',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_isLoadingCamera) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_cameraPermissionDenied) {
      return _DeniedState(
        onTryAgain: _setupCamera,
      );
    }

    if (_cameraError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            _cameraError!,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
        ),
      );
    }

    if (_capturedImagePath != null) {
      return _PreviewState(
        imagePath: _capturedImagePath!,
        onRetake: _retakePhoto,
        onSaveToAlbum: _saveAndContinue,
      );
    }

    final controller = _controller;
    final initializeFuture = _initializeControllerFuture;
    if (controller == null || initializeFuture == null) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: FutureBuilder<void>(
                future: initializeFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    return CameraPreview(controller);
                  }
                  return const Center(child: CircularProgressIndicator());
                },
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 24, top: 8),
          child: GestureDetector(
            onTap: _capturePhoto,
            child: Container(
              width: 78,
              height: 78,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE95755), width: 4),
              ),
              child: const Center(
                child: CircleAvatar(
                  radius: 28,
                  backgroundColor: Color(0xFFE95755),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PreviewState extends StatelessWidget {
  final String imagePath;
  final VoidCallback onRetake;
  final VoidCallback onSaveToAlbum;

  const _PreviewState({
    required this.imagePath,
    required this.onRetake,
    required this.onSaveToAlbum,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(
                File(imagePath),
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onSaveToAlbum,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE95755),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Save to Album',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: onRetake,
            child: const Text(
              'Retake',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}

class _DeniedState extends StatelessWidget {
  final VoidCallback onTryAgain;

  const _DeniedState({
    required this.onTryAgain,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Camera access is required to take your completion photo.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onTryAgain,
              child: const Text('Try Again'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: openAppSettings,
              child: const Text('Open Settings'),
            ),
          ],
        ),
      ),
    );
  }
}
