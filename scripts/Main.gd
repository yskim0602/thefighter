extends Node3D

const ROUND_TIME := 99.0

@onready var player: Fighter = $Player
@onready var enemy: Fighter = $Enemy
@onready var camera: Camera3D = $Camera3D
@onready var player_bar: ProgressBar = $UI/HUD/PlayerHealthBar
@onready var enemy_bar: ProgressBar = $UI/HUD/EnemyHealthBar
@onready var result_label: Label = $UI/HUD/ResultLabel
@onready var round_timer_label: Label = $UI/HUD/RoundTimer
@onready var player_style_label: Label = $UI/HUD/PlayerStyleLabel
@onready var enemy_style_label: Label = $UI/HUD/EnemyStyleLabel

var player_spawn: Vector3
var enemy_spawn: Vector3
var time_left := ROUND_TIME
var round_over := false


func _ready() -> void:
	player_spawn = player.global_position
	enemy_spawn = enemy.global_position

	player.opponent = enemy
	enemy.opponent = player
	player.health_changed.connect(_on_player_health_changed)
	enemy.health_changed.connect(_on_enemy_health_changed)
	player.knocked_out.connect(func(): _finish_fight(false, "KO 패배"))
	enemy.knocked_out.connect(func(): _finish_fight(true, "KO 승리"))

	result_label.visible = false
	_on_player_health_changed(player.health, player.stats.get_max_health())
	_on_enemy_health_changed(enemy.health, enemy.stats.get_max_health())
	player_style_label.text = FightingStyle.style_name(player.stats.style)
	enemy_style_label.text = FightingStyle.style_name(enemy.stats.style)


func _process(delta: float) -> void:
	_update_camera()

	if not round_over:
		time_left = max(time_left - delta, 0.0)
		round_timer_label.text = str(int(ceil(time_left)))
		if time_left <= 0.0:
			_finish_fight(player.health > enemy.health, "판정")

	if Input.is_action_just_pressed("restart"):
		_restart()
	if Input.is_action_just_pressed("return_to_menu"):
		Nav.go_home()


func _update_camera() -> void:
	var mid := (player.global_position + enemy.global_position) * 0.5
	var dist := player.global_position.distance_to(enemy.global_position)
	var back_distance: float = clamp(dist * 1.2 + 3.0, 6.0, 12.0)
	camera.global_position = mid + Vector3(0, 3.0, back_distance)
	camera.look_at(mid + Vector3(0, 1, 0), Vector3.UP)


func _on_player_health_changed(current: float, max_h: float) -> void:
	player_bar.max_value = max_h
	player_bar.value = current


func _on_enemy_health_changed(current: float, max_h: float) -> void:
	enemy_bar.max_value = max_h
	enemy_bar.value = current


func _finish_fight(player_won: bool, reason: String) -> void:
	if round_over:
		return
	round_over = true

	var career := SaveManager.career
	var reward: int
	var outcome_text: String
	if player_won:
		career.wins += 1
		reward = 100 + career.wins * 10
		outcome_text = "승리! (%s)" % reason
	else:
		career.losses += 1
		reward = 20
		outcome_text = "패배... (%s)" % reason
	career.fight_money += reward
	career.update_tier_from_wins()
	SaveManager.save()

	result_label.text = "%s\n+%d G\n\nR: 재대결   M: 커리어로" % [outcome_text, reward]
	result_label.visible = true


func _restart() -> void:
	round_over = false
	time_left = ROUND_TIME
	result_label.visible = false
	player.reset_fighter(player_spawn)
	enemy.reset_fighter(enemy_spawn)
