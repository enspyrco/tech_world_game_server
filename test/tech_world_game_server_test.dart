import 'dart:convert';
import 'dart:io';

import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:tech_world_game_server/client_connections_service.dart';
import 'package:tech_world_networking_types/tech_world_networking_types.dart';
import 'package:test/test.dart';

void main() {
  test('Receiving ArrivalMessages sends OtherPlayersMessage to clients',
      () async {
    final service = ClientConnectionsService();
    final server = await shelf_io.serve(
        webSocketHandler(service.messageHandler), 'localhost', 0);

    final client1 = await WebSocket.connect('ws://localhost:${server.port}');
    client1.add(
      jsonEncode(
        ArrivalMessage(NetworkUser(id: '1', displayName: 'name1')).toJson(),
      ),
    );

    expect(
      client1,
      emitsInOrder(
        [
          '{"type":"other_players","users":[]}',
          '{"type":"other_players","users":[{"id":"2","displayName":"name2"}]}',
        ],
      ),
    );

    final client2 = await WebSocket.connect('ws://localhost:${server.port}');
    client2.add(
      jsonEncode(
        ArrivalMessage(
          NetworkUser(id: '2', displayName: 'name2'),
        ).toJson(),
      ),
    );

    expect(
      client2,
      emitsInOrder(
        [
          '{"type":"other_players","users":[{"id":"1","displayName":"name1"}]}',
        ],
      ),
    );

    await server.close();
  });

  test('sends PlayerPathMessage to clients', () async {
    final service = ClientConnectionsService();
    final server = await shelf_io.serve(
        webSocketHandler(service.messageHandler), 'localhost', 0);

    final client1 = await WebSocket.connect('ws://localhost:${server.port}');
    client1.add(
      jsonEncode(
        ArrivalMessage(
          NetworkUser(id: '1', displayName: 'name1'),
        ).toJson(),
      ),
    );

    expect(
      client1,
      emitsInOrder(
        [
          '{"type":"other_players","users":[]}',
          '{"type":"other_players","users":[{"id":"2","displayName":"name2"}]}',
          '{"type":"player_path","userId":"2","points":[{"x":1.0,"y":1.0},{"x":1.0,"y":2.0}],"directions":["left","right"]}',
        ],
      ),
    );

    final client2 = await WebSocket.connect('ws://localhost:${server.port}');
    client2.add(
      jsonEncode(
        ArrivalMessage(
          NetworkUser(id: '2', displayName: 'name2'),
        ).toJson(),
      ),
    );

    client2.add(
      jsonEncode(
        PlayerPathMessage(
          userId: '2',
          points: [Double2(x: 1, y: 1), Double2(x: 1, y: 2)],
          directions: ['left', 'right'],
        ),
      ),
    );

    expect(
      client2,
      emitsInOrder(
        [
          '{"type":"other_players","users":[{"id":"1","displayName":"name1"}]}',
        ],
      ),
    );

    await server.close();
  });
}
