extends Node

const SCENES := {
	"main_menu": "res://scenes/main_menu.tscn",
	"character_select": "res://scenes/character_select.tscn",
	"stage_select": "res://scenes/stage_select.tscn",
	"battle": "res://scenes/battle.tscn",
	"level_up": "res://scenes/level_up.tscn",
	"pause": "res://scenes/pause.tscn",
	"chest_reward": "res://scenes/chest_reward.tscn",
	"result": "res://scenes/result.tscn",
	"permanent_growth": "res://scenes/permanent_growth.tscn",
	"collection": "res://scenes/collection.tscn",
	"settings": "res://scenes/settings.tscn",
}


func go(screen_id: String) -> void:
	if not SCENES.has(screen_id):
		push_error("등록되지 않은 화면입니다: %s" % screen_id)
		return
	var error := get_tree().change_scene_to_file(SCENES[screen_id])
	if error != OK:
		push_error("화면을 열지 못했습니다 (%s): %s" % [screen_id, error_string(error)])
