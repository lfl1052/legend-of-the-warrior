class_name Enums
extends RefCounted
## 枚举集合（替代 Unity 项目里的 Enums.cs）
##
## NPCState         敌人状态机状态
## SceneType        场景类型（菜单/关卡）
## PersistentType   存档持久化策略

enum NPCState {
	PATROL,
	CHASE,
	SKILL,
}

enum SceneType {
	## 注意：保留 Unity 端的命名（含拼写错误"Loaction"）以便存档兼容
	LOACTION = 0,
	MENU = 1,
}

enum PersistentType {
	READ_WRITE,
	DO_NOT_PERSIST,
}
