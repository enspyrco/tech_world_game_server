import 'dart:io';

import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:tech_world_game_server/locator.dart';

// For Google Cloud Run, set _hostname to '0.0.0.0'
const _hostname = '0.0.0.0';

void main() {
  // If there is no client connections service already provided, provide the default.
  final clientConnectionsService =
      Locator.provideDefaultClientConnectionsService();

  var handler = webSocketHandler(clientConnectionsService.messageHandler);

  // Create a SecurityContext for HTTPS
  final securityContext = SecurityContext()
    ..useCertificateChain('cert.pem') // Path to your certificate
    ..usePrivateKey('key.pem'); // Path to your private key

  shelf_io
      .serve(
    handler,
    _hostname,
    8080,
    securityContext: securityContext,
  )
      .then((server) {
    print('Serving at ws://${server.address.host}:${server.port}');
  });
}
