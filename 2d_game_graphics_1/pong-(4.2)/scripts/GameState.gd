## GameState.gd  (AutoLoad singleton)
## Stores settings chosen on the menu so Game scene can read them.

extends Node

var game_mode    : String = "local"   # "local" | "ai"
var ai_difficulty: String = "medium"  # "easy" | "medium" | "hard"
