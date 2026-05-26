class_name RewardNotificationUI
extends Control
## 奖励提示横幅（替代 Unity 项目里的 RewardNotificationUI.cs）
##
## 监听 GameEvents.reward_notification(reward_id, payload)：
## payload 至少包含 notification_key / notification_chinese / notification_english
## 三个字段（可来自 LootTableResource.entries 单条记录）。
## 表现：弹入 0.18s -> 显示 1.8s（重要奖励 2.35s）-> 淡出 0.35s。

@export_node_path("CanvasItem") var label_path: NodePath
@export var visible_duration: float = 1.8
@export var major_visible_duration: float = 2.35
@export var fade_duration: float = 0.35
@export var enter_duration: float = 0.18

var _label: Label
var _queue: Array[Dictionary] = []
var _busy: bool = false
var _current_tween: Tween = null


func _ready() -> void:
	_label = get_node_or_null(label_path) as Label
	modulate.a = 0.0
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if not GameEvents.reward_notification.is_connected(_on_reward_notification):
		GameEvents.reward_notification.connect(_on_reward_notification)


func _exit_tree() -> void:
	if GameEvents.reward_notification.is_connected(_on_reward_notification):
		GameEvents.reward_notification.disconnect(_on_reward_notification)
	_cancel_current_tween()
	_queue.clear()
	_busy = false


func _on_reward_notification(reward_id: StringName, payload) -> void:
	var data := _resolve_payload(reward_id, payload)
	if data.is_empty():
		return
	_queue.append(data)
	if not _busy:
		_play_next()


func show_message(key: String, fallback_chinese: String, fallback_english: String) -> void:
	var entry := {
		"chinese": fallback_chinese,
		"english": fallback_english,
		"major": false,
	}
	if key != "":
		var localized := LanguageManager.get_text(key)
		if localized != key and localized != "":
			# get_text 找到了对应翻译，按当前语言覆盖两侧
			if LanguageManager.current_language == "zh":
				entry.chinese = localized
			else:
				entry.english = localized
	_queue.append(entry)
	if not _busy:
		_play_next()


func _resolve_payload(reward_id: StringName, payload) -> Dictionary:
	var entry := {"chinese": String(reward_id), "english": String(reward_id), "major": false}
	if payload is Dictionary:
		var dict := payload as Dictionary
		if dict.has("notification_chinese"):
			entry.chinese = String(dict["notification_chinese"])
		if dict.has("notification_english"):
			entry.english = String(dict["notification_english"])
		if dict.has("notification_key"):
			var key := String(dict["notification_key"])
			if key != "":
				var localized := LanguageManager.get_text(key)
				if localized != key and localized != "":
					if LanguageManager.current_language == "zh":
						entry.chinese = localized
					else:
						entry.english = localized
		if dict.has("major"):
			entry.major = bool(dict["major"])
	return entry


func _play_next() -> void:
	_cancel_current_tween()
	if _queue.is_empty():
		_busy = false
		return
	_busy = true
	var entry: Dictionary = _queue.pop_front()
	if _label != null:
		_label.text = entry.chinese if LanguageManager.current_language == "zh" else entry.english
	_play_once(bool(entry.get("major", false)))


func _play_once(is_major: bool) -> void:
	var hold := major_visible_duration if is_major else visible_duration
	_current_tween = create_tween()
	_current_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_current_tween.tween_property(self, "modulate:a", 1.0, enter_duration).from(0.0)
	_current_tween.tween_interval(hold)
	_current_tween.tween_property(self, "modulate:a", 0.0, fade_duration)
	_current_tween.finished.connect(_on_current_tween_finished)


func _on_current_tween_finished() -> void:
	_current_tween = null
	_play_next()


func _cancel_current_tween() -> void:
	if _current_tween != null and _current_tween.is_valid():
		_current_tween.kill()
	_current_tween = null
