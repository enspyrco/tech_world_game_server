# Slides Configuration

## Project Context
Tech World Game Server - WebSocket backend for multiplayer game synchronization.

## Brand Colors
```json
{
  "primary": { "red": 0.20, "green": 0.40, "blue": 0.60 },
  "accent": { "red": 0.30, "green": 0.70, "blue": 0.90 },
  "success": { "red": 0.20, "green": 0.65, "blue": 0.35 },
  "warning": { "red": 0.95, "green": 0.65, "blue": 0.15 },
  "text": { "red": 0.20, "green": 0.20, "blue": 0.25 },
  "white": { "red": 1, "green": 1, "blue": 1 }
}
```

## Slide Style Preferences
- Clean, technical aesthetic
- Use architecture diagrams
- Include sequence diagrams for message flows
- Dark primary background for title slides
- White background for content slides

## Common Presentation Types

### Technical Overview
1. Title + project description
2. Architecture diagram (clients, server, messages)
3. WebSocket message flow
4. Deployment pipeline
5. Scaling considerations

### Status Update
1. Title + date
2. Completed work
3. Current blockers
4. Upcoming tasks
5. Metrics (connections, uptime)

## Key Talking Points
- Dart WebSocket server using shelf
- Real-time player movement broadcasting
- Bot user (Claude) presence management
- SSL/TLS via Let's Encrypt
- Docker deployment to GCP Compute Engine
- GitHub Actions CI/CD with tagged releases
