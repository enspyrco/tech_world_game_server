import 'package:tech_world_networking_types/tech_world_networking_types.dart';

/// A bot user that appears in the game world for all players.
final botUser = NetworkUser(
  id: 'bot-claude',
  displayName: 'Claude',
);

/// The fixed position where the bot stands in the game world.
/// Coordinates are in pixels (grid square size is 32 pixels).
final botPosition = Double2(x: 200.0, y: 200.0);
