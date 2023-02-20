import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:issuer_frontend/main.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher_string.dart';

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
  bool finished = false;

  @override
  void initState() {
    super.initState();
    print('init timer');
    t = Timer.periodic(const Duration(seconds: 5), (timer) async {
      var answer = await get(Uri.parse(
          'http://localhost:8081/isRunning/${widget.presentationId}'));
      if (answer.statusCode == 404) {
        t.cancel();
        finished = true;
        setState(() {});
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
        child: finished
            ? const Text('Credential erfolgreich ausgestellt')
            : Column(children: [
                QrImage(
                  data: widget.oobUrl,
                  version: QrVersions.auto,
                  size: 600,
                ),
                ElevatedButton(
                    onPressed: () async {
                      if (!await launchUrlString(widget.oobUrl)) {
                        throw Exception('Could not launch ${widget.oobUrl}');
                      }
                    },
                    child: const Text('Id-Ideal Wallet öffnen'))
              ]),
      ),
      persistentFooterButtons: [
        TextButton(
            onPressed: () {
              Navigator.of(context).pushReplacement(MaterialPageRoute(
                  builder: (context) => const MyHomePage(title: 'Ausstellen')));
            },
            child: const Text('Ok'))
      ],
    );
  }
}
