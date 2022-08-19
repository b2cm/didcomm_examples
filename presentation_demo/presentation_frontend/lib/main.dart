import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:presentation_frontend/render_qr.dart';

const List<String> tabValues = [
  'DresdenPass ausstellen',
  'Eintritt Museum',
  'DresdenPass mit Discover Feature'
];
const List<String> requestStrings = ['dresden', 'museum', 'discover_dd'];

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Presentation Request',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Presentation Request'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Wrap(
          children: List.generate(
              tabValues.length,
              (index) => ElevatedButton(
                  onPressed: () async {
                    var oobUrl = await get(Uri.parse(
                        'http://localhost:8080/oobMessage/${requestStrings[index]}'));
                    var res = jsonDecode(oobUrl.body);
                    Navigator.of(context)
                        .push(MaterialPageRoute(builder: (context) {
                      return QrRenderer(
                        oobUrl: res['oob'],
                        presentationId: res['id'],
                      );
                    }));
                  },
                  child: Text(tabValues[index]))),
        ),
      ),
      // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
