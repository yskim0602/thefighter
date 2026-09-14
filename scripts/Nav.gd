extends Node

## 오토로드 싱글턴. 화면 이동 기록을 스택으로 들고 있어서, 앞으로 메뉴가
## 몇 단계로 깊어지든 모든 메뉴가 공통으로 "뒤로가기"/"홈"을 쓸 수 있게 한다.
## 새 메뉴로 들어갈 땐 항상 change_scene_to_file 대신 go_to()를 쓸 것.

const HOME_SCENE := "res://scenes/Career.tscn"

var _history: Array[String] = []


func go_to(scene_path: String) -> void:
	var current := get_tree().current_scene.scene_file_path
	if current != "":
		_history.append(current)
	get_tree().change_scene_to_file(scene_path)


func go_back() -> void:
	if _history.is_empty():
		go_home()
		return
	var previous: String = _history.pop_back()
	get_tree().change_scene_to_file(previous)


func go_home() -> void:
	_history.clear()
	get_tree().change_scene_to_file(HOME_SCENE)
