class_name IInteractable
extends RefCounted
## 交互接口约定（替代 Unity 项目里的 IInteractable）
##
## Godot 没有真正的 interface，使用"鸭子类型 + 命名约定"：
## 任何节点只要声明 `func trigger_action() -> void` 就被视为可交互。
## 这里给出方法签名的占位形式，方便子类显式继承（也允许独立实现）。

func trigger_action() -> void:
	push_warning("IInteractable.trigger_action() 未实现")
