# 如何实现丝滑的运动｜Godot 4 教程《勇者传说》#4

> 原作者：瓦格良  
> 原文：[Bilibili 专栏 cv27731770](https://www.bilibili.com/read/cv27731770)  
> 所属文集：[勇者传说｜Godot 笔记](https://www.bilibili.com/read/readlist/rl782393)  
> 本地编号：5/9

---

## Godot 4.7 校订

本篇的 `CharacterBody2D`、`move_toward()`、`Timer`、郊狼时间和跳跃缓冲思路在 Godot 4.7 中仍然有效。实现时补充以下约束：

- 输入动作名使用 `StringName`（例如 `&"jump"`），减少重复字符串转换并提高拼写检查的可读性。
- 只在角色离地时累加重力，避免长时间站立后积累无意义的向下速度。
- 调用 `move_and_slide()` 前记录 `was_on_floor`，调用后再检查 `is_on_floor()`，才能正确识别“刚走出平台”。
- 主动跳跃时立即停止郊狼计时器，避免把主动离地误判为走出平台。
- 跳跃缓冲计时器和郊狼计时器都应启用 `one_shot`，并在进入地面状态时清理过期状态。
- 可变跳高只应在角色仍向上运动时截断 `velocity.y`。

```gdscript
const JUMP: StringName = &"jump"
const JUMP_VELOCITY := -320.0

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(JUMP):
		jump_request_timer.start()
	elif event.is_action_released(JUMP) and velocity.y < JUMP_VELOCITY * 0.5:
		velocity.y = JUMP_VELOCITY * 0.5

func move_player(delta: float) -> void:
	var was_on_floor := is_on_floor()
	# 在这里计算水平速度和离地重力。
	move_and_slide()

	if was_on_floor and not is_on_floor() and velocity.y >= 0.0:
		coyote_timer.start()
```

本项目现有实现位于 [player_controller.gd](../../../scripts/player/player_controller.gd)。官方参考：[CharacterBody2D](https://docs.godotengine.org/en/4.7/classes/class_characterbody2d.html)、[Timer](https://docs.godotengine.org/en/4.7/classes/class_timer.html)。

## 原教程正文（历史界面）

## 知识点：

-  郊狼时间：出自华纳公司的卡通形象威利狼，特点是在跑出悬崖后并不会立即坠落，而是依然能悬空一小段时间。

## 场景：

- 为了让角色丝滑的运动，修改角色脚本(player.gd)的移动速度RUN_SPEED=160和跳跃高度JUMP_VELOCITY=-320

![原文图片 1](images/04/001.png)

- 修改速度向量用move_toward()函数，按住ctrl+鼠标左键点击函数，可以跳转到编辑器内置的文档

![原文图片 2](images/04/002.png)

- 为了让角色能在起步和停止有个过程，添加水平加速度

![原文图片 3](images/04/003.png)

- 为了让角色空中转体更丝滑，将水平加速度修改为地面加速度，并添加空中转体加速度

![原文图片 4](images/04/004.png)

-  为角色添加郊狼时间，让角色能离开平台后的一段时间依然能起跳

a. 添加一个计时器改名为CoyoteTimer

![原文图片 5](images/04/005.png)

![原文图片 6](images/04/006.png)

b. 判断角色是否在地面上

c. 如果移动之前在地面，移动后，角色离开了地面

d. 启动郊狼时间的计时器

e. 否则就是角色着陆了，可以提前停止计时器

f. 角色离开地面有两种情况，一种是走出平台，一种是主动起跳，需要避免主动起跳触发郊狼时间的情况，单独设置角色当前是否起跳的状态

![原文图片 7](images/04/007.png)

- 为角色添加跳跃预输入

  - 添加计时器改名为JumpRequestTimer

![原文图片 8](images/04/008.png)

![原文图片 9](images/04/009.png)

- 按下jump键的时刻启动计时器

- 不每帧判断是否按下jump按键，而是使用事件回调函数_unhandled_input()判断

![原文图片 10](images/04/010.png)

- 为角色添加不同强度的跳跃

  - 短按轻跳，长按大跳

![原文图片 11](images/04/011.png)
