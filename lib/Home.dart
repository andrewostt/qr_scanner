import 'dart:developer';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:url_launcher/url_launcher.dart';

class QRViewExample extends StatefulWidget {
  //const QRViewExample({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _QRViewExampleState();
}

class _QRViewExampleState extends State<QRViewExample> {

  Barcode? result;
  QRViewController? controller;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');

  bool cameraOnPause = false;

  // In order to get hot reload to work we need to pause the camera if the platform
  // is android, or resume the camera if the platform is iOS.
  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller!.pauseCamera();
    }
    controller!.resumeCamera();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.indigo,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Ionicons.qr_code,),
            SizedBox(width: 2,),
            Text('ScanFlutter'),
          ],
        ),
      ),
      body: Column(
        children: <Widget>[
          Expanded(flex: 4, child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(25),
                child: _buildQrView(context),
            ),
          )),
          Expanded(
            flex: 1,
            child: FittedBox(
              fit: BoxFit.contain,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  if (result != null)
                    Text('')
                  else
                    const Text(''),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Container(
                        margin: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                            color: Colors.deepPurpleAccent,
                            border: Border.all(
                              color: Colors.cyanAccent,
                              width: 1,),
                            borderRadius: BorderRadius.all(
                                Radius.circular(24)),
                            boxShadow: [BoxShadow(blurRadius: 32,color: Colors.cyan.shade500 ,offset: Offset(1,3))]
                        ),
                        child: MaterialButton(
                            splashColor: Colors.transparent,
                            highlightColor: Colors.transparent,
                            enableFeedback: false,
                            onPressed: () async {
                              if(cameraOnPause == true) {
                                await controller?.resumeCamera();
                                cameraOnPause = false;
                              } else {
                                await controller?.pauseCamera();
                                cameraOnPause = true;
                              }
                            },
                            child: FutureBuilder(
                              future: controller?.resumeCamera(),
                              builder: (context, snapshot) {
                                return Row(
                                  children: [
                                    Icon(Icons.play_arrow, color: Colors.white,),
                                    Icon(Icons.pause, color: Colors.white,),
                                  ],
                                );
                                /*if(cameraOnPause == true) {
                                  return Icon(Icons.play_arrow);
                                } else {
                                  return Icon(Icons.pause);
                                }
                                */
                              },
                            )),
                      ),
                      Container(
                        margin: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: Colors.deepPurpleAccent,
                          border: Border.all(
                              color: Colors.cyanAccent,
                              width: 1,),
                          borderRadius: BorderRadius.all(
                              Radius.circular(24)),
                          boxShadow: [BoxShadow(blurRadius: 32,color: Colors.cyan.shade500 ,offset: Offset(1,3))]
                        ),
                        child: MaterialButton(
                            splashColor: Colors.transparent,
                            highlightColor: Colors.transparent,
                            enableFeedback: false,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                            onPressed: () async {
                              await controller?.toggleFlash();
                              setState(() {});
                            },
                            child: FutureBuilder(
                              future: controller?.getFlashStatus(),
                              builder: (context, snapshot) {
                                if('${snapshot.data}' == 'true') {
                                  return Icon(Ionicons.flash_outline, color: Colors.white,);
                                } else {
                                  return Icon(Ionicons.flash_off_outline, color: Colors.white,);
                                }
                              },
                            )),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildQrView(BuildContext context) {
    // For this example we check how width or tall the device is and change the scanArea and overlay accordingly.
    var scanArea = (MediaQuery.of(context).size.width < 250 ||
        MediaQuery.of(context).size.height < 400)
        ? 150.0
        : 300.0;
    // To ensure the Scanner view is properly sizes after rotation
    // we need to listen for Flutter SizeChanged notification and update controller
    return QRView(
      key: qrKey,
      onQRViewCreated: _onQRViewCreated,
      overlay: QrScannerOverlayShape(
          borderColor: Colors.cyanAccent,
          borderRadius: 7,
          borderLength: 35,
          borderWidth: 7,
          cutOutSize: scanArea),
      onPermissionSet: (ctrl, p) => _onPermissionSet(context, ctrl, p),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    setState(() {
      this.controller = controller;
    });
    controller.scannedDataStream.listen((scanData) async {
      controller.pauseCamera();
      if (await canLaunch(scanData.code.toString())) {
        await launch(scanData.code.toString());
        controller.resumeCamera();
      }else {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('could not find virable url'),
              content: SingleChildScrollView(
                child: ListView(
                  children: [
                    Text('${describeEnum(scanData.format)}'),
                    Text('${scanData.code}'),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () {
                  Navigator.pop(context);
                  },
                child: Text('ok'),)
              ],
            );
          }
        );
      }
      setState(() {
        result = scanData;
      });
    });
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