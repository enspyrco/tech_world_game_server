# tech_world_game_server

*Using [shelf](https://pub.dev/packages/shelf) and [shelf_web_socket](https://pub.dev/packages/shelf_web_socket) for a serverless websocket server.*

[Project Notes](https://enspyrco.notion.site/WS-Game-Server-c387081d4cc84c34b89bb92e1b78e48e)

## Running locally

We can debug with a launch configuration that runs `bin/server.dart`, eg:

```json
{
  "name": "ws_game_server",
  "request": "launch",
  "type": "dart",
  "program": "bin/server.dart"
},
```

You can use curl to test connecting (but you won't be able to send any data)

```sh
curl -i -N -H "Connection: Upgrade" -H "Upgrade: websocket" -H "Host: localhost" -H "Origin: http://localhost" -H "Sec-WebSocket-Version: 13" -H "Sec-WebSocket-Key: SGVsbG8sIHdvcmxkIQ==" http://localhost:8080
```

## Deploying to Cloud Run

[Setup Workload Identity Federation for GitHub Actions](https://www.notion.so/enspyr-resources/Setup-Workload-Identity-Federation-for-GitHub-Actions-dea8dc31ff704efda562376047e7a965)

[Build container image & deploy to Cloud Run in CI](https://www.notion.so/enspyr-resources/Build-container-image-deploy-to-Cloud-Run-in-CI-e99e4144cdf1460aad41a56aa5f45099)
