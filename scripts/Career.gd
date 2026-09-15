extends Control

## 홈 화면 (브롤스타즈 스타일 허브). 위쪽엔 지하실 배경의 3D 캐릭터 미리보기,
## 아래쪽엔 파이트머니/전적/무대 단계 표시와 서브 메뉴(캐릭터)/경기 시작 버튼이 있다.
## 능력치 훈련은 CharacterMenu.gd 쪽으로 옮겼다.

## 무대 단계에 따라 지하실(어두움) → 챔피언 무대(밝은 금색)로 배경을 보간한다.
## 지금은 사진 대신 색상만 바꾸지만, 나중에 실제 배경 사진/텍스처를 쓰게 되면
## Background를 ColorRect 대신 TextureRect로 바꾸고 이 보간 대신 텍스처 배열을
## 인덱싱하면 된다.
const STAGE_BG_START := Color(0.05, 0.05, 0.07)
const STAGE_BG_END := Color(0.14, 0.1, 0.02)

@onready var background: ColorRect = $Background
@onready var stage_label: Label = $TierLabel
@onready var money_label: Label = $MoneyLabel
@onready var record_label: Label = $RecordLabel


func _ready() -> void:
	_refresh()


func _refresh() -> void:
	var career := SaveManager.career
	background.color = _stage_bg_color(career.stage)
	stage_label.text = "무대: %s" % career.stage_name()
	record_label.text = "전적 %d승 %d패" % [career.wins, career.losses]
	money_label.text = "%d G" % career.fight_money


func _stage_bg_color(stage: int) -> Color:
	var stage_count := CareerData.STAGE_NAMES.size()
	var t: float = clamp(float(stage) / float(stage_count - 1), 0.0, 1.0)
	return STAGE_BG_START.lerp(STAGE_BG_END, t)


func _on_character_pressed() -> void:
	Nav.go_to("res://scenes/CharacterMenu.tscn")


func _on_fight_pressed() -> void:
	Nav.go_to("res://scenes/StageSelect.tscn")
