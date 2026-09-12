extends Node

## 오토로드 싱글턴 (project.godot [autoload] 참고). 커리어 세이브 데이터를
## 게임 전체(Career 화면, 전투 씬)에서 공유하고 user:// 에 JSON으로 저장한다.

const SAVE_PATH := "user://career_save.json"

var career: CareerData


func _ready() -> void:
	load_or_create()


func load_or_create() -> void:
	career = CareerData.new()
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var text := file.get_as_text()
	file.close()
	var parsed = JSON.parse_string(text)
	if parsed is Dictionary:
		career.from_dict(parsed)


func save() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(career.to_dict(), "\t"))
	file.close()
