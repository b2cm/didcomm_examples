import 'dart:io';

import 'package:dart_ssi/credentials.dart';
import 'package:dart_ssi/did.dart';
import 'package:dart_ssi/didcomm.dart';
import 'package:http/http.dart';
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
  } else if (plain.type == 'https://didcomm.org/empty/1.0') {
    if (plain.ack != null) {
      running.remove(plain.threadId);
      print('this is an ack for ${plain.ack}, thread: ${plain.threadId}');
    }
  }
}

void handleProposeCredential(ProposeCredential message) async {
  var f = File('example/propose.json');
  f.openSync(mode: FileMode.write);
  f.writeAsStringSync(message.toString());
  print('Received ProposeCredential: thread: ${message.threadId}');
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

  f = File('example/offer2.json');
  f.openSync(mode: FileMode.write);
  f.writeAsStringSync(offer.toString());

  send(message.from!, offer, message.replyUrl!);
}

void handleRequestCredential(RequestCredential message) async {
  print('received RequestCredential, thread: ${message.threadId}');

  var f = File('example/request.json');
  f.openSync(mode: FileMode.write);
  f.writeAsStringSync(message.toString());
  var credential = message.detail!.first.credential;
  // sign the requested credential (normally we had to check before that, that the data in it is the same we offered)
  var signed = await signCredential(wallet, credential,
      challenge: message.detail!.first.options.challenge);

  // issue the credential
  var issue = IssueCredential(
      threadId: message.threadId ?? message.id,
      from: connectionDid,
      to: [message.from!],
      replyTo: [serviceHttp, serviceXmpp],
      credentials: [VerifiableCredential.fromJson(signed)]);
  f = File('example/issue.json');
  f.openSync(mode: FileMode.write);
  f.writeAsStringSync(issue.toString());
  send(message.from!, issue, message.replyUrl!);
}

void send(String to, DidcommMessage message, String replyUrl) async {
  print('Send ${(message is DidcommPlaintextMessage) ? message.type : ''}');

  // get keys for recipient
  var ddo = (await resolveDidDocument(to));

  var f = File('example/ddo_short.json');
  f.openSync(mode: FileMode.write);
  f.writeAsStringSync(ddo.toString());

  ddo = ddo.convertAllKeysToJwk().resolveKeyIds();
  f = File('example/ddo_long.json');
  f.openSync(mode: FileMode.write);
  f.writeAsStringSync(ddo.toString());

  var myKey = await wallet.getPrivateKeyForConnectionDidAsJwk(connectionDid);

  // encrypt message
  var encrypted = DidcommEncryptedMessage.fromPlaintext(
      senderPrivateKeyJwk: myKey!,
      recipientPublicKeyJwk: [
        (ddo.keyAgreement!.first as VerificationMethod).publicKeyJwk!
      ],
      plaintext: message);

  f = File('example/encrypted.json');
  f.openSync(mode: FileMode.write);
  f.writeAsStringSync(encrypted.toString());

  // send message over xmpp or http
  if (replyUrl.startsWith('xmpp')) {
    xmppHandler.sendMessage(
        Jid.fromFullJid('testuser@localhost'), encrypted.toString());
  } else if (replyUrl.startsWith('http')) {
    post(Uri.parse(replyUrl), body: encrypted.toString());
  }
}
