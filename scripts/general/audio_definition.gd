class_name AudioDefinition
extends Node
## 音效播放器（替代 Unity 项目里的 AudioDefination.cs）
##
## 挂在场景里需要触发音效的节点上：通过 GameEvents.play_fx / play_bgm
## 把声音转交给 AudioManager 自动加载播放。

enum Channel {
	FX,
	BGM,
}

@export var audio_clip: AudioStream
@export var channel: int = Channel.FX
@export var play_on_ready: bool = false


func _ready() -> void:
	if play_on_ready:
		play_audio_clip()


func play_audio_clip() -> void:
	if audio_clip == null:
		return
	match channel:
		Channel.BGM:
			GameEvents.raise_play_bgm(audio_clip)
		_:
			var pos := Vector2.ZERO
			var parent := get_parent()
			if parent is Node2D:
				pos = (parent as Node2D).global_position
			GameEvents.raise_play_fx(audio_clip, pos)
