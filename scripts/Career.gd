extends Control

## 홈 화면 = 게임 로비. 캐릭터와 현재 경기장이 화면 중앙을 가득 채우는 3D
## 미리보기이고, 위쪽에 무대 이름을 좌우로 넘겨볼 수 있는 바가 있다.
## FIGHT 버튼은 "현재 실제로 도달한 무대"를 넘겨보고 있을 때만 눌린다.
## 능력치 훈련은 CharacterMenu.gd 쪽에 있다.

## 무대 단계에 따라 지하 체육관의 어두운 조명 → 화려한 챔피언 무대 조명으로
## 3D 프리뷰 자체의 라이팅을 보간한다. 실제 배경 사진/텍스처를 쓰게 되면
## 이 라이팅 보간 대신(또는 같이) 단계별 배경 씬을 교체하면 된다.
const AMBIENT_COLOR_START := Color(0.55, 0.5, 0.45)
const AMBIENT_COLOR_END := Color(0.9, 0.85, 0.7)
const AMBIENT_ENERGY_START := 0.35
const AMBIENT_ENERGY_END := 0.9
const BULB_COLOR_START := Color(1, 0.85, 0.6)
const BULB_COLOR_END := Color(1, 0.95, 0.85)
const BULB_ENERGY_START := 2.6
const BULB_ENERGY_END := 4.0

const FIGHT_WIN_BASE_REWARD := 100
const FIGHT_WIN_REWARD_PER_WIN := 10

@onready var arena_environment: Environment = $ArenaViewportContainer/ArenaViewport/ArenaScene/WorldEnvironment.environment
@onready var arena_bulb: OmniLight3D = $ArenaViewportContainer/ArenaViewport/ArenaScene/BulbLight

@onready var money_label: Label = $TopBar/TopBarRow/MoneyLabel

@onready var prev_peek_label: Label = $StageBar/StageCenterVBox/PrevPeekLabel
@onready var stage_name_label: Label = $StageBar/StageCenterVBox/StageNameLabel
@onready var next_peek_label: Label = $StageBar/StageCenterVBox/NextPeekLabel

@onready var record_label: Label = $InfoPanel/InfoVBox/RecordLabel
@onready var rank_label: Label = $InfoPanel/InfoVBox/RankLabel
@onready var next_fight_label: Label = $InfoPanel/InfoVBox/NextFightLabel
@onready var reward_label: Label = $InfoPanel/InfoVBox/RewardLabel

@onready var fight_button: Button = $BottomBar/BottomVBox/FightButton
@onready var locked_hint_label: Label = $BottomBar/BottomVBox/LockedHintLabel

## 지금 화면에 "넘겨보고 있는" 무대. 실제 도달한 무대(SaveManager.career.stage)와
## 다를 수 있고, 그럴 때는 FIGHT 버튼이 비활성화된다.
var browsed_stage: int = 0


func _ready() -> void:
	browsed_stage = SaveManager.career.stage
	_refresh()


func _refresh() -> void:
	var career := SaveManager.career
	money_label.text = "%d G" % career.fight_money

	record_label.text = "RECORD   %d - %d" % [career.wins, career.losses]
	rank_label.text = "RANK   %s" % career.stage_name()
	var next_fight_number := career.wins + career.losses + 1
	next_fight_label.text = "NEXT FIGHT   %s #%d" % [career.stage_name(), next_fight_number]
	var predicted_reward := FIGHT_WIN_BASE_REWARD + (career.wins + 1) * FIGHT_WIN_REWARD_PER_WIN
	reward_label.text = "REWARD   +%d G" % predicted_reward

	_apply_arena_lighting(career.stage)
	_refresh_stage_bar()


func _apply_arena_lighting(stage: int) -> void:
	var stage_count := CareerData.STAGE_NAMES.size()
	var t: float = clampf(float(stage) / float(stage_count - 1), 0.0, 1.0)
	arena_environment.ambient_light_color = AMBIENT_COLOR_START.lerp(AMBIENT_COLOR_END, t)
	arena_environment.ambient_light_energy = lerpf(AMBIENT_ENERGY_START, AMBIENT_ENERGY_END, t)
	arena_bulb.light_color = BULB_COLOR_START.lerp(BULB_COLOR_END, t)
	arena_bulb.light_energy = lerpf(BULB_ENERGY_START, BULB_ENERGY_END, t)


func _refresh_stage_bar() -> void:
	var stage_names := CareerData.STAGE_NAMES
	var current_stage := SaveManager.career.stage

	stage_name_label.text = stage_names[browsed_stage]
	prev_peek_label.text = stage_names[browsed_stage - 1] if browsed_stage > 0 else " "
	next_peek_label.text = stage_names[browsed_stage + 1] if browsed_stage < stage_names.size() - 1 else " "

	var is_current := browsed_stage == current_stage
	fight_button.disabled = not is_current
	locked_hint_label.visible = not is_current
	if browsed_stage > current_stage:
		locked_hint_label.text = "잠긴 무대입니다 - 먼저 %s 단계까지 승리해야 합니다" % stage_names[current_stage]
	elif browsed_stage < current_stage:
		locked_hint_label.text = "이미 지난 무대입니다"


func _on_prev_stage_pressed() -> void:
	browsed_stage = max(browsed_stage - 1, 0)
	_refresh_stage_bar()


func _on_next_stage_pressed() -> void:
	browsed_stage = min(browsed_stage + 1, CareerData.STAGE_NAMES.size() - 1)
	_refresh_stage_bar()


func _on_character_pressed() -> void:
	Nav.go_to("res://scenes/CharacterMenu.tscn")


func _on_fight_pressed() -> void:
	if browsed_stage != SaveManager.career.stage:
		return
	Nav.go_to("res://scenes/Main.tscn")
