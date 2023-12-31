import 'dart:developer';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:url_launcher/url_launcher.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  Barcode? result;
  QRViewController? controller;
  bool isPaused = false;
  bool isDialogShown = false;
  late bool isValidURL;

  // In order to get hot reload to work we need to pause the camera if the platform
  // is android, or resume the camera if the platform is iOS.
  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller!.pauseCamera();
    } else if (Platform.isIOS) {
      controller!.resumeCamera();
    }
  }

  void _onQRViewCreated(QRViewController controller) {
    setState(() {
      this.controller = controller;
    });

    controller.scannedDataStream.listen((scanData) {
      if (!isDialogShown) {
        setState(() {
          result = scanData;
        });
        if (result != null) {
          _showResults();
        }
      }
    });
  }

  void _showResults(){
    isDialogShown = true;   // Set the flag to true to prevent repeated dialogs
    isValidURL = Uri.parse('${result?.code}').isAbsolute;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('${describeEnum(result!.format).toUpperCase()} found!'),
          content: Text('${result?.code}'),
          actions: [
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: isValidURL ? () => _launchUrl() : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF139C9A),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text('Open', style: TextStyle(color: Colors.deepPurple[50]),),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      isDialogShown = false;
                      controller?.resumeCamera();
                      isPaused = false;
                      setState(() {});
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple[50],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: const BorderSide(width: 1.5, color: Color(0xFF139C9A)),
                      ),
                    ),
                    child: const Text('OK', style: TextStyle(color: Color(0xFF139C9A)),),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );

    controller?.pauseCamera();   // Pause scanning when the dialog is shown
    isPaused = true;
    setState(() {});
  }

  Future<void> _launchUrl() async {
    Uri url = Uri.parse('${result!.code}');

    if (!await launchUrl(url)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          Expanded(
            child: Stack(
              children: [
                QRView(
                  key: qrKey,
                  onQRViewCreated: _onQRViewCreated,
                  overlay: QrScannerOverlayShape(
                    borderColor: const Color(0xFF139C9A),
                    borderRadius: 10,
                    borderLength: 30,
                    borderWidth: 10,
                    cutOutSize: 305,
                  ),
                  onPermissionSet: (ctrl, p) => _onPermissionSet(context, ctrl, p),
                ),
                Center(
                  child: Lottie.asset('assets/animations/scanner.json', animate: !isPaused),
                ),
                Positioned(
                  top: MediaQuery.of(context).size.height / 1.3,
                  left: MediaQuery.of(context).size.width / 3,
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () async {
                          await controller?.toggleFlash();
                          setState(() {});
                        },
                        icon: const Icon(Icons.flashlight_on, size: 35, color: Color(0xFF139C9A),),
                      ),
                      IconButton(
                        onPressed: () async {
                          await controller?.flipCamera();
                          setState(() {});
                        },
                        icon: const Icon(Icons.flip_camera_ios, size: 35, color: Color(0xFF139C9A),),
                      ),
                      IconButton(
                        onPressed: () async{
                          isPaused ? await controller?.resumeCamera() : await controller?.pauseCamera();
                          isPaused = !isPaused;
                          setState(() {});
                        },
                        icon: const Icon(CupertinoIcons.qrcode_viewfinder, size: 35, color: Color(0xFF139C9A),),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _onPermissionSet(BuildContext context, QRViewController ctrl, bool p) {
    log('${DateTime.now().toIso8601String()}_onPermissionSet $p');
    if (!p) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('no Permission')),
      );
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}