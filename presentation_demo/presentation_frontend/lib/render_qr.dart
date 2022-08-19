import 'dart:async';
import 'dart:convert';

import 'package:dart_ssi/credentials.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:presentation_frontend/select_credential.dart';
import 'package:presentation_frontend/show_presentation.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QrRenderer extends StatefulWidget {
  final String oobUrl;
  final String presentationId;
  const QrRenderer(
      {Key? key, required this.oobUrl, required this.presentationId})
      : super(key: key);
  @override
  State<QrRenderer> createState() => _QrRendererState();
}

class _QrRendererState extends State<QrRenderer> {
  late Timer t;
  void requestQRData() async {}

  @override
  void initState() {
    super.initState();
    t = Timer.periodic(const Duration(seconds: 5), (timer) async {
      var res = await get(Uri.parse(
          'http://localhost:8080/presentation/${widget.presentationId}'));
      if (res.statusCode == 200) {
        print('Antwort erhalten');
        t.cancel();
        Map<String, dynamic> decodedBody = jsonDecode(res.body);
        if (decodedBody.containsKey('presentation')) {
          Navigator.of(context).pushReplacement(MaterialPageRoute(
              builder: (context) => ShowPresentation(
                  presentation: VerifiablePresentation.fromJson(
                      decodedBody['presentation']))));
        } else if (decodedBody.containsKey('typeList')) {
          Navigator.of(context).pushReplacement(MaterialPageRoute(
              builder: (context) => SelectCredentialScreen(
                    credentialTypes: decodedBody['typeList'],
                    presentationId: widget.presentationId,
                  )));
        }
      } else {
        print('nix da');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ausstellen'),
      ),
      body: Center(
        child: QrImage(
          data: widget.oobUrl,
          version: QrVersions.auto,
        ),
      ),
    );
  }
}
