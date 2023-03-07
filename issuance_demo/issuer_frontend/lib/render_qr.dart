import 'dart:async';

import 'package:flutter/foundation.dart';
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
  bool isMobile = false;

  @override
  void initState() {
    super.initState();

    isMobile = kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.android);

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
              : isMobile
                  ? ElevatedButton(
                      onPressed: () async {
                        var launched = await launchUrlString(widget.oobUrl);
                        if (!launched) {
                          throw Exception('Could not launch ${widget.oobUrl}');
                        }
                      },
                      child: const Text('Id-Ideal Wallet öffnen'))
                  : QrImage(
                      data: widget.oobUrl,
                      version: QrVersions.auto,
                      size: 600,
                    )),
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
