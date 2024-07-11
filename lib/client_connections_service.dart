import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:tech_world_networking_types/tech_world_networking_types.dart';

/// All of the user connections are kept by the [ClientConnectionsService] object,
/// which keeps a map of [WebSocketChannel]s to userIds.
///
/// When a user connection is added or removed the [OtherPlayerIds] is broadcast.
class ClientConnectionsService {
  // We can constructor inject the message handler function used by shelf_web_socket
  ClientConnectionsService([Function(WebSocketChannel)? messageHandler]) {
    _messageHandler = messageHandler ?? defaultMessageHandler;
  }

  final presenceMap = <WebSocketChannel, NetworkUser>{};

  // We keep the handler function as a member so that different handlers can
  // be constructor injected.
  late final Function(WebSocketChannel) _messageHandler;

  // The default function that [_messageHandler] is set to.
  void defaultMessageHandler(WebSocketChannel webSocket) {
    // Now attach a listener to the websocket that will perform the ongoing logic
    webSocket.stream.listen(
      (jsonString) {
        final jsonData = jsonDecode(jsonString as String);
        // If a user is announcing their presence, store the webSocket against the
        // userId and broadcast the current connections
        if (jsonData['type'] == ArrivalMessage.jsonType) {
          print(
              'server received: $jsonString \nAdding user & broadcasting other player list');
          _addAndBroadcast(webSocket, NetworkUser.fromJson(jsonData['user']));
        } else if (jsonData['type'] == OtherPlayersMessage.jsonType) {
          print('server received: $jsonString, broadcasting other player ids');
          _broadcastOtherPlayers();
        } else if (jsonData['type'] == PlayerPathMessage.jsonType) {
          print('server received: $jsonString, broadcasting');
          _broadcastPlayerPath(jsonData as Map<String, Object?>);
        } else {
          throw Exception('Unknown json type in websocket stream: $jsonData');
        }
      },
      onError: (error) {
        print(error);
        webSocket.sink.add('$error');
      },
      onDone: () {
        _removeAndBroadcast(webSocket);
      },
    );
  }

  Function(WebSocketChannel) get messageHandler => _messageHandler;

  void _addAndBroadcast(WebSocketChannel ws, NetworkUser user) {
    presenceMap[ws] = user;
    _broadcastOtherPlayers();
  }

  void _removeAndBroadcast(WebSocketChannel ws) {
    presenceMap.remove(ws);
    _broadcastOtherPlayers();
  }

  void _broadcastOtherPlayers() {
    for (final ws in presenceMap.keys) {
      // make the "other players" list for this player and send
      final users = presenceMap.values.toSet();
      users.remove(presenceMap[ws]!);
      final message = jsonEncode(OtherPlayersMessage(users: users));
      ws.sink.add(message);
    }
  }

  void _broadcastPlayerPath(JsonMap jsonData) {
    var playerPathMessage = PlayerPathMessage.fromJson(jsonData);
    for (final ws in presenceMap.keys) {
      if (presenceMap[ws]!.id != playerPathMessage.userId) {
        ws.sink.add(jsonEncode(playerPathMessage.toJson()));
      }
    }
  }
}
