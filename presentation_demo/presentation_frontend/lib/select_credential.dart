import 'dart:async';
import 'dart:convert';

import 'package:dart_ssi/credentials.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:presentation_frontend/show_presentation.dart';

class SelectCredentialScreen extends StatefulWidget {
  final List<String> credentialTypes;
  final String presentationId;

  const SelectCredentialScreen(
      {Key? key, required this.credentialTypes, required this.presentationId})
      : super(key: key);

  @override
  State<SelectCredentialScreen> createState() => _SelectCredentialState();
}

class _SelectCredentialState extends State<SelectCredentialScreen> {
  late Timer t;
  bool waiting = false;

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
        title: const Text('Credential auswählen'),
      ),
      body: Center(
        child: waiting
            ? const Text('Warte auf Antwort')
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                      'Wähle das Credential, das dein Gegenüber vorzeigen kann:',
                      style: TextStyle(fontSize: 20)),
                  const SizedBox(
                    height: 20,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                        widget.credentialTypes.length,
                        (index) => ElevatedButton(
                            onPressed: () {
                              get(Uri.parse(
                                  'http://localhost:8080/typeRequest/${widget.presentationId}/${widget.credentialTypes[index]}'));
                              setState(() {
                                waiting = true;
                              });
                            },
                            child: Text(
                              widget.credentialTypes[index],
                              style: const TextStyle(fontSize: 15),
                            ))),
                  )
                ],
              ),
      ),
    );
  }
}
