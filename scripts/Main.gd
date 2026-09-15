extends Node3D

const ROUND_TIME := 99.0
## 승/패 결과를 보여주고 다음 경기 제의로 자동으로 넘어가기까지의 시간(초).
const RESULT_DISPLAY_TIME := 2.5

const WIN_COLOR := Color(0.4, 0.85, 0.4)
const LOSE_COLOR := Color(0.9, 0.35, 0.35)

@onready var player: Fighter = $Player
@onready var enemy: Fighter = $Enemy
@onready var camera: Camera3D = $Camera3D
@onready var player_bar: ProgressBar = $UI/HUD/PlayerHealthBar
@onready var enemy_bar: ProgressBar = $UI/HUD/EnemyHealthBar
@onready var result_label: Label = $UI/HUD/ResultLabel
@onready var player_result_label: Label = $UI/HUD/PlayerResultLabel
@onready var enemy_result_label: Label = $UI/HUD/EnemyResultLabel
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
	player_result_label.visible = false
	enemy_result_label.visible = false
	_on_player_health_changed(player.health, player.stats.get_max_health())
	_on_enemy_health_changed(enemy.health, enemy.stats.get_max_health())
	player_style_label.text = "복서"
	var offer := MatchContext.current_offer
	enemy_style_label.text = offer.archetype_name() if offer != null else "복서"


func _process(delta: float) -> void:
	_update_camera()

	if not round_over:
		time_left = max(time_left - delta, 0.0)
		round_timer_label.text = str(int(ceil(time_left)))
		if time_left <= 0.0:
			_finish_fight(player.health > enemy.health, "판정")


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

	player_result_label.text = "WIN" if player_won else "LOSE"
	player_result_label.add_theme_color_override("font_color", WIN_COLOR if player_won else LOSE_COLOR)
	player_result_label.visible = true

	enemy_result_label.text = "LOSE" if player_won else "WIN"
	enemy_result_label.add_theme_color_override("font_color", LOSE_COLOR if player_won else WIN_COLOR)
	enemy_result_label.visible = true

	var extra_text := reason
	if progress.get("promoted", false):
		extra_text += "\n%s 승급!" % career.stage_name()
	if progress.get("stage_failed", false):
		extra_text += "\n승급 실패... 같은 무대에서 다시 도전합니다"
	if progress.get("became_champion", false):
		extra_text += "\n챔피언 등극!"
	result_label.text = extra_text
	result_label.visible = true

	get_tree().create_timer(RESULT_DISPLAY_TIME).timeout.connect(_go_to_next_offer)


func _go_to_next_offer() -> void:
	if not round_over:
		return  # 결과 화면이 뜬 사이 일시정지 메뉴에서 "다시하기"를 눌러 이미 재대결이 시작됨.
	get_tree().paused = false  # 결과 대기 중 일시정지된 채로 다음 화면에 들어가지 않도록.
	# reset_to를 써서 이동 기록을 비운다 - 그래야 다음 화면에서 "뒤로"를 눌렀을 때
	# 방금 끝난 이 전투 씬으로 되돌아가 시합이 다시 시작되는 문제가 생기지 않는다.
	Nav.reset_to("res://scenes/MatchOffer.tscn")


func _restart() -> void:
	round_over = false
	time_left = ROUND_TIME
	result_label.visible = false
	player_result_label.visible = false
	enemy_result_label.visible = false
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
