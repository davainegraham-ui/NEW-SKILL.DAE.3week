## Game.gd
## Core Pong gameplay — direct port of the HTML/JS logic to Godot 4 GDScript.
## Reads GameState (autoload) for mode & difficulty chosen on the menu.

extends Node2D

# ── Constants ─────────────────────────────────────────────
const W  := 880.0
const H  := 480.0

const PADDLE_W     := 14.0
const PADDLE_H     := 90.0
const PADDLE_SPEED := 350.0   # px / sec

const BALL_SIZE    := 12.0
const BALL_SPEED   := 275.0
const BALL_SPEED_CAP := 700.0
const BALL_ACCEL   := 1.05

const WINNING_SCORE := 7

const AI_CONFIG := {
	"easy":   { "speed": 140.0, "reaction_zone": 0.35, "error_range": 40.0 },
	"medium": { "speed": 225.0, "reaction_zone": 0.55, "error_range": 18.0 },
	"hard":   { "speed": 340.0, "reaction_zone": 0.85, "error_range":  4.0 },
}

# ── Node refs ─────────────────────────────────────────────
@onready var p1_rect    : ColorRect = $P1Paddle
@onready var p2_rect    : ColorRect = $P2Paddle
@onready var ball_rect  : ColorRect = $Ball
@onready var p1_score_l : Label     = $HUD/P1Score
@onready var p2_score_l : Label     = $HUD/P2Score
@onready var p2_label   : Label     = $HUD/P2Label
@onready var ai_badge   : Label     = $HUD/AIBadge
@onready var win_overlay: Control   = $HUD/WinOverlay
@onready var win_msg    : Label     = $HUD/WinOverlay/WinVBox/WinMsg
@onready var win_score  : Label     = $HUD/WinOverlay/WinVBox/WinScore
@onready var btn_again  : Button    = $HUD/WinOverlay/WinVBox/BtnPlayAgain
@onready var btn_menu   : Button    = $HUD/WinOverlay/WinVBox/BtnMainMenu

# ── State ─────────────────────────────────────────────────
var p1_y      : float = H / 2.0 - PADDLE_H / 2.0
var p2_y      : float = H / 2.0 - PADDLE_H / 2.0
var p1_score  : int   = 0
var p2_score  : int   = 0

var ball_x    : float = W / 2.0
var ball_y    : float = H / 2.0
var ball_vx   : float = 0.0
var ball_vy   : float = 0.0

var game_running : bool   = false
var game_mode    : String = "local"
var ai_difficulty: String = "medium"

# AI internal
var ai_target_y      : float = H / 2.0
var ai_error_offset  : float = 0.0

# ── Lifecycle ─────────────────────────────────────────────

func _ready() -> void:
	game_mode     = GameState.game_mode
	ai_difficulty = GameState.ai_difficulty

	# Paddle sizes
	p1_rect.size   = Vector2(PADDLE_W, PADDLE_H)
	p2_rect.size   = Vector2(PADDLE_W, PADDLE_H)
	ball_rect.size = Vector2(BALL_SIZE, BALL_SIZE)

	# AI / 2P UI
	if game_mode == "ai":
		ai_badge.visible = true
		p2_label.text    = "AI"
		p2_rect.color    = Color(0.494, 0.784, 1.0)   # blue tint
	else:
		ai_badge.visible = false
		p2_label.text    = "P2"
		p2_rect.color    = Color(1, 1, 1)

	# Buttons
	btn_again.pressed.connect(_on_play_again)
	btn_menu.pressed.connect(_on_main_menu)

	_reset_game()
	game_running = true


func _process(delta: float) -> void:
	if not game_running:
		return
	_handle_input(delta)
	if game_mode == "ai":
		_update_ai(delta)
	_update_ball(delta)
	_draw_state()


# ── Input ─────────────────────────────────────────────────

func _handle_input(delta: float) -> void:
	# P1
	if Input.is_key_pressed(KEY_W):
		p1_y -= PADDLE_SPEED * delta
	if Input.is_key_pressed(KEY_S):
		p1_y += PADDLE_SPEED * delta
	p1_y = clamp(p1_y, 0.0, H - PADDLE_H)

	# P2 (human only)
	if game_mode == "local":
		if Input.is_key_pressed(KEY_UP):
			p2_y -= PADDLE_SPEED * delta
		if Input.is_key_pressed(KEY_DOWN):
			p2_y += PADDLE_SPEED * delta
		p2_y = clamp(p2_y, 0.0, H - PADDLE_H)


# ── AI ────────────────────────────────────────────────────

func _update_ai(delta: float) -> void:
	var cfg  : Dictionary = AI_CONFIG[ai_difficulty]
	var p2x  : float      = W - 20.0 - PADDLE_W
	var zone : float      = W * cfg["reaction_zone"]

	if ball_vx > 0.0 and ball_x > W - zone:
		# Predict Y when ball reaches paddle X
		var dist     : float = p2x - ball_x
		var t        : float = dist / max(ball_vx, 0.1)
		var predict_y: float = ball_y + ball_vy * t

		# One-wall bounce correction
		if predict_y < 0.0:
			predict_y = -predict_y
		elif predict_y > H:
			predict_y = 2.0 * H - predict_y
		predict_y = clamp(predict_y, 0.0, H)

		ai_target_y = predict_y - PADDLE_H / 2.0 + ai_error_offset
	elif ball_vx < 0.0:
		# Drift back to centre
		ai_target_y += (H / 2.0 - PADDLE_H / 2.0 - ai_target_y) * 0.02

	var center : float = p2_y + PADDLE_H / 2.0
	var target : float = ai_target_y + PADDLE_H / 2.0
	var diff   : float = target - center

	if abs(diff) > 2.0:
		p2_y += sign(diff) * min(cfg["speed"] * delta, abs(diff))
	p2_y = clamp(p2_y, 0.0, H - PADDLE_H)


# ── Ball physics ──────────────────────────────────────────

func _update_ball(delta: float) -> void:
	ball_x += ball_vx * delta
	ball_y += ball_vy * delta

	# Top / bottom wall bounce
	if ball_y <= 0.0:
		ball_y  = 0.0
		ball_vy = abs(ball_vy)
	elif ball_y + BALL_SIZE >= H:
		ball_y  = H - BALL_SIZE
		ball_vy = -abs(ball_vy)

	var p1x : float = 20.0
	var p2x : float = W - 20.0 - PADDLE_W

	# P1 paddle collision
	if ball_vx < 0.0 and _hit_paddle(p1x, p1_y):
		ball_x  = p1x + PADDLE_W
		ball_vx = abs(ball_vx) * BALL_ACCEL
		var hit  : float = (ball_y + BALL_SIZE / 2.0) - (p1_y + PADDLE_H / 2.0)
		ball_vy  = hit * 0.2 * (BALL_SPEED / 5.5)   # scale to px/s equivalent
		_cap_speed()
		ai_error_offset = (randf() - 0.5) * AI_CONFIG[ai_difficulty]["error_range"] * 2.0

	# P2 paddle collision
	if ball_vx > 0.0 and _hit_paddle(p2x, p2_y):
		ball_x  = p2x - BALL_SIZE
		ball_vx = -abs(ball_vx) * BALL_ACCEL
		var hit  : float = (ball_y + BALL_SIZE / 2.0) - (p2_y + PADDLE_H / 2.0)
		ball_vy  = hit * 0.2 * (BALL_SPEED / 5.5)
		_cap_speed()

	# Scoring
	if ball_x < 0.0:
		p2_score += 1
		p2_score_l.text = str(p2_score)
		if _check_win(2):
			return
		_reset_ball(1.0)

	if ball_x > W:
		p1_score += 1
		p1_score_l.text = str(p1_score)
		if _check_win(1):
			return
		_reset_ball(-1.0)


func _hit_paddle(px: float, py: float) -> bool:
	return (ball_x         < px + PADDLE_W and
	        ball_x + BALL_SIZE > px         and
	        ball_y         < py + PADDLE_H  and
	        ball_y + BALL_SIZE > py)


func _cap_speed() -> void:
	var spd := sqrt(ball_vx * ball_vx + ball_vy * ball_vy)
	if spd > BALL_SPEED_CAP:
		ball_vx = (ball_vx / spd) * BALL_SPEED_CAP
		ball_vy = (ball_vy / spd) * BALL_SPEED_CAP


# ── Win check ─────────────────────────────────────────────

func _check_win(player: int) -> bool:
	var score : int = p1_score if player == 1 else p2_score
	if score >= WINNING_SCORE:
		game_running = false
		var msg : String
		if game_mode == "ai":
			msg = "YOU WIN!" if player == 1 else "AI WINS!"
		else:
			msg = "PLAYER %d WINS" % player
		win_msg.text   = msg
		win_score.text = "%d — %d" % [p1_score, p2_score]
		win_overlay.visible = true
		return true
	return false


# ── Reset helpers ─────────────────────────────────────────

func _reset_ball(dir: float) -> void:
	ball_x = W / 2.0
	ball_y = H / 2.0
	var angle : float = (randf() * 0.6) - 0.3
	ball_vx = dir * BALL_SPEED * cos(angle)
	ball_vy = BALL_SPEED * sin(angle)
	ai_error_offset = (randf() - 0.5) * AI_CONFIG[ai_difficulty]["error_range"] * 2.0
	ai_target_y = H / 2.0


func _reset_game() -> void:
	p1_y = H / 2.0 - PADDLE_H / 2.0
	p2_y = H / 2.0 - PADDLE_H / 2.0
	p1_score = 0
	p2_score = 0
	p1_score_l.text = "0"
	p2_score_l.text = "0"
	win_overlay.visible = false
	_reset_ball(1.0 if randf() > 0.5 else -1.0)


# ── Render ────────────────────────────────────────────────

func _draw_state() -> void:
	p1_rect.position   = Vector2(20.0, p1_y)
	p2_rect.position   = Vector2(W - 20.0 - PADDLE_W, p2_y)
	ball_rect.position = Vector2(ball_x, ball_y)


func _draw() -> void:
	# Center dashed divider line
	var dash_h    : float = 12.0
	var gap_h     : float = 12.0
	var total_h   : float = dash_h + gap_h
	var y         : float = 0.0
	var line_col  : Color = Color(1.0, 1.0, 1.0, 0.2)
	while y < H:
		draw_rect(Rect2(W / 2.0 - 1.0, y, 2.0, min(dash_h, H - y)), line_col)
		y += total_h


# ── Button handlers ───────────────────────────────────────

func _on_play_again() -> void:
	win_overlay.visible = false
	_reset_game()
	game_running = true


func _on_main_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
