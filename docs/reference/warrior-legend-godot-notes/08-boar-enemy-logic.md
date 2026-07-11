# 野猪的基本逻辑｜Godot 4 教程《勇者传说》#8

> 原作者：瓦格良  
> 原文：[Bilibili 专栏 cv33837976](https://www.bilibili.com/read/cv33837976)  
> 所属文集：[勇者传说｜Godot 笔记](https://www.bilibili.com/read/readlist/rl782393)  
> 本地编号：9/9

---

勇者传说 #8

人物素材： https://brullov.itch.io/generic-char-asset

环境素材： https://anokolisa.itch.io/sidescroller-pixelart-sprites-asset-pack-forest-16x16

## 知识点

- Collision Layer 碰撞层

  - 节点自身所处的碰撞层

  - 一个节点可以同时位于多个不同的碰撞层上，也可以不处于任何碰撞层

- Collision Mask 碰撞遮罩/碰撞掩码

  - 当前节点能够和哪些碰撞层的对象相碰撞

- 实际应用最好命名碰撞/遮罩层，而不是使用默认的数字标识

## 场景

- 创建敌人

  - 新建场景，根节点CharacterBody2D，重命名为Enemy

  - 根节点下添加一个Node2D节点并改名为Graphics

    - 添加一个Sprite2D节点

  - 根节点下添加一个CollisionShape2D节点来定义碰撞形状

  - 根节点下添加一个AnimationPlayer节点用来定义动画

  - 根节点下添加一个StateMachine节点用来定义具体的逻辑

  - 保存场景命名为enemy

![原文图片 1](images/08/001.png)

- 在根节点添加一个脚本，用来定义敌人的类

![原文图片 2](images/08/002.png)

- 创建野猪

  - 新建场景，点击链条按钮，以enemy.tscn场景为父场景

![原文图片 3](images/08/003.png)

- 黄色节点是继承过来的节点

- 将新建场景的根节点改名为Boar并保存场景

- 添加野猪的4个动画(步骤参考前期笔记，此处省略)

  - hit不开启动画循环，idle、run、walk开启动画循环

- 为野猪的CollisionShape2D节点设置圆形碰撞区域

![原文图片 4](images/08/004.png)

- 为Graphics节点添加RayCast2D节点，改名为WallChecker，调整到眼睛位置

![原文图片 5](images/08/005.png)

- 添加RayCast2D节点，改名为FloorChecker，不要放到x轴上，调整到下巴附近位置

![原文图片 6](images/08/006.png)

- 添加RayCast2D节点，改名为PlayerChecker，调整到视野前方，并适当拉长

![原文图片 7](images/08/007.png)

- 野猪节点展示

![原文图片 8](images/08/008.png)

- 调整碰撞层

  - 将Player的碰撞层设置于Player层

![原文图片 9](images/08/009.png)

- 将Player的遮罩层设置为只能和Environment层相碰撞

![原文图片 10](images/08/010.png)

- 将Boar的碰撞层设置为Enemy层

![原文图片 11](images/08/011.png)

- 将Boar的遮罩层设置为只能和Environment层相碰撞

![原文图片 12](images/08/012.png)

- 将PlayerChecker的遮罩层设置为只能和Player层相碰撞

![原文图片 13](images/08/013.png)

- 将FloorChecker和WallChecker的遮罩层设置为只能和Environment层相碰撞

![原文图片 14](images/08/014.png)

- 逻辑实现

  - 在Boar场景的根节点右键，选择扩展脚本，用来处理野猪的逻辑状态

  - 为Boar场景添加Timer节点，改名为CalmDownTimer，用来给记录野猪从遇到玩家奔跑到看不到玩家之后的冷静时间，等待时间设置为2.5秒，勾选One Shot，并拖入扩展脚本中

![原文图片 15](images/08/015.png)

- 为enemy.gd脚本添加移动函数

![原文图片 16](images/08/016.png)

- 处理boar.gd中野猪行为的每一帧行为

![原文图片 17](images/08/017.png)

- 添加敌人

  - 在world.tscn场景中点击链条按钮，选择boar.tscn场景，添加一只野猪进行测试

![原文图片 18](images/08/018.png)

## 代码

- enemy.gd

```gdscript
class_name Enemy
extends CharacterBody2D

@onready var graphics: Node2D = $Graphics
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var state_machine: StateMachine = $StateMachine

# 敌人面朝的方向
enum Direction {
	# 面向左边
	LEFT = -1,
	# 面向右边
	RIGHT = +1,
}

@export var direction := Direction.LEFT:
	set(v):
		direction = v
        # 等待节点ready
		if not is_node_ready():
			await ready
		graphics.scale.x = -direction

# 最大速度
@export var max_speed: float = 180
# 加速度
@export var acceleration: float = 2000

# 获取引擎给的重力加速度
var default_gravity := ProjectSettings.get("physics/2d/default_gravity") as float

func move(speed: float, delta: float) -> void:
	# 修改速度向量
	velocity.x = move_toward(velocity.x, speed * direction, acceleration * delta)
	velocity.y += default_gravity * delta

	move_and_slide()

```

- boar.gd

```gdscript
extends Enemy

enum  State {
	IDLE,
	WALK,
	RUN,
}

@onready var wall_checker: RayCast2D = $Graphics/WallChecker
@onready var player_checker: RayCast2D = $Graphics/PlayerChecker
@onready var floor_checker: RayCast2D = $Graphics/FloorChecker
@onready var calm_down_timer: Timer = $CalmDownTimer

# 每一帧的逻辑
func tick_physics(state: State,delta: float) -> void:
	match state:
		State.IDLE:
			move(0.0, delta)

		State.WALK:
			move(max_speed / 3, delta)

		State.RUN:
			if wall_checker.is_colliding() or not floor_checker.is_colliding():
				@warning_ignore("int_as_enum_without_cast")
				direction *= -1
			move(max_speed, delta)
			if player_checker.is_colliding():
				calm_down_timer.start()

# 获取下一个状态
func get_next_state(state: State) -> State:
	# 野猪碰见玩家则立即冲向玩家
	if player_checker.is_colliding():
		return State.RUN

	match state:
		State.IDLE:
			# 野猪空闲超过2秒则进入走动状态
			if state_machine.state_time > 2:
				return State.WALK

		State.WALK:
			# 野猪碰到墙壁或者前面没路的时候进入空闲状态
			if wall_checker.is_colliding() or not floor_checker.is_colliding():
				return State.IDLE

		State.RUN:
			# 野猪的冷静计时器到点后，进入走动状态
			if calm_down_timer.is_stopped():
				return State.WALK
	# 保持当前状态不变
	return state

# 状态转换
@warning_ignore("unused_parameter")
func transition_state(from: State,to: State) -> void:
	print("[%s] %s => %s" %[
		Engine.get_physics_frames(),
		State.keys()[from] if from != -1 else "<START>",
		State.keys()[to],
	])
	match to:
		State.IDLE:
			animation_player.play("idle")
			# 如果前方是墙，则野猪转身
			if wall_checker.is_colliding():
				@warning_ignore("int_as_enum_without_cast")
				direction *= -1

		State.WALK:
			animation_player.play("walk")
			# 如果前方是悬崖，则野猪转身
			if not floor_checker.is_colliding():
				@warning_ignore("int_as_enum_without_cast")
				direction *= -1
                # 转身后强制更新射线的缓存
				floor_checker.force_raycast_update()

		State.RUN:
			animation_player.play("run")

```
