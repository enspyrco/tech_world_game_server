import 'dart:convert';
import 'dart:io';

import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:tech_world_game_server/client_connections_service.dart';
import 'package:tech_world_networking_types/tech_world_networking_types.dart';
import 'package:test/test.dart';

// Bot user is always included in other_players messages
const botUserJson = '{"id":"bot-claude","displayName":"Claude"}';
const botPathJson = '{"type":"player_path","userId":"bot-claude","points":[{"x":200.0,"y":200.0}],"directions":[]}';

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
          // First client gets bot only, then bot position, then client2 joins
          '{"type":"other_players","users":[$botUserJson]}',
          botPathJson,
          '{"type":"other_players","users":[{"id":"2","displayName":"name2"},$botUserJson]}',
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
          '{"type":"other_players","users":[{"id":"1","displayName":"name1"},$botUserJson]}',
          botPathJson,
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
          '{"type":"other_players","users":[$botUserJson]}',
          botPathJson,
          '{"type":"other_players","users":[{"id":"2","displayName":"name2"},$botUserJson]}',
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
          '{"type":"other_players","users":[{"id":"1","displayName":"name1"},$botUserJson]}',
          botPathJson,
        ],
      ),
    );

    await server.close();
  });

  test('DepartureMessage removes client and broadcasts updated player list', () async {
    final service = ClientConnectionsService();
    final server = await shelf_io.serve(
        webSocketHandler(service.messageHandler), 'localhost', 0);

    final client1 = await WebSocket.connect('ws://localhost:${server.port}');
    client1.add(
      jsonEncode(
        ArrivalMessage(NetworkUser(id: '1', displayName: 'name1')).toJson(),
      ),
    );

    final client2 = await WebSocket.connect('ws://localhost:${server.port}');
    client2.add(
      jsonEncode(
        ArrivalMessage(NetworkUser(id: '2', displayName: 'name2')).toJson(),
      ),
    );

    // Wait for connections to be established
    await Future.delayed(const Duration(milliseconds: 50));

    // Client 2 sends departure message
    client2.add(
      jsonEncode(DepartureMessage('2').toJson()),
    );

    // Client 1 should receive: bot only, bot position, client2 joined, client2 left
    expect(
      client1,
      emitsInOrder([
        '{"type":"other_players","users":[$botUserJson]}',
        botPathJson,
        '{"type":"other_players","users":[{"id":"2","displayName":"name2"},$botUserJson]}',
        '{"type":"other_players","users":[$botUserJson]}',
      ]),
    );

    await server.close();
  });

  test('client disconnect triggers removal and broadcast', () async {
    final service = ClientConnectionsService();
    final server = await shelf_io.serve(
        webSocketHandler(service.messageHandler), 'localhost', 0);

    final client1 = await WebSocket.connect('ws://localhost:${server.port}');
    client1.add(
      jsonEncode(
        ArrivalMessage(NetworkUser(id: '1', displayName: 'name1')).toJson(),
      ),
    );

    final client2 = await WebSocket.connect('ws://localhost:${server.port}');
    client2.add(
      jsonEncode(
        ArrivalMessage(NetworkUser(id: '2', displayName: 'name2')).toJson(),
      ),
    );

    // Wait for connections to be established
    await Future.delayed(const Duration(milliseconds: 50));

    // Client 2 disconnects abruptly
    await client2.close();

    // Client 1 should receive: bot only, bot position, client2 joined, client2 left
    expect(
      client1,
      emitsInOrder([
        '{"type":"other_players","users":[$botUserJson]}',
        botPathJson,
        '{"type":"other_players","users":[{"id":"2","displayName":"name2"},$botUserJson]}',
        '{"type":"other_players","users":[$botUserJson]}',
      ]),
    );

    await server.close();
  });

  test('PlayerPathMessage is not sent back to sender', () async {
    final service = ClientConnectionsService();
    final server = await shelf_io.serve(
        webSocketHandler(service.messageHandler), 'localhost', 0);

    final client1 = await WebSocket.connect('ws://localhost:${server.port}');
    client1.add(
      jsonEncode(
        ArrivalMessage(NetworkUser(id: '1', displayName: 'name1')).toJson(),
      ),
    );

    // Wait for connection
    await Future.delayed(const Duration(milliseconds: 50));

    // Client 1 sends a path message
    client1.add(
      jsonEncode(
        PlayerPathMessage(
          userId: '1',
          points: [Double2(x: 0, y: 0), Double2(x: 1, y: 1)],
          directions: ['downRight'],
        ),
      ),
    );

    // Client 1 should receive the initial other_players (with bot) and bot position,
    // NOT their own path message echoed back
    expect(
      client1,
      emitsInOrder([
        '{"type":"other_players","users":[$botUserJson]}',
        botPathJson,
      ]),
    );

    // Give time for any erroneous message to arrive
    await Future.delayed(const Duration(milliseconds: 100));

    await server.close();
  });
}
