import 'package:dart_ssi/credentials.dart';
import 'package:dart_ssi/did.dart';
import 'package:dart_ssi/didcomm.dart';
import 'package:http/http.dart';
import 'package:uuid/uuid.dart';
import 'package:xmpp_stone/xmpp_stone.dart';

import 'server.dart';

Future<DidcommMessage?> handleDidcommMessage(String m) async {
  // For now, we only expect encrypted messages
  var encrypted = DidcommEncryptedMessage.fromJson(m);
  // Therefore decrypt them
  var plain = await encrypted.decrypt(wallet);
  if (plain is! DidcommPlaintextMessage) throw Exception('Unexpected message');

  // handle the messages according to their type
  if (plain.type == 'https://didcomm.org/present-proof/3.0/presentation') {
    return handlePresentation(Presentation.fromJson(plain.toJson()));
  } else if (plain.type == DidcommMessages.discoverFeatureDisclose) {
    return handleDiscoverFeature(DiscloseMessage.fromJson(plain.toJson()));
  } else {
    return null;
  }
}

Future<DidcommMessage> send(
    String to, DidcommMessage message, String? replyUrl) async {
  print('Send ${(message is DidcommPlaintextMessage) ? message.type : ''}');

  // get keys for recipient
  var ddo =
      (await resolveDidDocument(to)).convertAllKeysToJwk().resolveKeyIds();
  var myKey = await wallet.getPrivateKeyForConnectionDidAsJwk(connectionDid);

  // encrypt message
  var encrypted = DidcommEncryptedMessage.fromPlaintext(
      senderPrivateKeyJwk: myKey!,
      recipientPublicKeyJwk: [
        (ddo.keyAgreement!.first as VerificationMethod).publicKeyJwk!
      ],
      plaintext: message);

  // send message over xmpp
  if (replyUrl != null) {
    if (replyUrl.startsWith('xmpp')) {
      xmppHandler.sendMessage(
          Jid.fromFullJid('testuser@localhost'), encrypted.toString());
    } else if (replyUrl.startsWith('http')) {
      post(Uri.parse(replyUrl), body: encrypted.toString());
    }
  }

  return encrypted;
}

Future<DidcommMessage?> handlePresentation(Presentation message) async {
  var vp = message.verifiablePresentation.first;
  print(message.threadId);
  var request = requestMessages[message.threadId];
  if (request is RequestPresentation) {
    var challenge = request.presentationDefinition.first.challenge;
    try {
      var verified = await verifyPresentation(vp, challenge);
      print(verified);
      presentations[message.threadId!] = {'presentation': vp.toJson()};

      return send(
          message.from!,
          EmptyMessage(
              threadId: message.threadId ?? message.id,
              from: connectionDid,
              to: [message.from!],
              ack: [message.id]),
          message.returnRoute == null ||
                  message.returnRoute == ReturnRouteValue.none
              ? determineReplyUrl(message.replyUrl, message.replyTo)
              : null);
    } catch (e) {
      print(e);
    }
  }

  return null;
}

Future<DidcommMessage>? handleDiscoverFeature(DiscloseMessage message) {
  print(message.disclosures);
  var requestId = message.threadId!;
  var type = typeMapping[requestId];
  if (message.disclosures.isNotEmpty) {
    var definition = definitions[type];

    var challenge = Uuid().v4();

    print('RequestId: $requestId');
    var request =
        RequestPresentation(threadId: requestId, from: connectionDid, replyTo: [
      serviceHttp,
      serviceXmpp
    ], presentationDefinition: [
      PresentationDefinitionWithOptions(
          presentationDefinition: definition!,
          domain: 'Testservice',
          challenge: challenge)
    ]);

    requestMessages[requestId] = request;

    return send(
        message.from!,
        request,
        message.returnRoute == null ||
                message.returnRoute == ReturnRouteValue.none
            ? determineReplyUrl(message.replyUrl, message.replyTo)
            : null);
  } else {
    presentations[requestId] = {'typeList': credentialLists[type]};
    otherPartyInfo[requestId] = {
      'to': message.from!,
      'replyUrl': message.replyUrl
    };
  }

  return null;
}

String? determineReplyUrl(String? replyUrl, List<String>? replyTo) {
  if (replyUrl != null) {
    return replyUrl;
  } else {
    if (replyTo == null) {
      return null;
    }
    for (var url in replyTo) {
      if (url.startsWith('http')) return url;
    }
  }
  return null;
}
