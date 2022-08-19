import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:issuer_frontend/render_qr.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ausstellen',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Ausstellen'),
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
  List<String> typeList = [];
  late Future _initF;

  @override
  void initState() {
    super.initState();
    _initF = getList();
  }

  Future<bool> getList() async {
    var res = await get(Uri.parse('http://localhost:8081/getTypeList'));
    Map<String, dynamic> jsonBody = jsonDecode(res.body);
    typeList = jsonBody['types'];
    setState(() {});
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Credential-Auswahl'),
      ),
      body: Center(
        child: Wrap(
            children: List.generate(
                typeList.length,
                (index) => ElevatedButton(
                    onPressed: () async {
                      var oobUrl = await get(Uri.parse(
                          'http://localhost:8081/oobMessage/${typeList[index]}'));
                      var res = jsonDecode(oobUrl.body);
                      Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (context) {
                        return QrRenderer(
                          oobUrl: res['oob'],
                          presentationId: res['id'],
                        );
                      }));
                    },
                    child: Text(typeList[index])))),
      ),
    );
  }
}
