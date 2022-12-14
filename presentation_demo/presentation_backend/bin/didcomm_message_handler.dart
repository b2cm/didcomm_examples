import 'package:dart_ssi/credentials.dart';
import 'package:dart_ssi/did.dart';
import 'package:dart_ssi/didcomm.dart';
import 'package:http/http.dart';
import 'package:uuid/uuid.dart';
import 'package:xmpp_stone/xmpp_stone.dart';

import 'server.dart';

void handleDidcommMessage(String m) async {
  // For now, we only expect encrypted messages
  var encrypted = DidcommEncryptedMessage.fromJson(m);
  // Therefore decrypt them
  var plain = await encrypted.decrypt(wallet);
  if (plain is! DidcommPlaintextMessage) throw Exception('Unexpected message');

  // handle the messages according to their type
  if (plain.type ==
      'https://didcomm.org/issue-credential/3.0/propose-credential') {
    handleProposeCredential(ProposeCredential.fromJson(plain.toJson()));
  } else if (plain.type ==
      'https://didcomm.org/issue-credential/3.0/request-credential') {
    handleRequestCredential(RequestCredential.fromJson(plain.toJson()));
  } else if (plain.type == 'https://didcomm.org/reserved/2.0/empty') {
    if (plain.ack != null) {
      print('this is an ack for ${plain.ack}');
    }
  }

  // !!!The important part!!!rest is copy paste
  else if (plain.type == 'https://didcomm.org/present-proof/3.0/presentation') {
    handlePresentation(Presentation.fromJson(plain.toJson()));
  } else if (plain.type == DidcommMessages.discoverFeatureDisclose.value) {
    handleDiscoverFeature(DiscloseMessage.fromJson(plain.toJson()));
  }
}

void handleProposeCredential(ProposeCredential message) async {
  print('Received ProposeCredential');
  // it is expected that the wallet changes the did, the credential should be issued to
  var vcSubjectId = message.detail!.first.credential.credentialSubject['id'];
  for (var a in message.attachments!) {
    // to check, if the wallet controls the did it is expected to sign the attachment
    if (!(await a.data.verifyJws(vcSubjectId))) {
      throw Exception('not verifiable');
    }
  }

  // answer with offer credential message
  var offer = OfferCredential(
      threadId: message.threadId ?? message.id,
      detail: message.detail,
      from: connectionDid,
      to: [message.from!],
      replyTo: [serviceHttp, serviceXmpp]);

  send(message.from!, offer, message.replyUrl!);
}

void handleRequestCredential(RequestCredential message) async {
  print('received RequestCredential');
  var credential = message.detail!.first.credential;
  // sign the requested credential (normally we had to check before that, that the data in it is the same we offered)
  var signed = await signCredential(wallet, credential,
      challenge: message.detail!.first.options.challenge);

  // issue the credential
  var issue = IssueCredential(
      threadId: message.threadId ?? message.id,
      from: connectionDid,
      to: [message.from!],
      replyTo: [serviceXmpp, serviceHttp],
      credentials: [VerifiableCredential.fromJson(signed)]);

  send(message.from!, issue, message.replyUrl!);
}

void send(String to, DidcommMessage message, String replyUrl) async {
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
  if (replyUrl.startsWith('xmpp')) {
    xmppHandler.sendMessage(
        Jid.fromFullJid('testuser@localhost'), encrypted.toString());
  } else if (replyUrl.startsWith('http')) {
    post(Uri.parse(replyUrl), body: encrypted.toString());
  }
}

void handlePresentation(Presentation message) async {
  var vp = message.verifiablePresentation.first;
  print(message.threadId);
  var request = requestMessages[message.threadId];
  if (request is RequestPresentation) {
    var challenge = request.presentationDefinition.first.challenge;
    try {
      var verified = await verifyPresentation(vp, challenge);
      print(verified);
      presentations[message.threadId!] = {'presentation': vp.toJson()};
    } catch (e) {
      print(e);
    }
  }
}

void handleDiscoverFeature(DiscloseMessage message) {
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

    send(message.from!, request, message.replyUrl!);
  } else {
    presentations[requestId] = {'typeList': credentialLists[type]};
    otherPartyInfo[requestId] = {
      'to': message.from!,
      'replyUrl': message.replyUrl
    };
  }
}
