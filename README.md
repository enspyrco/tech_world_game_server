# Tech World Game Server

WebSocket server for Tech World that manages player connections and broadcasts movement/presence messages to all connected clients.

Built using [shelf](https://pub.dev/packages/shelf) and [shelf_web_socket](https://pub.dev/packages/shelf_web_socket).

## Features

- Manages WebSocket connections for multiple players
- Broadcasts player presence (arrivals/departures)
- Relays player movement paths to other connected clients
- SSL/TLS support for secure WebSocket connections (WSS)

## Prerequisites

- Dart SDK 3.0.0+
- SSL certificates for production deployment

## Setup

```bash
dart pub get
```

## Running

### Development

```bash
dart run bin/server.dart
```

The server requires SSL certificates at `/app/cert.pem` and `/app/key.pem`. For local development, you may need to modify these paths or generate self-signed certificates.

### VS Code Launch Configuration

```json
{
  "name": "ws_game_server",
  "request": "launch",
  "type": "dart",
  "program": "bin/server.dart"
}
```

### Testing Connection

```bash
curl -i -N -H "Connection: Upgrade" -H "Upgrade: websocket" -H "Host: localhost" -H "Origin: http://localhost" -H "Sec-WebSocket-Version: 13" -H "Sec-WebSocket-Key: SGVsbG8sIHdvcmxkIQ==" http://localhost:8080
```

## Testing

```bash
dart test
```

## Architecture

- **bin/server.dart**: Entry point, creates shelf server with SSL on port 443
- **lib/client_connections_service.dart**: Manages WebSocket connections, handles message routing
- **lib/locator.dart**: Service locator for dependency injection

### Message Flow

1. Client connects via WebSocket
2. Client sends `arrival` message with user info
3. Server stores connection and broadcasts `other_users` to all clients
4. Server relays `player_path` messages to other connected clients
5. On disconnect, server broadcasts updated `other_users` list

## Deployment

### Deploying to GCP Compute Engine

The CI/CD pipeline automatically deploys to a Compute Engine VM when you push a tagged commit:

```bash
git tag v1.0.0 && git push --tags
```

**How it works:**
1. Push a tagged commit
2. GitHub Actions builds the Docker image and pushes to Artifact Registry
3. The workflow SSHs into the VM and updates the running container

**VM Details:**
- Instance: `instance-20251007-053239`
- Zone: `us-central1-a`
- Machine type: `e2-micro`

**Required GCP Permissions for GitHub Actions service account:**
- `roles/artifactregistry.writer` - push images to Artifact Registry
- `roles/compute.instanceAdmin.v1` - SSH into the VM
- `roles/iap.tunnelResourceAccessor` - tunnel through IAP (if enabled)

**Setup References:**
- [Setup Workload Identity Federation for GitHub Actions](https://www.notion.so/enspyr-resources/Setup-Workload-Identity-Federation-for-GitHub-Actions-dea8dc31ff704efda562376047e7a965)
- [Create a Compute Engine VM](https://www.notion.so/enspyr-resources/Create-a-Compute-Engine-VM-dc44c9b90ad64e3b8148d5ba1858fdac)

## Dependencies

- `shelf`: HTTP server framework
- `shelf_web_socket`: WebSocket support for shelf
- `web_socket_channel`: WebSocket abstractions
- `tech_world_networking_types`: Shared message types
