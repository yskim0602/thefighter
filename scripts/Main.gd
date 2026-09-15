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
@onready var pause_layer: CanvasLayer = $PauseLayer

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
		Nav.go_to("res://scenes/MatchOffer.tscn")


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
	var offer := MatchContext.current_offer
	if offer == null:
		offer = OpponentOffer.new()  # 제의 없이 씬을 바로 실행한 경우를 위한 안전망.

	var progress := career.register_result(player_won, offer)
	SaveManager.save()

	var outcome_text: String
	var reward_amount: int
	if player_won:
		outcome_text = "승리! (%s)" % reason
		reward_amount = offer.money_reward
	else:
		outcome_text = "패배... (%s)" % reason
		reward_amount = int(offer.money_reward * 0.2)

	var extra_text := ""
	if progress.get("promoted", false):
		extra_text += "\n%s 승급!" % career.stage_name()
	if progress.get("stage_failed", false):
		extra_text += "\n승급 실패... 같은 무대에서 다시 도전합니다"
	if progress.get("became_champion", false):
		extra_text += "\n챔피언 등극!"

	result_label.text = "%s\n+%d G%s\n\nR: 재대결   M: 다음 경기 제의" % [outcome_text, reward_amount, extra_text]
	result_label.visible = true


func _restart() -> void:
	round_over = false
	time_left = ROUND_TIME
	result_label.visible = false
	player.reset_fighter(player_spawn)
	enemy.reset_fighter(enemy_spawn)


func _on_pause_button_pressed() -> void:
	if get_tree().paused:
		_resume()
	else:
		_pause()


func _pause() -> void:
	get_tree().paused = true
	pause_layer.visible = true


func _resume() -> void:
	get_tree().paused = false
	pause_layer.visible = false


func _on_resume_pressed() -> void:
	_resume()


func _on_pause_restart_pressed() -> void:
	_resume()
	_restart()


func _on_pause_exit_pressed() -> void:
	get_tree().paused = false
	Nav.go_home()
