## GameConstants.gd
## Shared constants used across all scripts

extends Node

# Canvas / world dimensions
const WIDTH  := 880
const HEIGHT := 480

# Paddle
const PADDLE_W     := 14
const PADDLE_H     := 90
const PADDLE_SPEED := 350.0   # pixels per second

# Ball
const BALL_SIZE    := 12
const BALL_SPEED   := 275.0   # initial speed px/s
const BALL_SPEED_CAP := 700.0 # maximum speed
const BALL_ACCEL   := 1.05    # speed multiplier per paddle hit

# Winning score
const WINNING_SCORE := 7

# AI config  [speed, reaction_zone_fraction, error_range, label]
const AI_CONFIG := {
	"easy":   { "speed": 140.0, "reaction_zone": 0.35, "error_range": 40.0 },
	"medium": { "speed": 225.0, "reaction_zone": 0.55, "error_range": 18.0 },
	"hard":   { "speed": 340.0, "reaction_zone": 0.85, "error_range":  4.0 },
}
