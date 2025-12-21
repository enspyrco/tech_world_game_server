# tech_world_game_server

_Using [shelf](https://pub.dev/packages/shelf) and [shelf_web_socket](https://pub.dev/packages/shelf_web_socket) for a serverless websocket server._

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

## CI/CD

### Deploying to Compute Engine

The CI/CD pipeline automatically deploys to a Compute Engine VM when you push a tagged commit.

**How it works:**
1. Push a tagged commit (e.g., `git tag v1.0.0 && git push --tags`)
2. GitHub Actions builds the Docker image and pushes to Artifact Registry
3. The workflow SSHs into the VM and updates the running container

**VM Details:**
- Instance: `instance-20251007-053239`
- Zone: `us-central1-a`
- Machine type: `e2-micro`

**Required GCP Permissions for the GitHub Actions service account:**
- `roles/artifactregistry.writer` - push images to Artifact Registry
- `roles/compute.instanceAdmin.v1` - SSH into the VM
- `roles/iap.tunnelResourceAccessor` - tunnel through IAP (if enabled)

**Setup References:**
- [Setup Workload Identity Federation for GitHub Actions](https://www.notion.so/enspyr-resources/Setup-Workload-Identity-Federation-for-GitHub-Actions-dea8dc31ff704efda562376047e7a965)
- [Create a Compute Engine VM](https://www.notion.so/enspyr-resources/Create-a-Compute-Engine-VM-dc44c9b90ad64e3b8148d5ba1858fdac)
