## MainMenu.gd
## Handles mode / difficulty selection then launches the Game scene.

extends Control

const GC = preload("res://scripts/GameConstants.gd")

var _selected_mode       : String = "local"
var _selected_difficulty : String = "medium"

@onready var btn_local    : Button       = $VBox/ModeRow/BtnLocal
@onready var btn_ai       : Button       = $VBox/ModeRow/BtnAI
@onready var diff_box     : VBoxContainer = $VBox/DifficultyBox
@onready var btn_easy     : Button       = $VBox/DifficultyBox/DiffRow/BtnEasy
@onready var btn_medium   : Button       = $VBox/DifficultyBox/DiffRow/BtnMedium
@onready var btn_hard     : Button       = $VBox/DifficultyBox/DiffRow/BtnHard
@onready var btn_start    : Button       = $VBox/BtnStart


func _ready() -> void:
	# Apply initial visual state
	_refresh_mode_buttons()
	_refresh_diff_buttons()
	diff_box.visible = false   # hidden until AI mode selected

	# Connect signals
	btn_local.pressed.connect(_on_mode_local)
	btn_ai.pressed.connect(_on_mode_ai)
	btn_easy.pressed.connect(func(): _set_difficulty("easy"))
	btn_medium.pressed.connect(func(): _set_difficulty("medium"))
	btn_hard.pressed.connect(func(): _set_difficulty("hard"))
	btn_start.pressed.connect(_on_start)

	# Style
	_apply_theme()


func _on_mode_local() -> void:
	_selected_mode = "local"
	diff_box.visible = false
	_refresh_mode_buttons()


func _on_mode_ai() -> void:
	_selected_mode = "ai"
	diff_box.visible = true
	_refresh_mode_buttons()


func _set_difficulty(d: String) -> void:
	_selected_difficulty = d
	_refresh_diff_buttons()


func _on_start() -> void:
	GameState.game_mode     = _selected_mode
	GameState.ai_difficulty = _selected_difficulty
	get_tree().change_scene_to_file("res://scenes/Game.tscn")


# ── Visual helpers ────────────────────────────────────────

func _refresh_mode_buttons() -> void:
	btn_local.modulate = Color(1, 1, 1, 1)    if _selected_mode == "local" else Color(0.55, 0.55, 0.55, 1)
	btn_ai.modulate    = Color(0.29, 0.61, 1, 1) if _selected_mode == "ai"    else Color(0.55, 0.55, 0.55, 1)


func _refresh_diff_buttons() -> void:
	var accent := Color(0.29, 0.61, 1, 1)
	var dim    := Color(0.55, 0.55, 0.55, 1)
	btn_easy.modulate   = accent if _selected_difficulty == "easy"   else dim
	btn_medium.modulate = accent if _selected_difficulty == "medium" else dim
	btn_hard.modulate   = accent if _selected_difficulty == "hard"   else dim


func _apply_theme() -> void:
	# Quick programmatic styling so the menu looks dark even without a Theme asset
	for btn in [btn_local, btn_ai, btn_easy, btn_medium, btn_hard, btn_start]:
		btn.add_theme_color_override("font_color",          Color(1, 1, 1))
		btn.add_theme_color_override("font_hover_color",    Color(0.29, 0.61, 1))
		btn.add_theme_color_override("font_pressed_color",  Color(0.2, 0.45, 0.8))
