import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:async';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({Key? key}) : super(key: key);

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  late List<CameraDescription> _cameras;
  late CameraController _controller;
  int _selected = 0;
  String imagePath = "";

  @override
  void initState() {
    super.initState();
    setupCamera();
  }

  Future<void> setupCamera() async {
    await [
      Permission.camera,
    ].request();
    _cameras = await availableCameras();

    _controller = CameraController(_cameras[_selected], ResolutionPreset.max);
    _controller.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {});
    }).catchError((Object e) {
      if (e is CameraException) {
        switch (e.code) {
          case 'CameraAccessDenied':
            // Handle access errors here.
            break;
          default:
            // Handle other errors here.
            break;
        }
      }
    });
  }

  toggleCamera() async {
    int newSelected = (_selected + 1) % _cameras.length;
    _selected = newSelected;

    var controller =
        await CameraController(_cameras[_selected], ResolutionPreset.max);
    setState(() => _controller = controller);
  }

  void takePhoto() async {
    try {
      final image = await _controller.takePicture();
      setState(() {
        imagePath = image.path;
        //TODO: save image path to backend
      });
    } catch (e) {
      print(e);
    }
  }

  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: EdgeInsets.only(top: 80.0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromARGB(255, 237, 86, 86),
              Color.fromARGB(77, 237, 86, 86)
            ], // Adjust colors as needed
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0.0, 0.5], // Adjust stops as needed
            tileMode: TileMode.clamp,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: TextButton.styleFrom(
                      backgroundColor: Color.fromARGB(0, 0, 0, 0)),
                  child: Row(
                    children: [
                      Padding(
                        padding: EdgeInsets.only(right: 8.0),
                        child: SvgPicture.asset(
                          "assets/icons/back.svg",
                          width: 6,
                          height: 14,
                          colorFilter: ColorFilter.mode(
                              Color.fromARGB(255, 96, 67, 91), BlendMode.srcIn),
                        ),
                      ),
                      Text(
                        "Leave Photo",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                Spacer(),
                ElevatedButton(
                  onPressed: () {},
                  child: Text(
                    "Challenge",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                )
              ],
            ),
            Text(
              "Remember this moment with a photo!",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            imagePath == ""
                ? Container(
                    width: 600,
                    height: 600,
                    child: AspectRatio(
                      aspectRatio: _controller.value.aspectRatio,
                      child: CameraPreview(_controller),
                    ),
                  )
                : Container(
                    width: 600,
                    height: 600,
                    child: Image.file(
                      File(imagePath),
                    ),
                  ),
            IconButton(
              onPressed: takePhoto,
              icon: SvgPicture.asset('assets/icons/Shutter.svg'),
            ),
            // Image.file(),
          ],
        ),
      ),
    );
  }
}
