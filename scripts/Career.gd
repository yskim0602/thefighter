extends Control

## 홈 화면 (브롤스타즈 스타일 허브). 위쪽엔 지하실 배경의 3D 캐릭터 미리보기,
## 아래쪽엔 파이트머니/전적/등급 표시와 서브 메뉴(캐릭터)/경기 시작 버튼이 있다.
## 능력치 훈련은 CharacterMenu.gd 쪽으로 옮겼다.

## 등급별 배경색. 지금은 사진 대신 색상만 바꾸지만, 나중에 실제 배경 사진/텍스처를
## 쓰게 되면 Background를 ColorRect 대신 TextureRect로 바꾸고 이 테이블을
## 텍스처 리소스 테이블로 그대로 교체하면 된다.
const TIER_BG_COLORS := {
	CareerData.Tier.UNDERGROUND: Color(0.05, 0.05, 0.06),
	CareerData.Tier.AMATEUR: Color(0.05, 0.07, 0.09),
	CareerData.Tier.CONTENDER: Color(0.04, 0.07, 0.11),
	CareerData.Tier.CHAMPION: Color(0.10, 0.08, 0.02),
}

@onready var background: ColorRect = $Background
@onready var tier_label: Label = $TierLabel
@onready var money_label: Label = $MoneyLabel
@onready var record_label: Label = $RecordLabel


func _ready() -> void:
	_refresh()


func _refresh() -> void:
	var career := SaveManager.career
	background.color = TIER_BG_COLORS.get(career.tier, TIER_BG_COLORS[CareerData.Tier.UNDERGROUND])
	tier_label.text = "등급: %s" % career.tier_name()
	record_label.text = "전적 %d승 %d패" % [career.wins, career.losses]
	money_label.text = "%d G" % career.fight_money


func _on_character_pressed() -> void:
	Nav.go_to("res://scenes/CharacterMenu.tscn")


func _on_fight_pressed() -> void:
	Nav.go_to("res://scenes/Main.tscn")
