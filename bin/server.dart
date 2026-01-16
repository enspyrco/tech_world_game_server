import 'dart:io';

import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:tech_world_game_server/locator.dart';

// For Google Cloud Run, set _hostname to '0.0.0.0'
const _hostname = '0.0.0.0';

void main(List<String> args) {
  final useSSL = !args.contains('--no-ssl');

  // If there is no client connections service already provided, provide the default.
  final clientConnectionsService =
      Locator.provideDefaultClientConnectionsService();

  var handler = webSocketHandler(clientConnectionsService.messageHandler);

  if (useSSL) {
    // Create a SecurityContext for HTTPS/WSS (production)
    final securityContext = SecurityContext()
      ..useCertificateChain('/app/cert.pem')
      ..usePrivateKey('/app/key.pem');

    shelf_io
        .serve(
      handler,
      _hostname,
      443,
      securityContext: securityContext,
    )
        .then((server) {
      print('Serving at wss://${server.address.host}:${server.port}');
    });
  } else {
    // No SSL for local development
    shelf_io.serve(handler, _hostname, 8080).then((server) {
      print('Serving at ws://${server.address.host}:${server.port}');
    });
  }
}
