extends Control

## 스테이지 화면: 10단계 커리어 로드맵을 사각형 박스로 늘어놓고, 화살표로
## 한 칸씩 넘겨보는 화면이다. 여기서 상대나 무대를 직접 고르는 건 아니다 -
## 실제 대전은 항상 홈의 FIGHT → 경기 제의 흐름을 거친다. 이 화면은 순전히
## "지금 어디까지 왔는지, 각 무대에서 몇 승 몇 패 했는지"를 구경하는 용도다.
##
## Track(HBoxContainer)에 10개 박스를 전부 만들어 나란히 붙여두고,
## CarouselViewport가 그 중 VISIBLE_COUNT개만 보이게 clip_contents로
## 잘라낸다. 화살표를 누르면 Track 전체를 박스 하나 너비만큼 좌우로
## 미끄러뜨린다(tween) - 그래서 "박스가 하나씩 이동"하는 것처럼 보인다.

const VISIBLE_COUNT := 3
const BOX_WIDTH := 240.0
const BOX_HEIGHT := 240.0
const BOX_GAP := 20.0
const SLIDE_TIME := 0.28

const LOCKED_COLOR := Color(0.55, 0.55, 0.6)
const CURRENT_COLOR := Color(1, 0.85, 0.3)
const CLEARED_COLOR := Color(0.4, 0.85, 0.45)
const LOCKED_ALPHA := 0.55

@onready var track: HBoxContainer = $CarouselViewport/Track
@onready var left_arrow: Button = $LeftArrow
@onready var right_arrow: Button = $RightArrow

var _window_start := 0
var _max_window_start := 0


func _ready() -> void:
	track.add_theme_constant_override("separation", BOX_GAP)
	var career := SaveManager.career
	for i in range(CareerData.STAGE_NAMES.size()):
		track.add_child(_build_stage_box(i, career))

	_max_window_start = max(CareerData.STAGE_NAMES.size() - VISIBLE_COUNT, 0)
	# 지금 도전 중인 무대가 첫 칸에 보이도록 시작 위치를 맞춘다.
	_window_start = clampi(career.stage, 0, _max_window_start)
	_snap_track()
	_refresh_arrows()


func _build_stage_box(stage_index: int, career: CareerData) -> Control:
	var box := PanelContainer.new()
	box.custom_minimum_size = Vector2(BOX_WIDTH, BOX_HEIGHT)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	box.add_child(vbox)

	var number_label := Label.new()
	number_label.text = "STAGE %02d" % (stage_index + 1)
	number_label.add_theme_font_size_override("font_size", 13)
	number_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.65))
	vbox.add_child(number_label)

	var name_label := Label.new()
	name_label.text = CareerData.STAGE_NAMES[stage_index]
	name_label.add_theme_font_size_override("font_size", 19)
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(name_label)

	vbox.add_child(HSeparator.new())

	var status_label := Label.new()
	status_label.add_theme_font_size_override("font_size", 15)
	vbox.add_child(status_label)

	var requirement_label := Label.new()
	requirement_label.add_theme_font_size_override("font_size", 13)
	requirement_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.75))
	requirement_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	requirement_label.text = _requirement_text(stage_index)
	vbox.add_child(requirement_label)

	var record: Dictionary = career.stage_record[stage_index] if stage_index < career.stage_record.size() else {}
	var wins: int = record.get("wins", 0)
	var losses: int = record.get("losses", 0)
	var record_label := Label.new()
	record_label.add_theme_font_size_override("font_size", 13)
	record_label.text = ("%d승 %d패" % [wins, losses]) if (wins + losses) > 0 else "미도전"
	vbox.add_child(record_label)

	if stage_index < career.stage:
		status_label.text = "CLEAR"
		status_label.add_theme_color_override("font_color", CLEARED_COLOR)
	elif stage_index == career.stage:
		status_label.text = "도전 중"
		status_label.add_theme_color_override("font_color", CURRENT_COLOR)
	else:
		status_label.text = "잠김"
		status_label.add_theme_color_override("font_color", LOCKED_COLOR)
		box.modulate = Color(1, 1, 1, LOCKED_ALPHA)

	return box


func _requirement_text(stage_index: int) -> String:
	if stage_index < CareerConfig.RANKED_STAGE_INDEX:
		return "%d전 %d승 시 승급" % [CareerConfig.STAGE_FIGHTS_REQUIRED, CareerConfig.STAGE_WINS_REQUIRED]
	match stage_index:
		CareerData.Stage.RANKED:
			return "랭크 %d에서 시작 - %d 이하면 TOP 10" % [CareerConfig.RANK_START, CareerConfig.RANK_TOP10_THRESHOLD]
		CareerData.Stage.TOP_10:
			return "랭크 %d 도달 시 타이틀전" % CareerConfig.RANK_TITLE_SHOT_THRESHOLD
		CareerData.Stage.TITLE_SHOT:
			return "챔피언과의 타이틀전"
		CareerData.Stage.CHAMPION:
			return "타이틀 방어 %d회 성공 시 레전드" % CareerConfig.TITLE_DEFENSES_FOR_LEGEND
	return ""


func _snap_track() -> void:
	track.position.x = -_window_start * (BOX_WIDTH + BOX_GAP)


func _refresh_arrows() -> void:
	left_arrow.disabled = _window_start <= 0
	right_arrow.disabled = _window_start >= _max_window_start


func _on_left_arrow_pressed() -> void:
	if _window_start <= 0:
		return
	_window_start -= 1
	_slide_track()


func _on_right_arrow_pressed() -> void:
	if _window_start >= _max_window_start:
		return
	_window_start += 1
	_slide_track()


func _slide_track() -> void:
	_refresh_arrows()
	var target_x: float = -_window_start * (BOX_WIDTH + BOX_GAP)
	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(track, "position:x", target_x, SLIDE_TIME)
