import 'package:dart_ssi/credentials.dart';
import 'package:flutter/material.dart';
import 'package:presentation_frontend/main.dart';

class ShowPresentation extends StatelessWidget {
  final VerifiablePresentation presentation;

  const ShowPresentation({Key? key, required this.presentation})
      : super(key: key);

  List<Widget> buildCredSubject(Map<String, dynamic> subject,
      [String? before]) {
    List<Widget> children = [];
    subject.forEach((key, value) {
      if (key != 'id') {
        if (value is Map<String, dynamic>) {
          List<Widget> subs = buildCredSubject(value, key);
          children.addAll(subs);
        } else {
          children.add(Text('${before != null ? '$before.' : ''}$key: $value'));
        }
      }
    });
    return children;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Übermittelte Credentials'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children:
              List.generate(presentation.verifiableCredential.length, (index) {
            var vc = presentation.verifiableCredential[index];
            return Card(
              child: Column(
                children: [
                      Text(
                        vc.type.firstWhere(
                            (element) => element != 'VerifiableCredential'),
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      Text(
                          'Gültigkeit: ${vc.issuanceDate.day}.${vc.issuanceDate.month}.${vc.issuanceDate.year} - '
                          '${vc.expirationDate == null ? 'unbestimmt' : '${vc.expirationDate!.day}.${vc.expirationDate!.month}.${vc.expirationDate!.year}'}  '),
                      const SizedBox(
                        height: 10,
                      )
                    ] +
                    buildCredSubject(
                        vc.credentialSubject as Map<String, dynamic>),
              ),
            );
          }),
        ),
      ),
      persistentFooterButtons: [
        TextButton(
            onPressed: () {
              Navigator.of(context).pushReplacement(MaterialPageRoute(
                  builder: (context) =>
                      const MyHomePage(title: 'Presentation Request')));
            },
            child: const Text('Ok'))
      ],
    );
  }
}
