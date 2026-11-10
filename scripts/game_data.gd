extends Node

var party_size: int = CHARACTERS.size()
const SAVE_PATH := "user://survivor_save.cfg"
const DB_PATH := "user://survivor_save.db"

const CHARACTERS := [
	{
		"name": "견습 기사",
		"title": "초보 모험가",
		"weapon": "목검",
		"passive": "최대 체력 +10%",
		"stats": [80, 60, 55],
		"attack_style": "melee",
		"attributes": {"STR": 5, "AGI": 3, "VIT": 5, "INT": 1, "DEX": 2, "LUK": 2},
		"visual":
		{
			"scene": "res://assets/characters/char01/Model/char01.fbx",
			"scale": 1.0,
			"forward_rotation_degrees": 0.0,
			"vertical_offset": -0.9,
			"texture": "res://assets/characters/char01/Animations/FighterTexture.png",
			"animations":
			{
				"walk":
				{
					"scene": "res://assets/characters/char01/Animations/Sprint.fbx",
					"clip": "mixamo_com",
				},
				"idle":
				{
					"scene": "res://assets/characters/char01/Animations/Fighting Idle.fbx",
					"clip": "mixamo_com",
				},
				"run":
				{
					"scene": "res://assets/characters/char01/Animations/Sprint.fbx",
					"clip": "mixamo_com",
				},
				"hit":
				{
					"scene": "res://assets/characters/char01/Animations/Boxing.fbx",
					"clip": "mixamo_com",
				},
				"death":
				{
					"scene": "res://assets/characters/char01/Animations/Boxing.fbx",
					"clip": "mixamo_com",
				},
				"attack":
				{
					"scene": "res://assets/characters/char01/Animations/Boxing.fbx",
					"clip": "mixamo_com",
				},
				"skill_1":
				{
					"scene": "res://assets/characters/char01/Animations/Kicking.fbx",
					"clip": "mixamo_com",
				},
				"skill_2":
				{
					"scene": "res://assets/characters/char01/Animations/Flying Kick.fbx",
					"clip": "mixamo_com",
				},
				"skill_3":
				{
					"scene": "res://assets/characters/char01/Animations/Hurricane Kick.fbx",
					"clip": "mixamo_com",
				},
				"skill_4":
				{
					"scene": "res://assets/characters/char01/Animations/Martelo 2.fbx",
					"clip": "mixamo_com",
				},
			},
		},
		"color": Color("#59a9e8"),
	},
	{
		"name": "무도가",
		"title": "빠르고 강력한 격투가",
		"weapon": "강철 건틀렛",
		"passive": "공격 속도 +10%",
		"stats": [70, 80, 60],
		"attack_style": "melee",
		"attributes": {"STR": 4, "AGI": 5, "VIT": 4, "INT": 2, "DEX": 4, "LUK": 3},
		"visual":
		{
			"scene": "res://assets/characters/char02/Animations/T-Pose.fbx",
			"scale": 1.0,
			"forward_rotation_degrees": 0.0,
			"vertical_offset": 0.0,
			"texture": "res://assets/characters/char02/Animations/Texture.png",
			"animations":
			{
				"walk":
				{
					"scene": "res://assets/characters/char01/Animations/Sprint.fbx",
					"clip": "mixamo",
				},
				"idle":
				{
					"scene": "res://assets/characters/char02/Animations/Fighting Idle.fbx",
					"clip": "mixamo",
				},
				"run":
				{
					"scene": "res://assets/characters/char01/Animations/Sprint.fbx",
					"clip": "mixamo",
				},
				"hit":
				{
					"scene": "res://assets/characters/char02/Animations/Quad Punch.fbx",
					"clip": "mixamo",
				},
				"death":
				{
					"scene": "res://assets/characters/char02/Animations/Dying.fbx",
					"clip": "mixamo",
				},
				"attack":
				{
					"scene": "res://assets/characters/char02/Animations/Quad Punch.fbx",
					"clip": "mixamo",
				},
				"skill_1":
				{
					"scene": "res://assets/characters/char02/Animations/Flying Kick.fbx",
					"clip": "mixamo",
				},
				"skill_2":
				{
					"scene": "res://assets/characters/char02/Animations/Roundhouse Kick.fbx",
					"clip": "mixamo",
				},
				"skill_3":
				{
					"scene": "res://assets/characters/char02/Animations/Hurricane Kick.fbx",
					"clip": "mixamo",
				},
				"skill_4":
				{
					"scene": "res://assets/characters/char02/Animations/Standing Dive Forward.fbx",
					"clip": "mixamo",
				},
			},
		},
		"color": Color("#e89b59"),
	},
	{
		"name": "검수",
		"title": "거대한 검수",
		"weapon": "대검",
		"passive": "공격력 +10%",
		"stats": [60, 70, 50],
		"attack_style": "melee",
		"attributes": {"STR": 3, "AGI": 4, "VIT": 3, "INT": 2, "DEX": 5, "LUK": 3},
		"visual":
		{
			"scene": "res://assets/characters/char03/Model/char03.fbx",
			"scale": 1.0,
			"forward_rotation_degrees": 0.0,
			"vertical_offset": -0.4,
			"texture": "res://assets/characters/char03/Model/char03_texture.png",
			"weapon_bone": "mixamorig:RightHand",
			"default_weapon": "Sword",
			"weapon_profiles":
			{
				"Sword":
				{
					"scene": "res://assets/items/weapon/sword_2handed.fbx",
					"position": Vector3.ZERO,
					"rotation_degrees": Vector3.ZERO,
					"scale": Vector3.ONE * 0.3,
				},
				"Crossbow":
				{
					"scene": "res://assets/items/weapon/crossbow_1handed.fbx",
					"position": Vector3.ZERO,
					"rotation_degrees": Vector3.ZERO,
					"scale": Vector3.ONE * 0.1,
				},
				"Bow":
				{
					"scene": "res://assets/items/weapon/bow_withString.fbx",
					"position": Vector3.ZERO,
					"rotation_degrees": Vector3.ZERO,
					"scale": Vector3.ONE * 0.1,
				},
				"Staff":
				{
					"scene": "res://assets/items/weapon/staff.fbx",
					"position": Vector3.ZERO,
					"rotation_degrees": Vector3.ZERO,
					"scale": Vector3.ONE * 0.1,
				},
			},
			"animations":
			{
				"walk":
				{
					"scene": "res://assets/characters/char03/Animations/Sword And Shield Walk.fbx",
					"clip": "mixamo_com",
				},
				"idle":
				{
					"scene": "res://assets/characters/char03/Animations/Sword And Shield Idle.fbx",
					"clip": "mixamo_com",
				},
				"run":
				{
					"scene": "res://assets/characters/char03/Animations/Sword And Shield Run.fbx",
					"clip": "mixamo_com",
				},
				"hit":
				{
					"scene": "res://assets/characters/char03/Animations/Sword And Shield Death.fbx",
					"clip": "mixamo_com",
				},
				"death":
				{
					"scene": "res://assets/characters/char03/Animations/Sword And Shield Death.fbx",
					"clip": "mixamo_com",
				},
				"attack":
				{
					"scene": "res://assets/characters/char03/Animations/Sword And Shield Slash.fbx",
					"clip": "mixamo_com",
				},
				"skill_1":
				{
					"scene": "res://assets/characters/char03/Animations/Great Sword Jump Attack.fbx",
					"clip": "mixamo_com",
				},
				"skill_2":
				{
					"scene": "res://assets/characters/char03/Animations/Stable Sword Outward Slash.fbx",
					"clip": "mixamo_com",
				},
				"skill_3":
				{
					"scene": "res://assets/characters/char03/Animations/Sword And Shield Slash.fbx",
					"clip": "mixamo_com",
				},
				"skill_4":
				{
					"scene": "res://assets/characters/char03/Animations/Great Sword Jump Attack.fbx",
					"clip": "mixamo_com",
				},
			},
		},
		"color": Color("#8bc34a"),
	},
]

const STAGES := [
	{
		"name": "슬라임 초원",
		"subtitle": "정령의 기운이 가득한 초원",
		"difficulty": "쉬움",
		"level": 1,
		"monsters": "슬라임 · 고블린 · 박쥐 · 정령 골렘",
		"reward": "경험치 · 골드 · HP 물약",
		"color": Color("#91c878"),
	},
]

var player_level := 1
var gold := 500
var gems := 25
var selected_character := 0
var selected_detail_character := 0
var party_characters: Array[int] = [0, 1, 2]
var camera_target_slot := 0
var selected_party_slot := 0
var selected_stage := 0
var permanent_stats: Dictionary = {
	"STR": 0,
	"AGI": 0,
	"VIT": 0,
	"INT": 0,
	"DEX": 0,
	"LUK": 0,
}
var sound_enabled := true
var vibration_enabled := true
var run_gold_reward := 0
var run_experience_reward := 0
var run_elapsed_time := 0.0
var run_kill_count := 0
var run_start_hero_levels: Dictionary = {}
var run_start_party_slot_levels: Array[int] = []
var run_won := true
var run_level := 1
var run_upgrades: Dictionary = {"power": 0, "vitality": 0, "fortune": 0}
var hero_levels: Dictionary = {}
var hero_experience: Dictionary = {}
var hero_ranks: Dictionary = {}
var hero_equipment: Dictionary = {}
var hero_equipped_skills: Dictionary = {}
var codex_monsters: Array[String] = ["slime"]
var codex_reward_claimed: Dictionary = {}
var party_slot_levels: Array[int] = [1, 1, 1]
var party_slot_experience: Array[int] = [0, 0, 0]
var party_slot_progress_loaded := false


func _ready() -> void:
	load_game()
	for i in range(CHARACTERS.size()):
		if not hero_levels.has(i):
			hero_levels[i] = 1
		if not hero_experience.has(i):
			hero_experience[i] = 0
		if not hero_ranks.has(i):
			hero_ranks[i] = 0
		if not hero_equipment.has(i):
			hero_equipment[i] = CHARACTERS[i]["weapon"]
		if not hero_equipped_skills.has(i):
			hero_equipped_skills[i] = CombatData.CHARACTER_SKILL_SETS.get(i, []).duplicate()
	if not party_slot_progress_loaded:
		_initialize_party_slot_progress()
	if synchronize_party_progress():
		save_game()


func synchronize_party_progress() -> bool:
	var changed := false
	for slot in range(mini(party_size, party_characters.size())):
		var character_index := party_characters[slot]
		var hero_level := maxi(1, int(hero_levels.get(character_index, 1)))
		var slot_level := maxi(1, party_slot_levels[slot])
		var level := maxi(hero_level, slot_level)
		var experience := 0
		if hero_level > slot_level:
			experience = maxi(0, int(hero_experience.get(character_index, 0)))
		elif slot_level > hero_level:
			experience = maxi(0, party_slot_experience[slot])
		else:
			experience = maxi(
				int(hero_experience.get(character_index, 0)),
				party_slot_experience[slot]
			)
		var required_experience := CombatData.experience_required_for_level(level)
		while experience >= required_experience:
			experience -= required_experience
			level += 1
			required_experience = CombatData.experience_required_for_level(level)
		if (
			hero_level != level
			or int(hero_experience.get(character_index, 0)) != experience
			or slot_level != level
			or party_slot_experience[slot] != experience
		):
			changed = true
		hero_levels[character_index] = level
		hero_experience[character_index] = experience
		party_slot_levels[slot] = level
		party_slot_experience[slot] = experience
	return changed


func _open_db() -> SQLite:
	var db := SQLite.new()
	db.path = DB_PATH
	db.open_db()
	_ensure_schema(db)
	return db

func _ensure_schema(db: SQLite) -> void:
	db.query("""
	CREATE TABLE IF NOT EXISTS profile (
		key TEXT PRIMARY KEY,
		value TEXT
	);
	""")
	db.query("""
	CREATE TABLE IF NOT EXISTS hero (
		character_index INTEGER PRIMARY KEY,
		level INTEGER,
		exp INTEGER,
		rank INTEGER,
		equipment TEXT,
		skills TEXT
	);
	""")
	db.query("""
	CREATE TABLE IF NOT EXISTS party (
		slot INTEGER PRIMARY KEY,
		character_index INTEGER
	);
	""")
	db.query("""
	CREATE TABLE IF NOT EXISTS growth (
		stat_key TEXT PRIMARY KEY,
		value INTEGER
	);
	""")
	db.query("""
	CREATE TABLE IF NOT EXISTS codex_monsters (
		monster_id TEXT PRIMARY KEY
	);
	""")
	db.query("""
	CREATE TABLE IF NOT EXISTS codex_rewards (
		reward_key TEXT PRIMARY KEY,
		claimed INTEGER
	);
	""")
	db.query("""
	CREATE TABLE IF NOT EXISTS party_progress (
		slot INTEGER PRIMARY KEY,
		level INTEGER,
		exp INTEGER
	);
	""")

func _migrate_from_cfg() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return
	var db := _open_db()
	# profile
	var pairs := {
		"gold": gold, "gems": gems, "character": selected_character,
		"camera_target_slot": camera_target_slot, "stage": selected_stage,
		"sound": sound_enabled, "vibration": vibration_enabled,
	}
	# We'll just run save_game after populating in-memory from cfg, then delete cfg.
	# Simpler: load into memory using existing logic by temporarily calling legacy loader.
	db.close_db()

func load_game() -> void:
	# Migrate legacy cfg if db missing
	var db_file := FileAccess.file_exists(DB_PATH)
	var cfg_exists := FileAccess.file_exists(SAVE_PATH)
	if (not db_file) and cfg_exists:
		# Load legacy into memory via helper
		_load_legacy_cfg()
		save_game()
		# backup cfg
		DirAccess.rename_absolute(SAVE_PATH, SAVE_PATH + ".bak")
		return
	var db := _open_db()
	# profile
	var rows = db.query_result if false else null
	db.query("SELECT key, value FROM profile")
	for r in db.query_result:
		match r["key"]:
			"gold": gold = maxi(0, int(r["value"]))
			"gems": gems = maxi(0, int(r["value"]))
			"character": selected_character = clampi(int(r["value"]), 0, CHARACTERS.size() - 1)
			"camera_target_slot": camera_target_slot = clampi(int(r["value"]), 0, party_size - 1)
			"stage": selected_stage = clampi(int(r["value"]), 0, STAGES.size() - 1)
			"sound": sound_enabled = bool(int(r["value"]))
			"vibration": vibration_enabled = bool(int(r["value"]))
	# growth
	db.query("SELECT stat_key, value FROM growth")
	for r in db.query_result:
		if permanent_stats.has(r["stat_key"]):
			permanent_stats[r["stat_key"]] = int(r["value"])
	# hero
	db.query("SELECT * FROM hero")
	for r in db.query_result:
		var i := int(r["character_index"])
		hero_levels[i] = maxi(1, int(r["level"]))
		hero_experience[i] = maxi(0, int(r["exp"]))
		hero_ranks[i] = clampi(int(r["rank"]), 0, 5)
		hero_equipment[i] = str(r["equipment"])
		var sk = JSON.parse_string(str(r["skills"]))
		if sk is Array:
			hero_equipped_skills[i] = sk
	# party
	db.query("SELECT slot, character_index FROM party")
	for r in db.query_result:
		var slot := int(r["slot"])
		if slot >= 0 and slot < party_characters.size():
			party_characters[slot] = int(r["character_index"])
	# codex
	db.query("SELECT monster_id FROM codex_monsters")
	codex_monsters.clear()
	for r in db.query_result:
		codex_monsters.append(str(r["monster_id"]))
	db.query("SELECT reward_key, claimed FROM codex_rewards")
	codex_reward_claimed.clear()
	for r in db.query_result:
		codex_reward_claimed[str(r["reward_key"])] = bool(int(r["claimed"]))
	# party progress
	db.query("SELECT slot, level, exp FROM party_progress")
	for r in db.query_result:
		var slot := int(r["slot"])
		if slot >= 0 and slot < party_slot_levels.size():
			party_slot_levels[slot] = maxi(1, int(r["level"]))
			party_slot_experience[slot] = maxi(0, int(r["exp"]))
	db.close_db()
	_normalize_party()
	player_level = 1
	party_slot_progress_loaded = true


func _load_legacy_cfg() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return
	player_level = 1
	gold = maxi(0, int(config.get_value("profile", "gold", gold)))
	gems = maxi(0, int(config.get_value("profile", "gems", gems)))
	selected_character = clampi(int(config.get_value("profile", "character", 0)), 0, CHARACTERS.size() - 1)
	var saved_party: Variant = config.get_value("profile", "party", [])
	if saved_party is Array:
		for i in range(mini(party_size, saved_party.size())):
			party_characters[i] = clampi(int(saved_party[i]), 0, CHARACTERS.size() - 1)
	if not party_characters.is_empty():
		party_characters[0] = selected_character
	_normalize_party()
	camera_target_slot = clampi(int(config.get_value("profile", "camera_target_slot", 0)), 0, party_size - 1)
	selected_stage = clampi(int(config.get_value("profile", "stage", 0)), 0, STAGES.size() - 1)
	var saved_stats: Variant = config.get_value("growth", "permanent_stats", config.get_value("growth", "upgrades", {}))
	if saved_stats is Dictionary:
		var legacy_mapping := {"power": "STR", "vitality": "VIT", "fortune": "LUK"}
		for legacy_key in legacy_mapping:
			var stat_key: String = legacy_mapping[legacy_key]
			permanent_stats[stat_key] = maxi(int(permanent_stats[stat_key]), int(saved_stats.get(legacy_key, 0)))
		for key in permanent_stats:
			permanent_stats[key] = maxi(int(permanent_stats[key]), int(saved_stats.get(key, 0)))
	sound_enabled = bool(config.get_value("settings", "sound", true))
	vibration_enabled = bool(config.get_value("settings", "vibration", true))
	for i in range(CHARACTERS.size()):
		hero_levels[i] = maxi(1, int(config.get_value("hero", "level_%d" % i, 1)))
		hero_experience[i] = maxi(0, int(config.get_value("hero", "exp_%d" % i, 0)))
		hero_ranks[i] = clampi(int(config.get_value("hero", "rank_%d" % i, 0)), 0, 5)
		hero_equipment[i] = str(config.get_value("hero", "equipment_%d" % i, CHARACTERS[i]["weapon"]))
		var skills_key := "skills_%d" % i
		var saved_skills: Variant = config.get_value("hero", skills_key, [])
		if config.has_section_key("hero", skills_key) and saved_skills is Array:
			hero_equipped_skills[i] = saved_skills.duplicate()
		else:
			hero_equipped_skills[i] = CombatData.CHARACTER_SKILL_SETS.get(i, []).duplicate()
	var saved_codex: Variant = config.get_value("collection", "monsters", ["slime"])
	if saved_codex is Array:
		codex_monsters.clear()
		for monster_id in saved_codex:
			if not codex_monsters.has(str(monster_id)):
				codex_monsters.append(str(monster_id))
	var saved_rewards: Variant = config.get_value("collection", "rewards", {})
	codex_reward_claimed = saved_rewards.duplicate() if saved_rewards is Dictionary else {}
	_initialize_party_slot_progress()
	for slot in range(party_size):
		var level_key := "level_%d" % slot
		var experience_key := "exp_%d" % slot
		if config.has_section_key("party_progress", level_key):
			party_slot_levels[slot] = maxi(1, int(config.get_value("party_progress", level_key, party_slot_levels[slot])))
		if config.has_section_key("party_progress", experience_key):
			party_slot_experience[slot] = maxi(0, int(config.get_value("party_progress", experience_key, party_slot_experience[slot])))

func save_game() -> void:
	var db := _open_db()
	# profile upserts
	var profile_pairs := {
		"gold": gold, "gems": gems, "character": selected_character,
		"camera_target_slot": camera_target_slot, "stage": selected_stage,
		"sound": int(sound_enabled), "vibration": int(vibration_enabled),
	}
	for k in profile_pairs:
		db.query_with_bindings("INSERT INTO profile (key, value) VALUES (?, ?) ON CONFLICT(key) DO UPDATE SET value=excluded.value", [k, str(profile_pairs[k])])
	# growth
	for key in permanent_stats:
		db.query_with_bindings("INSERT INTO growth (stat_key, value) VALUES (?, ?) ON CONFLICT(stat_key) DO UPDATE SET value=excluded.value", [key, int(permanent_stats[key])])
	# hero
	for i in range(CHARACTERS.size()):
		db.query_with_bindings("INSERT INTO hero (character_index, level, exp, rank, equipment, skills) VALUES (?, ?, ?, ?, ?, ?) ON CONFLICT(character_index) DO UPDATE SET level=excluded.level, exp=excluded.exp, rank=excluded.rank, equipment=excluded.equipment, skills=excluded.skills", [i, int(hero_levels.get(i, 1)), int(hero_experience.get(i, 0)), int(hero_ranks.get(i, 0)), str(hero_equipment.get(i, CHARACTERS[i]["weapon"])), JSON.stringify(hero_equipped_skills.get(i, []))])
	# party
	for slot in range(party_size):
		db.query_with_bindings("INSERT INTO party (slot, character_index) VALUES (?, ?) ON CONFLICT(slot) DO UPDATE SET character_index=excluded.character_index", [slot, int(party_characters[slot])])
	# codex monsters
	db.query("DELETE FROM codex_monsters")
	for m in codex_monsters:
		db.query_with_bindings("INSERT OR IGNORE INTO codex_monsters (monster_id) VALUES (?)", [m])
	# codex rewards
	for k in codex_reward_claimed:
		db.query_with_bindings("INSERT INTO codex_rewards (reward_key, claimed) VALUES (?, ?) ON CONFLICT(reward_key) DO UPDATE SET claimed=excluded.claimed", [k, int(codex_reward_claimed[k])])
	# party progress
	for slot in range(party_size):
		db.query_with_bindings("INSERT INTO party_progress (slot, level, exp) VALUES (?, ?, ?) ON CONFLICT(slot) DO UPDATE SET level=excluded.level, exp=excluded.exp", [slot, int(party_slot_levels[slot]), int(party_slot_experience[slot])])
	db.close_db()

func spend_gold(amount: int) -> bool:
	if amount < 0 or gold < amount:
		return false
	gold -= amount
	save_game()
	return true


func add_gold(amount: int, save_immediately := true) -> void:
	gold += maxi(0, amount)
	if save_immediately:
		save_game()


func add_party_slot_experience(slot: int, character_index: int, amount: int) -> void:
	if (
		slot < 0
		or slot >= party_slot_levels.size()
		or character_index < 0
		or character_index >= CHARACTERS.size()
		or amount <= 0
	):
		return
	var current_level := party_slot_levels[slot]
	var current_experience := party_slot_experience[slot] + amount
	var required_experience := CombatData.experience_required_for_level(current_level)
	while current_experience >= required_experience:
		current_experience -= required_experience
		current_level += 1
		required_experience = CombatData.experience_required_for_level(current_level)
	party_slot_levels[slot] = current_level
	party_slot_experience[slot] = current_experience

	var recorded_level := int(hero_levels.get(character_index, 1))
	if current_level > recorded_level:
		hero_levels[character_index] = current_level
		hero_experience[character_index] = current_experience
	elif current_level == recorded_level:
		hero_experience[character_index] = maxi(
			int(hero_experience.get(character_index, 0)), current_experience
		)


func _initialize_party_slot_progress() -> void:
	for slot in range(party_size):
		var character_index := party_characters[slot]
		party_slot_levels[slot] = int(hero_levels.get(character_index, 1))
		party_slot_experience[slot] = int(hero_experience.get(character_index, 0))


func set_party_slot_character(slot: int, character_index: int) -> void:
	if (
		slot < 0
		or slot >= party_characters.size()
		or character_index < 0
		or character_index >= CHARACTERS.size()
	):
		return
	if party_characters[slot] == character_index:
		return
	for other_slot in range(party_characters.size()):
		if other_slot != slot and party_characters[other_slot] == character_index:
			return
	party_characters[slot] = character_index
	party_slot_levels[slot] = int(hero_levels.get(character_index, 1))
	party_slot_experience[slot] = int(hero_experience.get(character_index, 0))


func discover_monster(monster_id: String) -> void:
	if monster_id.is_empty() or codex_monsters.has(monster_id):
		return
	codex_monsters.append(monster_id)
	save_game()


func _normalize_party() -> void:
	var assigned: Dictionary = {}
	for slot in range(mini(party_size, party_characters.size())):
		var character_index := clampi(party_characters[slot], 0, CHARACTERS.size() - 1)
		if assigned.has(character_index):
			for candidate in range(CHARACTERS.size()):
				if not assigned.has(candidate):
					character_index = candidate
					break
		party_characters[slot] = character_index
		assigned[character_index] = true


func begin_run() -> void:
	run_gold_reward = 0
	run_experience_reward = 0
	run_elapsed_time = 0.0
	run_kill_count = 0
	run_start_hero_levels = hero_levels.duplicate()
	run_start_party_slot_levels = party_slot_levels.duplicate()
	run_won = true
	player_level = 1
	run_level = 1
	run_upgrades = {"power": 0, "vitality": 0, "fortune": 0}
