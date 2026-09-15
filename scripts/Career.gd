extends Control

## 홈 화면 = 게임 로비. 캐릭터와 현재 무대가 화면 중앙을 가득 채우는 3D
## 미리보기다. 플레이어가 무대나 상대를 직접 고르지 않으므로(경기는 항상
## "제의 수락/거절" 방식), FIGHT 버튼은 항상 새 경기 제의 화면(MatchOffer)
## 으로 이동한다. 능력치 훈련은 CharacterMenu.gd 쪽에 있다.

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

@onready var arena_environment: Environment = $ArenaViewportContainer/ArenaViewport/ArenaScene/WorldEnvironment.environment
@onready var arena_bulb: OmniLight3D = $ArenaViewportContainer/ArenaViewport/ArenaScene/BulbLight

@onready var money_label: Label = $TopBar/TopBarRow/MoneyLabel
@onready var stage_name_label: Label = $StageNameLabel

@onready var record_label: Label = $InfoPanel/InfoVBox/RecordLabel
@onready var progress_label: Label = $InfoPanel/InfoVBox/ProgressLabel
@onready var fans_label: Label = $InfoPanel/InfoVBox/FansLabel
@onready var fame_label: Label = $InfoPanel/InfoVBox/FameLabel


func _ready() -> void:
	_refresh()


func _refresh() -> void:
	var career := SaveManager.career
	money_label.text = "%d G" % career.fight_money
	stage_name_label.text = career.stage_name()

	record_label.text = "RECORD   %d W / %d L" % [career.wins, career.losses]
	fans_label.text = "FANS   %d" % career.fans
	fame_label.text = "FAME   %d" % career.fame

	if career.is_ranked_stage():
		progress_label.text = "RANK   %d" % career.rank
	elif career.promotion_ready:
		progress_label.text = "승급전 도전 가능! (FIGHT를 눌러보세요)"
	else:
		progress_label.text = "승급 조건   7승 달성 (%d/%d경기, %d승)" % [
			career.fights_this_stage, CareerConfig.STAGE_FIGHTS_REQUIRED, career.wins_this_stage
		]

	_apply_arena_lighting(career.stage)


func _apply_arena_lighting(stage: int) -> void:
	var stage_count := CareerData.STAGE_NAMES.size()
	var t: float = clampf(float(stage) / float(stage_count - 1), 0.0, 1.0)
	arena_environment.ambient_light_color = AMBIENT_COLOR_START.lerp(AMBIENT_COLOR_END, t)
	arena_environment.ambient_light_energy = lerpf(AMBIENT_ENERGY_START, AMBIENT_ENERGY_END, t)
	arena_bulb.light_color = BULB_COLOR_START.lerp(BULB_COLOR_END, t)
	arena_bulb.light_energy = lerpf(BULB_ENERGY_START, BULB_ENERGY_END, t)


func _on_character_pressed() -> void:
	Nav.go_to("res://scenes/CharacterMenu.tscn")


func _on_fight_pressed() -> void:
	Nav.go_to("res://scenes/MatchOffer.tscn")
