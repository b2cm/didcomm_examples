import 'dart:convert';
import 'dart:io';

import 'package:dart_ssi/credentials.dart';
import 'package:dart_ssi/didcomm.dart';
import 'package:dart_ssi/wallet.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_static/shelf_static.dart';
import 'package:uuid/uuid.dart';
import 'package:xmpp_stone/xmpp_stone.dart';

import 'didcomm_message_handler.dart';
import 'init_xmpp.dart';

// Configure routes.
final _router = Router()
  ..get('/oobMessage/<type>', _buildOobMessage)
  ..get('/requestMessage/<messageId>', _getOfferMessage)
  ..post('/receive', _receivePresentation)
  ..get('/getTypeList', _getTypeList)
  ..get('/isRunning/<id>', _isRunning);

// configure directory of frontend
final Handler _staticHandler = createStaticHandler(
    '..${Platform.pathSeparator}issuer_frontend${Platform.pathSeparator}build${Platform.pathSeparator}web',
    defaultDocument: 'index.html');

late int port;
final String serverUrl = 'http://localhost';

final WalletStore wallet = WalletStore('.${Platform.pathSeparator}wallet');

late MessageHandler xmppHandler;

String serviceXmpp = 'xmpp:testuser2@localhost';
String serviceHttp = 'http://localhost:8081/receive';

late String issuerDid;

late String connectionDid;

Map<String, DidcommMessage> requestMessages = {};
List<String> running = [];

List<String> typeList = [];

void main(List<String> args) async {
  // open server-wallet
  await wallet.openBoxes('serverPassword');
  if (!wallet.isInitialized()) {
    await wallet.initialize(network: 'ropsten');
    await wallet.initializeIssuer(KeyType.ed25519);
  }

  var cDid = wallet.getConfigEntry('connectionDid');
  if (cDid == null) {
    cDid = await wallet.getNextConnectionDID(KeyType.x25519);
    await wallet.storeConfigEntry('connectionDid', cDid);
  }
  connectionDid = cDid;

  issuerDid = wallet.getStandardIssuerDid(KeyType.ed25519)!;

  print(wallet.getConfigEntry('certificate'));

  // initialize xmpp-connection (see init_xmpp.dart)
  var connection = init();
  xmppHandler = MessageHandler.getInstance(connection);

  //find all issuable credentials
  var dir = Directory('credential_templates');
  var fileList = dir.listSync();
  for (var f in fileList) {
    var filename = f.path.split(Platform.pathSeparator).last;
    var type = filename.split('.').first;
    typeList.add(type);
  }

  print('Existing credential types: $typeList');

  // Use any available host or container IP (usually `0.0.0.0`).
  final ip = InternetAddress.anyIPv4;

  // Configure a pipeline that logs requests.
  final Cascade _cascade = Cascade().add(_router).add(_staticHandler);

  // For running in containers, we respect the PORT environment variable.
  port = int.parse(Platform.environment['PORT'] ?? '8081');
  final server = await serve(_cascade.handler, ip, port);
  print('Server listening on port ${server.port}');
}

Response _buildOobMessage(Request givenRequest, String type) {
  var oobId = Uuid().v4();
  var requestId = Uuid().v4();
  var file = File('credential_templates${Platform.pathSeparator}$type.json');
  Map<String, dynamic> fileData = jsonDecode(file.readAsStringSync());

  var context = fileData.remove('@context');
  List<dynamic> contextList = ['https://www.w3.org/2018/credentials/v1'];
  if (context != null) {
    if (context is String) {
      contextList.add(context);
    } else {
      contextList.addAll(context);
    }
  }
  contextList.add({
    'certificate': {'@id': 'https://x509.org/certificate'}
  });
  fileData.remove('type');
  if (!fileData.containsKey('id')) {
    fileData['id'] = 'did:key:000';
  }

  print('oobId : $oobId');
  print('RequestId: $requestId');

  running.add(requestId);

  var vc = VerifiableCredential(
      context: contextList,
      type: ['VerifiableCredential', type],
      issuer: issuerDid,
      // issuer: {
      //   'id': issuerDid,
      //   'certificate': wallet.getConfigEntry('certificate')
      // },
      credentialSubject: fileData,
      issuanceDate: DateTime.now());

  var offer = OfferCredential(id: requestId, threadId: requestId, detail: [
    LdProofVcDetail(
        credential: vc,
        options: LdProofVcDetailOptions(proofType: 'Ed25519Signature'))
  ], replyTo: [
    serviceHttp,
    serviceXmpp
  ]);
  requestMessages[requestId] = offer;
  var oob = OutOfBandMessage(
      id: requestId,
      threadId: requestId,
      from: connectionDid,
      replyTo: [
        serviceHttp,
        serviceXmpp
      ],
      attachments: [
        Attachment(
            data: AttachmentData(
                links: ['http://localhost:8081/requestMessage/$requestId'],
                hash: 'ghjdw'))
      ]);

  return Response.ok(
      jsonEncode({'oob': oob.toUrl('http', 'wallet.de', ''), 'id': requestId}),
      headers: {'Content-Type': 'application/json'});
}

Response _getOfferMessage(Request request, String messageId) {
  var offer = requestMessages[messageId];
  if (offer == null) return Response.notFound('Cant find offer');

  return Response.ok(offer.toString(),
      headers: {'Content-Type': 'application/json'});
}

Future<Response> _receivePresentation(Request request) async {
  handleDidcommMessage(await request.readAsString());
  return Response.ok('');
}

Response _getTypeList(Request request) {
  return Response.ok(jsonEncode({'types': typeList}),
      headers: {'Content-Type': 'application/json'});
}

Response _isRunning(Request request, String id) {
  if (running.contains(id)) {
    return Response.ok('Ausstellprozess läuft');
  } else {
    return Response.notFound('Austellprozess beendet');
  }
}
