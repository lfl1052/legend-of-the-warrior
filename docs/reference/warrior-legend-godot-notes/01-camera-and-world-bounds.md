# 通过相机发现更大的世界｜Godot 4 教程《勇者传说》#1

> 原作者：瓦格良  
> 原文：[Bilibili 专栏 cv23972760](https://www.bilibili.com/read/cv23972760)  
> 所属文集：[勇者传说｜Godot 笔记](https://www.bilibili.com/read/readlist/rl782393)  
> 本地编号：2/9

---

## Godot 4.7 校订

- 原教程的 `Camera2D` 拖拽边距、位置平滑和限制属性在 4.7 中仍然有效。
- 地图类型改为 `TileMapLayer`。`get_used_rect()` 返回图块坐标范围，不是像素范围；地图节点有偏移时，应通过 `map_to_local()` 和 `to_global()` 转换后再写入相机限制。
- `reset_smoothing()` 仍可在设置限制后把相机立即对齐到当前平滑目标。
- 如果关卡有独立的相机边界碰撞体或设计区域，应优先读取明确配置的边界；装饰图块可能扩大 `get_used_rect()`，不适合作为玩法边界。

```gdscript
extends Node2D

@onready var ground: TileMapLayer = $Ground
@onready var camera: Camera2D = $Player/Camera2D

func _ready() -> void:
	var used := ground.get_used_rect()
	if used.size == Vector2i.ZERO:
		return

	var half_tile := Vector2(ground.tile_set.tile_size) * 0.5
	var first_cell := ground.map_to_local(used.position) - half_tile
	var last_cell := ground.map_to_local(used.end - Vector2i.ONE) + half_tile
	var world_begin := ground.to_global(first_cell)
	var world_end := ground.to_global(last_cell)

	camera.limit_left = int(floor(world_begin.x))
	camera.limit_top = int(floor(world_begin.y))
	camera.limit_right = int(ceil(world_end.x))
	camera.limit_bottom = int(ceil(world_end.y))
	camera.reset_smoothing()
```

本项目已有更稳妥的相机边界组件：[camera_control.gd](../../../scripts/utilities/camera_control.gd)。官方参考：[Camera2D](https://docs.godotengine.org/en/4.7/classes/class_camera2d.html)、[TileMapLayer.get_used_rect](https://docs.godotengine.org/en/4.7/classes/class_tilemaplayer.html#class-tilemaplayer-method-get-used-rect)。

## 原教程正文（历史界面与代码）

## 设置编辑器：

- 点击编辑器=》编辑器设置=》文本编辑器=》不全=》添加类型提示(勾选)

  - 类型补全能够提gdscripts性能

  - 后续补全能利用到类型信息

![原文图片 1](images/01/001.png)

## 场景

1.选择world场景，选择TileMap节点，点击下方TileMap菜单，选择图块进行地图扩展
  - crtl+左键点击 吸取单个图块

  - crtl+按住左键拖动 吸取多个图块

  - crtl+shift+按住左键拖动 绘制矩形区域

  - 右键删除图块

![原文图片 2](images/01/002.png)

2.让画面跟随玩家移动，给Player节点添加Camera2D节点

![原文图片 3](images/01/003.png)

3.拖动相机的十字准星，可以调整相机的位置，按住crtl再拖动，可以方便的对齐到其他节点

![原文图片 4](images/01/004.png)

4.对齐到Player节点的中心

![原文图片 5](images/01/005.png)

5.游戏中相机并不总是跟随玩家，玩家在屏幕中心附近有一定的自由活动空间
  - 在Camera2D节点的Drag属性勾选Horizontal Enable和Vertical Enable （水平和垂直方向上的相机拖动功能）

  - 在Camera2D节点的Editor属性勾选Draw Drag Margin，可以观察到可自由活动的范围，通过调整Drag属性的Left Margin等，可以控制其大小，值是0至1的比例

![原文图片 6](images/01/006.png)

6.实现相机平滑移动，勾选Camera2D节点的Position Smoothing下的Enabled
  - 其中Speed可调整相机的平滑移动速度

![原文图片 7](images/01/007.png)

7.限制相机拍摄范围，禁止相机拍到地图外，利用标尺量出地图底部距离，然后在Camera2D的Limit中设置Bottom为量出的数值，接着勾选Smoothed实现相机碰到极限时平滑移动

![原文图片 8](images/01/008.png)

![原文图片 9](images/01/009.png)

8.代码自动限制相机范围，给World根节点添加脚本

```gdscript
extends Node2D
@onready var tile_map: TileMap = $TileMap
@onready var camera_2d: Camera2D = $Player/Camera2D

func _ready() -> void:
	# 获取瓦片地图的范围
	var used := tile_map.get_used_rect()
	# 获取单个图块的尺寸
	var tile_size:=tile_map.tile_set.tile_size
	# 为相机的上下左右添加限制
	camera_2d.limit_top= used.position.y * tile_size.y
	camera_2d.limit_right= used.end.x * tile_size.x
	camera_2d.limit_bottom= used.end.y * tile_size.y
	camera_2d.limit_left= used.position.x * tile_size.x
	# 将相机的位置立即设置为其当前平滑的目标位置。
	camera_2d.reset_smoothing()

```
