import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:tech_world_networking_types/tech_world_networking_types.dart';
import 'package:tech_world_game_server/bot_user.dart';

/// All of the user connections are kept by the [ClientConnectionsService] object,
/// which keeps a map of rooms, each containing WebSocketChannels to userIds.
///
/// When a user connection is added or removed the [OtherPlayersMessage] is broadcast
/// only to users in the same room.
class ClientConnectionsService {
  // We can constructor inject the message handler function used by shelf_web_socket
  ClientConnectionsService([Function(WebSocketChannel)? messageHandler]) {
    _messageHandler = messageHandler ?? defaultMessageHandler;
  }

  /// Map of roomId -> (WebSocketChannel -> NetworkUser)
  final rooms = <String, Map<WebSocketChannel, NetworkUser>>{};

  /// Reverse lookup: WebSocketChannel -> roomId (for cleanup on disconnect)
  final _connectionRooms = <WebSocketChannel, String>{};

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
          final roomId = jsonData['roomId'] as String;
          print(
              'server received: $jsonString \nAdding user to room $roomId & broadcasting');
          _addAndBroadcast(webSocket, NetworkUser.fromJson(jsonData['user']), roomId);
        } else if (jsonData['type'] == DepartureMessage.jsonType) {
          print(
              'server received: $jsonString \nRemoving user & broadcasting other player list');
          _removeAndBroadcast(webSocket);
        } else if (jsonData['type'] == OtherUsersMessage.jsonType) {
          final roomId = _connectionRooms[webSocket];
          if (roomId != null) {
            print('server received: $jsonString, broadcasting other users info to room $roomId');
            _broadcastOtherUsers(roomId);
          }
        } else if (jsonData['type'] == PlayerPathMessage.jsonType) {
          final roomId = jsonData['roomId'] as String;
          print('server received: $jsonString, broadcasting to room $roomId');
          _broadcastPlayerPath(jsonData as Map<String, Object?>, roomId);
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

  void _addAndBroadcast(WebSocketChannel ws, NetworkUser user, String roomId) {
    // Ensure room exists
    rooms.putIfAbsent(roomId, () => {});
    
    // Add user to room
    rooms[roomId]![ws] = user;
    _connectionRooms[ws] = roomId;
    
    _broadcastOtherUsers(roomId);
    _sendBotPosition(ws, roomId);
  }

  /// Sends the bot's position to a newly connected player.
  void _sendBotPosition(WebSocketChannel ws, String roomId) {
    final botPathMessage = PlayerPathMessage(
      userId: botUser.id,
      roomId: roomId,
      points: [botPosition],
      directions: [],
    );
    ws.sink.add(jsonEncode(botPathMessage.toJson()));
  }

  void _removeAndBroadcast(WebSocketChannel ws) {
    final roomId = _connectionRooms.remove(ws);
    if (roomId != null && rooms.containsKey(roomId)) {
      rooms[roomId]!.remove(ws);
      
      // Clean up empty rooms
      if (rooms[roomId]!.isEmpty) {
        rooms.remove(roomId);
      } else {
        _broadcastOtherUsers(roomId);
      }
    }
  }

  void _broadcastOtherUsers(String roomId) {
    final roomConnections = rooms[roomId];
    if (roomConnections == null) return;
    
    for (final ws in roomConnections.keys) {
      // make the "other players" list for this player and send
      final users = roomConnections.values.toSet();
      users.remove(roomConnections[ws]!);
      users.add(botUser); // Always include the bot
      final message = jsonEncode(OtherUsersMessage(users: users));
      ws.sink.add(message);
    }
  }

  void _broadcastPlayerPath(JsonMap jsonData, String roomId) {
    final roomConnections = rooms[roomId];
    if (roomConnections == null) return;
    
    var playerPathMessage = PlayerPathMessage.fromJson(jsonData);
    for (final ws in roomConnections.keys) {
      if (roomConnections[ws]!.id != playerPathMessage.userId) {
        ws.sink.add(jsonEncode(playerPathMessage.toJson()));
      }
    }
  }
}
