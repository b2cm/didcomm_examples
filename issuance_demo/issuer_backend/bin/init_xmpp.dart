import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:console/console.dart';
import 'package:image/image.dart' as image;
import 'package:xmpp_stone/src/logger/Log.dart';
import 'package:xmpp_stone/xmpp_stone.dart' as xmpp;

import 'didcomm_message_handler.dart';

/// Instantiate xmpp-connection as described in example of xmpp_stone
xmpp.Connection init() {
  Log.logLevel = LogLevel.DEBUG;
  Log.logXmpp = false;

  var userAtDomain = 'testuser2@localhost';
  var password = 'passwort';
  var jid = xmpp.Jid.fromFullJid(userAtDomain);
  var account = xmpp.XmppAccountSettings(
      userAtDomain, jid.local, jid.domain, password, 5222,
      resource: 'xmppstone');

  var connection = xmpp.Connection(account);
  connection.connect();
  xmpp.MessagesListener messagesListener = ExampleMessagesListener();
  ExampleConnectionStateChangedListener(connection, messagesListener);

  var presenceManager = xmpp.PresenceManager.getInstance(connection);
  presenceManager.subscriptionStream.listen((streamEvent) {
    if (streamEvent.type == xmpp.SubscriptionEventType.REQUEST) {
      presenceManager.acceptSubscription(streamEvent.jid);
    }
  });
  return connection;
}

class ExampleConnectionStateChangedListener
    implements xmpp.ConnectionStateChangedListener {
  late xmpp.Connection _connection;
  late xmpp.MessagesListener _messagesListener;
  late StreamSubscription<String> subscription;

  ExampleConnectionStateChangedListener(
      xmpp.Connection connection, xmpp.MessagesListener messagesListener) {
    _connection = connection;
    _messagesListener = messagesListener;
    _connection.connectionStateStream.listen(onConnectionStateChanged);
  }

  @override
  void onConnectionStateChanged(xmpp.XmppConnectionState state) {
    if (state == xmpp.XmppConnectionState.Ready) {
      print('connection ready');
      print(_connection.authenticated);
      print(_connection.isOpened());

      var vCardManager = xmpp.VCardManager(_connection);
      vCardManager.getSelfVCard().then((vCard) {
        if (vCard != null) {}
      });
      var messageHandler = xmpp.MessageHandler.getInstance(_connection);
      var rosterManager = xmpp.RosterManager.getInstance(_connection);
      messageHandler.messagesStream.listen(_messagesListener.onNewMessage);
      sleep(const Duration(seconds: 1));
      var receiver = 'testuser@localhost';
      var receiverJid = xmpp.Jid.fromFullJid(receiver);
      rosterManager.addRosterItem(xmpp.Buddy(receiverJid)).then((result) {
        if (result.description != null) {}
      });
      sleep(const Duration(seconds: 1));
      vCardManager.getVCardFor(receiverJid).then((vCard) {
        if (vCard != null) {
          if (vCard != null && vCard.image != null) {
            var file = File('test456789.jpg')
              ..writeAsBytesSync(image.encodeJpg(vCard.image!));
          }
        }
      });
      var presenceManager = xmpp.PresenceManager.getInstance(_connection);
      presenceManager.presenceStream.listen(onPresence);
    }
  }

  void onPresence(xmpp.PresenceData event) {
    print('on Presence');
  }
}

Stream<String> getConsoleStream() {
  return Console.adapter.byteStream().map((bytes) {
    var str = ascii.decode(bytes);
    str = str.substring(0, str.length - 1);
    return str;
  });
}

class ExampleMessagesListener implements xmpp.MessagesListener {
  @override
  void onNewMessage(xmpp.MessageStanza? message) {
    if (message != null) {
      if (message.body != null) {
        // Only expected message types are didcomm messages. -> See didcomm_message_handler.dart
        handleDidcommMessage(message.body!);
      }
    }
  }
}
