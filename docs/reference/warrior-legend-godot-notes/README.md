# 《勇者传说｜Godot 笔记》本地参考

> 原作者：瓦格良  
> 原始文集：[Bilibili 文集号 782393](https://www.bilibili.com/read/readlist/rl782393)  
> 最近一次原文更新时间：2024-04-16  
> Godot 校订基线：Godot 4.7 stable（2026-07-11）
> 用途：本项目内部开发参考；版权归原作者及相关素材作者所有。

本目录保存了文集的 9 篇正文及其配图，Markdown 中的图片均使用本地相对路径，离线时也可以查看。原文截图继续保留用于对照旧版界面；每篇开头的“Godot 4.7 校订”才是本项目当前应采用的做法。

## 目录

1. [十分钟制作横版动作游戏｜Godot 4 教程《勇者传说》#0](00-project-setup-and-player.md)（13 张图片）
2. [通过相机发现更大的世界｜Godot 4 教程《勇者传说》#1](01-camera-and-world-bounds.md)（9 张图片）
3. [如何使用 TileMap｜Godot 4 教程《勇者传说》#2](02-tilemap-and-terrain.md)（16 张图片）
4. [如何实现视差背景｜Godot 4 教程《勇者传说》#3](03-parallax-background.md)（19 张图片）
5. [如何实现丝滑的运动｜Godot 4 教程《勇者传说》#4](04-smooth-movement.md)（11 张图片）
6. [如何实现状态机｜Godot 4 教程《勇者传说》#5](05-player-state-machine.md)（14 张图片）
7. [如何实现滑墙｜Godot 4 教程《勇者传说》#6](06-wall-slide.md)（17 张图片）
8. [如何实现蹬墙跳｜Godot 4 教程《勇者传说》#7](07-wall-jump.md)（6 张图片）
9. [野猪的基本逻辑｜Godot 4 教程《勇者传说》#8](08-boar-enemy-logic.md)（18 张图片）

## 使用说明

- `TileMap` 在 Godot 4.7 中已弃用，改用一个或多个 `TileMapLayer`。
- `ParallaxBackground` 与 `ParallaxLayer` 在 Godot 4.7 中已弃用，改用多个 `Parallax2D`。
- `CharacterBody2D`、`Camera2D`、`AnimationPlayer`、`RayCast2D`、`Timer` 和 `move_and_slide()` 仍然适用。
- Godot 4.7 新项目默认使用 `canvas_items` 拉伸模式和 `expand` 拉伸纵横比；旧项目仍应显式检查这两个设置。
- Godot 4.7 新增 2D Scene Paint Mode，可用于快速散布敌人、收集物和装饰，但地形主体仍应使用 `TileMapLayer`。
- 本地内容用于对照实现思路，不应覆盖项目当前已经演进的架构。
- 原文导入工具已经移除；如需重新同步，必须先确认不会覆盖本目录中的 4.7 校订内容。

## 官方依据

- [Godot 4.7 发布说明](https://godotengine.org/releases/4.7/)
- [从 Godot 4.6 升级到 4.7](https://docs.godotengine.org/en/4.7/tutorials/migrating/upgrading_to_godot_4.7.html)
- [使用 TileMapLayer](https://docs.godotengine.org/en/4.7/tutorials/2d/using_tilemaps.html)
- [使用 Parallax2D](https://docs.godotengine.org/en/4.7/tutorials/2d/2d_parallax.html)
- [CharacterBody2D 类参考](https://docs.godotengine.org/en/4.7/classes/class_characterbody2d.html)

当前本地副本共包含 **9 篇文章、123 张图片**。
