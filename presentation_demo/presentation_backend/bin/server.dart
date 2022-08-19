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
import 'presentaion_definitions.dart';

// Configure routes.
final _router = Router()
  ..get('/oobMessage/<type>', _buildOobMessage)
  ..get('/requestMessage/<messageId>', _getOfferMessage)
  ..get('/presentation/<id>', _getPresentation)
  ..get('/feature/<type>', _askForFeature)
  ..post('/receive', _receivePresentation)
  ..get('/typeRequest/<requestId>/<type>', _handleType);

// configure directory of frontend
final Handler _staticHandler = createStaticHandler(
    "..${Platform.pathSeparator}presentation_frontend${Platform.pathSeparator}build${Platform.pathSeparator}web",
    defaultDocument: "index.html");

late int port;
final String serverUrl = 'http://localhost';

final WalletStore wallet = WalletStore('.${Platform.pathSeparator}wallet');

late MessageHandler xmppHandler;

final String serviceXmpp = 'xmpp:testuser2@localhost';
final String serviceHttp = 'http://localhost:8080/receive';

late String issuerDid;

late String connectionDid;

Map<String, DidcommMessage> requestMessages = {};
Map<String, String> typeMapping = {};
Map<String, List<String>> credentialLists = {
  'dresden': [
    'Wohngeldbescheid',
    'ALG2Bescheid',
    'Kinderzuschlag',
    'Altersgrundsicherung',
    'Jugendhilfe',
    'Asylleistungen'
  ],
  'museum': ['Studierendenausweis', 'Schülerausweis', 'Rentennachweis']
};

final Map<String, PresentationDefinition> definitions = {
  'dresden': dresdenPass,
  'museum': museum,
  'Wohngeldbescheid': wohngeld,
  'ALG2Bescheid': alg2,
  'Kinderzuschlag': kinderzuschlag,
  'Altersgrundsicherung': alter,
  'Jugendhilfe': jugend,
  'Asylleistungen': asyl
};

Map<String, Map<String, dynamic>> presentations = {};
Map<String, Map<String, dynamic>> otherPartyInfo = {};

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

  // initialize xmpp-connection (see init_xmpp.dart)
  var connection = init();
  xmppHandler = MessageHandler.getInstance(connection);

  // Use any available host or container IP (usually `0.0.0.0`).
  final ip = InternetAddress.anyIPv4;

  // Configure a pipeline that logs requests.
  final Cascade _cascade = Cascade().add(_router).add(_staticHandler);

  // For running in containers, we respect the PORT environment variable.
  port = int.parse(Platform.environment['PORT'] ?? '8080');
  final server = await serve(_cascade.handler, ip, port);
  print('Server listening on port ${server.port}');
}

Response _askForFeature(Request request, String type) {
  var requestId = Uuid().v4();

  var query = QueryMessage(id: requestId, from: connectionDid, replyTo: [
    serviceHttp,
    serviceXmpp
  ], queries: [
    Query(
        featureType: FeatureType.attachmentFormat,
        match: AttachmentFormat.presentationDefinition2.value)
  ]);
  requestMessages[requestId] = query;
  typeMapping[requestId] = type;
  var oob = OutOfBandMessage(
      from: connectionDid,
      attachments: [Attachment(data: AttachmentData(json: query.toJson()))],
      replyTo: [serviceXmpp, serviceHttp]);

  return Response.ok(
      jsonEncode({'oob': oob.toUrl('http', 'wallet.de', ''), 'id': requestId}),
      headers: {'Content-Type': 'application/json'});
}

Response _buildOobMessage(Request givenRequest, String type) {
  if (type == 'discover_dd') {
    return _askForFeature(givenRequest, 'dresden');
  }
  var definition = definitions[type];
  var oobId = Uuid().v4();
  var requestId = Uuid().v4();
  var challenge = Uuid().v4();
  print('oobId : $oobId');
  print('RequestId: $requestId');
  var request = RequestPresentation(
      id: requestId,
      threadId: requestId,
      parentThreadId: oobId,
      from: connectionDid,
      replyTo: [
        serviceXmpp,
        serviceHttp
      ],
      presentationDefinition: [
        PresentationDefinitionWithOptions(
            presentationDefinition: definition!,
            domain: 'Testservice',
            challenge: challenge)
      ]);

  requestMessages[requestId] = request;

  var oob = OutOfBandMessage(id: oobId, from: connectionDid, attachments: [
    Attachment(
        data: AttachmentData(
            links: ['$serverUrl:$port/requestMessage/$requestId'],
            hash: 'ghwef'))
  ], replyTo: [
    serviceHttp,
    serviceXmpp
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

Response _getPresentation(Request request, String id) {
  var presentation = presentations.remove(id);
  if (presentation == null) {
    return Response.notFound('Cannot find Presentation');
  }
  return Response.ok(jsonEncode(presentation),
      headers: {'Content-Type': 'application/json'});
}

Future<Response> _receivePresentation(Request request) async {
  handleDidcommMessage(await request.readAsString());
  return Response.ok('');
}

Response _handleType(Request request, String requestId, String type) {
  var challenge = Uuid().v4();
  var definition = definitions[type];
  print('RequestId: $requestId');
  var request = RequestPresentation(
      id: requestId,
      threadId: requestId,
      from: connectionDid,
      replyTo: [
        serviceXmpp,
        serviceHttp
      ],
      presentationDefinition: [
        PresentationDefinitionWithOptions(
            presentationDefinition: definition!,
            domain: 'Testservice',
            challenge: challenge)
      ]);

  requestMessages[requestId] = request;

  var other = otherPartyInfo[requestId];
  send(other!['to']!, request, other['replyUrl']!);
  return Response.ok('');
}
