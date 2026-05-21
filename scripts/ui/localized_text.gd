class_name LocalizedText
extends Label
## 本地化文本（替代 Unity 项目里的 LocalizedText.cs）
##
## 在 Inspector 里设置 chinese_text / english_text，节点会根据
## LanguageManager.current_language 自动切换显示。

@export_multiline var chinese_text: String = ""
@export_multiline var english_text: String = ""


func _ready() -> void:
	if not LanguageManager.language_changed.is_connected(_on_language_changed):
		LanguageManager.language_changed.connect(_on_language_changed)
	refresh()


func set_content(chinese: String, english: String) -> void:
	chinese_text = chinese
	english_text = english
	refresh()


func refresh() -> void:
	text = chinese_text if LanguageManager.current_language == "zh" else english_text


func _on_language_changed(_language: String) -> void:
	refresh()
