extends Node
## 语言管理器（替代 Unity 项目里的 LanguageManager）
##
## Unity 端使用自定义 LanguageManager + LocalizedText 组件。
## Godot 端封装 TranslationServer 与 RuntimeData.ui_strings，
## 同时对外提供 set_language()/get_text(key) 和 language_changed 信号。

signal language_changed(new_language: String)

const SUPPORTED := ["zh", "en"]
const DEFAULT_LANGUAGE := "zh"
const SAVE_KEY := "language"

var current_language: String = DEFAULT_LANGUAGE


func _ready() -> void:
	_apply_language(_load_saved_language())


# ----- 公共 API ----------------------------------------------------------------

func set_language(lang: String) -> void:
	if not SUPPORTED.has(lang):
		return
	if lang == current_language:
		return
	_apply_language(lang)
	_save_language(lang)


func toggle_language() -> void:
	var idx := SUPPORTED.find(current_language)
	idx = (idx + 1) % SUPPORTED.size()
	set_language(SUPPORTED[idx])


func get_text(key: StringName) -> String:
	# 优先用 RuntimeData 的 ui_strings；缺失时回退 TranslationServer.tr
	var text := RuntimeData.try_get_ui_string(key, current_language)
	if text == String(key):
		return tr(String(key))
	return text


# ----- 内部 --------------------------------------------------------------------

func _apply_language(lang: String) -> void:
	current_language = lang
	TranslationServer.set_locale(lang)
	language_changed.emit(lang)


func _load_saved_language() -> String:
	var cfg := ConfigFile.new()
	var err := cfg.load("user://settings.cfg")
	if err != OK:
		return DEFAULT_LANGUAGE
	var lang: String = String(cfg.get_value("locale", SAVE_KEY, DEFAULT_LANGUAGE))
	return lang if SUPPORTED.has(lang) else DEFAULT_LANGUAGE


func _save_language(lang: String) -> void:
	var cfg := ConfigFile.new()
	cfg.load("user://settings.cfg")
	cfg.set_value("locale", SAVE_KEY, lang)
	cfg.save("user://settings.cfg")
