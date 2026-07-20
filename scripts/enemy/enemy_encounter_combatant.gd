class_name EnemyEncounterCombatant
extends Enemy
## 精英 / Boss 战斗基类（替代 Unity 项目里的 EnemyEncounterCombatant）
##
## 在 Enemy 之上扩展：
##   - 阶段（phase）：根据血量阈值切换
##   - 韧性（poise）：积累到上限后强制硬直
##   - 技能冷却字典：HUD 可读取
##   - 焦点广播：玩家发现后通知 HUD（GameEvents.encounter_focus_changed）

signal phase_changed(phase_index: int)
signal poise_changed(ratio: float)
signal skill_cooldown_changed(skill_id: StringName, ratio: float)

@export var phase_thresholds: Array[float] = [0.66, 0.33]   # 健康比例阈值（降序）
@export var max_poise: float = 6.0
@export var poise_recover_per_second: float = 1.5
@export var super_armor_threshold: float = 4.0
@export var display_name_key: StringName = &"enemy.boss.generic"

var phase_index: int = 0
var poise: float = 0.0
var skill_cooldowns: Dictionary = {}        # skill_id -> { time_left, total }


func _ready() -> void:
	super._ready()
	if character != null:
		character.health_changed.connect(_evaluate_phase)
	_evaluate_phase()


func _process(delta: float) -> void:
	super._process(delta)
	if poise > 0.0:
		poise = maxf(0.0, poise - poise_recover_per_second * delta)
		poise_changed.emit(get_poise_ratio())
		GameEvents.encounter_poise_changed.emit(self, get_poise_ratio())

	for id in skill_cooldowns.keys():
		var entry: Dictionary = skill_cooldowns[id]
		entry["time_left"] = maxf(0.0, float(entry.get("time_left", 0.0)) - delta)
		skill_cooldowns[id] = entry
		var ratio := get_skill_cooldown_ratio(StringName(id))
		skill_cooldown_changed.emit(StringName(id), ratio)
		GameEvents.encounter_skill_cooldown_changed.emit(self, StringName(id), ratio)


# ----- 受击：考虑 super armor / 韧性 -------------------------------------------

func _on_character_damage(by: Node) -> void:
	if poise < super_armor_threshold:
		super._on_character_damage(by)
	else:
		# 命中但不进入 hurt 状态（超甲）
		if by is Node2D:
			var n2d := by as Node2D
			var dir := signf(global_position.x - n2d.global_position.x)
			velocity.x = dir * (hurt_force * 0.25)
		hurt_started.emit(by)
	_accumulate_poise(1.0)


func _accumulate_poise(amount: float) -> void:
	poise = clampf(poise + amount, 0.0, max_poise)
	poise_changed.emit(get_poise_ratio())
	GameEvents.encounter_poise_changed.emit(self, get_poise_ratio())


# ----- 阶段切换 ---------------------------------------------------------------

func _evaluate_phase() -> void:
	if character == null:
		return
	var ratio := character.get_health_ratio()
	var new_phase := 0
	for i in phase_thresholds.size():
		if ratio < phase_thresholds[i]:
			new_phase = i + 1
	if new_phase != phase_index:
		phase_index = new_phase
		phase_changed.emit(phase_index)
		GameEvents.encounter_phase_changed.emit(self, phase_index)


# ----- 技能冷却 ---------------------------------------------------------------

func register_skill(id: StringName, total: float) -> void:
	skill_cooldowns[String(id)] = {"time_left": 0.0, "total": total}


func trigger_skill(id: StringName) -> bool:
	var key := String(id)
	if not skill_cooldowns.has(key):
		return false
	var entry: Dictionary = skill_cooldowns[key]
	if float(entry.get("time_left", 0.0)) > 0.0:
		return false
	var configured_total := float(entry.get("total", 1.0))
	var total := get_skill_cooldown_duration(id, configured_total)
	entry["total"] = total
	entry["time_left"] = total
	skill_cooldowns[key] = entry
	return true


func get_skill_cooldown_duration(_id: StringName, default_duration: float) -> float:
	return maxf(0.0, default_duration)


# ----- 契约接口（HUD 端 has_method 检测） --------------------------------------

func get_health_ratio() -> float:
	return character.get_health_ratio() if character != null else 0.0


func get_phase_index() -> int:
	return phase_index


func get_phase_count() -> int:
	return phase_thresholds.size() + 1


func get_poise_ratio() -> float:
	return 0.0 if max_poise <= 0.0 else poise / max_poise


func get_skill_cooldown_ratio(id: StringName) -> float:
	var key := String(id)
	if not skill_cooldowns.has(key):
		return 0.0
	var entry: Dictionary = skill_cooldowns[key]
	var total := float(entry.get("total", 1.0))
	if total <= 0.0:
		return 0.0
	return clampf(float(entry.get("time_left", 0.0)) / total, 0.0, 1.0)


func get_display_name_key() -> StringName:
	return display_name_key


# ----- 玩家进入交战范围时上报焦点 ----------------------------------------------

func found_player() -> bool:
	var found := super.found_player()
	if found:
		GameEvents.encounter_focus_changed.emit(self)
	return found
