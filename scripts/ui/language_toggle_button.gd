class_name LanguageToggleButton
extends Button
## 语言切换按钮（替代 Unity 项目里的 LanguageToggleButton.cs）
##
## 点击后切换 LanguageManager 当前语言；按钮文字根据当前语言显示
## "切到另一语言"的提示。

@export var chinese_button_label: String = "English"
@export var english_button_label: String = "中文"


func _ready() -> void:
	if not pressed.is_connected(_on_pressed):
		pressed.connect(_on_pressed)
	if not LanguageManager.language_changed.is_connected(_on_language_changed):
		LanguageManager.language_changed.connect(_on_language_changed)
	_refresh_label()


func _on_pressed() -> void:
	LanguageManager.toggle_language()


func _on_language_changed(_language: String) -> void:
	_refresh_label()


func _refresh_label() -> void:
	text = chinese_button_label if LanguageManager.current_language == "zh" else english_button_label
