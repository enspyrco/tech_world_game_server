# Review Configuration

## Project Context
Tech World Game Server - WebSocket server managing multiplayer connections for Tech World game. Broadcasts player movement and presence messages.

## Tech Stack
- **Dart**: shelf, shelf_web_socket
- **SSL/TLS**: Let's Encrypt certificates
- **Docker**: Containerized deployment
- **GCP Compute Engine**: Production hosting

## Review Focus Areas
- WebSocket connection handling and cleanup
- Message broadcasting efficiency
- SSL certificate handling (must not be committed)
- Error handling and reconnection scenarios
- Bot user management

## Code Standards
- Dart: Follow lints rules
- Run `dart analyze --fatal-infos` before committing
- Ensure tests cover message flows

## Required Checks
- CI must pass (test job with analyze + test)
- No analyzer warnings (--fatal-infos)

## Security Notes
- SSL certificates are mounted from host, never baked into Docker image
- Certificates stored in /etc/letsencrypt on the VM
- Private keys must NEVER be committed to git
