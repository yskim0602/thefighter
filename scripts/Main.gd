extends Node3D

const ROUND_TIME := 99.0
## 승/패 결과를 보여주고 다음 경기 제의로 자동으로 넘어가기까지의 시간(초).
const RESULT_DISPLAY_TIME := 2.5

const WIN_COLOR := Color(0.4, 0.85, 0.4)
const LOSE_COLOR := Color(0.9, 0.35, 0.35)

@onready var player: PlayerController = $Player
@onready var enemy: Fighter = $Enemy
@onready var camera: Camera3D = $Camera3D
@onready var fp_camera: Camera3D = $Player/FirstPersonCamera
@onready var player_bar: ProgressBar = $UI/HUD/PlayerHealthBar
@onready var enemy_bar: ProgressBar = $UI/HUD/EnemyHealthBar
@onready var player_stamina_bar: ProgressBar = $UI/HUD/PlayerStaminaBar
@onready var enemy_stamina_bar: ProgressBar = $UI/HUD/EnemyStaminaBar
@onready var result_label: Label = $UI/HUD/ResultLabel
@onready var player_result_label: Label = $UI/HUD/PlayerResultLabel
@onready var enemy_result_label: Label = $UI/HUD/EnemyResultLabel
@onready var down_label: Label = $UI/HUD/DownLabel
@onready var round_timer_label: Label = $UI/HUD/RoundTimer
@onready var player_style_label: Label = $UI/HUD/PlayerStyleLabel
@onready var enemy_style_label: Label = $UI/HUD/EnemyStyleLabel
@onready var pause_layer: CanvasLayer = $PauseLayer

var player_spawn: Vector3
var enemy_spawn: Vector3
var time_left := ROUND_TIME
var round_over := false
## V로 전환. 1인칭에서는 카메라가 플레이어 몸체(항상 상대를 바라보도록
## 자동 회전함)에 그대로 붙어서 따라간다 - PlayerController.first_person도
## 같이 맞춰서 이동 입력을 그 몸체 기준(카메라가 보는 방향 기준)으로 바꾼다.
var first_person := false


func _ready() -> void:
	player_spawn = player.global_position
	enemy_spawn = enemy.global_position

	player.opponent = enemy
	enemy.opponent = player
	player.health_changed.connect(_on_player_health_changed)
	enemy.health_changed.connect(_on_enemy_health_changed)
	player.stamina_changed.connect(_on_player_stamina_changed)
	enemy.stamina_changed.connect(_on_enemy_stamina_changed)
	player.knocked_down.connect(func(count: int): _on_fighter_down(count))
	enemy.knocked_down.connect(func(count: int): _on_fighter_down(count))
	player.recovered_from_down.connect(_on_fighter_recovered)
	enemy.recovered_from_down.connect(_on_fighter_recovered)
	player.knocked_out.connect(func(): _finish_fight(false, "KO 패배"))
	enemy.knocked_out.connect(func(): _finish_fight(true, "KO 승리"))

	result_label.visible = false
	player_result_label.visible = false
	enemy_result_label.visible = false
	down_label.visible = false
	_on_player_health_changed(player.health, player.get_effective_max_health())
	_on_enemy_health_changed(enemy.health, enemy.get_effective_max_health())
	_on_player_stamina_changed(player.stamina, player.get_effective_max_stamina())
	_on_enemy_stamina_changed(enemy.stamina, enemy.get_effective_max_stamina())
	player_style_label.text = BoxingStyle.style_name(player.style)


func _process(delta: float) -> void:
	if Input.is_action_just_pressed("toggle_view"):
		_toggle_view()
	_update_camera()
	enemy_style_label.text = BoxingStyle.style_name(enemy.style)

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


## V로 3인칭/1인칭을 전환한다. 1인칭 카메라는 Player의 자식이라 몸통이
## 상대를 자동으로 바라보는 회전(Fighter._face_opponent)에 그대로 실려서
## 따라간다. 내 캡슐 몸통은 1인칭에서 시야를 가리니 숨기고(글러브는 그대로
## 보이게 둬서 어떤 펀치가 나가는지는 계속 보인다), PlayerController의
## 이동 계산도 같이 전환해서 "앞으로"가 지금 보고 있는 방향과 맞게 한다.
func _toggle_view() -> void:
	first_person = not first_person
	camera.current = not first_person
	fp_camera.current = first_person
	player.mesh.visible = not first_person
	player.first_person = first_person


func _on_player_health_changed(current: float, max_h: float) -> void:
	player_bar.max_value = max_h
	player_bar.value = current


func _on_enemy_health_changed(current: float, max_h: float) -> void:
	enemy_bar.max_value = max_h
	enemy_bar.value = current


func _on_player_stamina_changed(current: float, max_s: float) -> void:
	player_stamina_bar.max_value = max_s
	player_stamina_bar.value = current


func _on_enemy_stamina_changed(current: float, max_s: float) -> void:
	enemy_stamina_bar.max_value = max_s
	enemy_stamina_bar.value = current


func _on_fighter_down(count: int) -> void:
	down_label.text = "DOWN! (%d/%d)" % [count, Fighter.MAX_KNOCKDOWNS]
	down_label.visible = true


func _on_fighter_recovered() -> void:
	down_label.visible = false


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
	down_label.visible = false
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
