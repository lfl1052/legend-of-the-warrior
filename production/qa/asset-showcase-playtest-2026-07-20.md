# 素材组合验收关卡试玩记录 — 2026-07-20

## 目标与通过标准

- 目标：验证 `asset_showcase_level.tscn` 能把课程森林原素材组成连续、可玩的“森林高地 → 林间河桥 → 矿洞入口”。
- 视口：640×360，Windows/OpenGL Compatibility。
- 通过标准：三个区域方向明确、素材职责正确、无明显矩形裁片/悬空套件、玩家可连续到达右端。

## 本轮发现与处理

| 严重度 | 责任系统 | 发现 | 处理结果 |
| --- | --- | --- | --- |
| P2 | level-content / asset-pipeline | 初版树冠 Tile 机械盖印后出现矩形边缘 | 移除不可靠盖印，改用 `editor_ready` 的完整树木 Scene Paint |
| P2 | renderer / asset-pipeline | `Mine Stone` 洞口右侧自带不透明岩壁底色，与蓝色天空形成方块色差 | 使用原图真实底色 `RGB(28,31,10)` 作为矿区背景，并通过顶点色渐变过渡 |
| P2 | level-content / physics | 水体覆盖连续草地、缺少正式过河结构 | 从 Geometry 中挖出 80px 河槽，使用 `Forest-1.png` 作者原桥区域建立带 World 碰撞的正式桥 prefab |
| P2 | renderer / level-content | 将 46px 完整中段重复两次后，上层木板出现额外台阶、下层阴影在复制边界断开 | 按课程图集恢复“左桥头 + 单个完整中段 + 右桥头”，桥面碰撞改为 90×8；实机放大检查只保留中段素材自身的自然错位 |
| P2 | level-content | 初版拼接桥下残留踏石；修正水素材后浪花位置过高并进入桥板区域 | 清除河槽内全部岩石并缩窄河宽；WaterTiles 位于 Geometry 后方并下移 16px，使河岸贴合地面、浪花落在桥板下方 |
| P2 | renderer / level-content | 桥头额外抬高一格导致草地尺寸不一致；水边 Terrain 透明像素露出蓝色背景 | 取消桥头抬高；水体向两岸各延伸一格并置于 Geometry 后方，让侧壁自然遮边 |
| P2 | asset-pipeline / renderer | 3×4 瀑布帧被错误横向拆成三组“浅/中/深水”，并堆叠在桥下，河流读成竖向瀑布 | 河岸 `(0..2,13..16)`、瀑布 `(3..5,13..16)`、河面 `(6..9,14..16)` 分离；瀑布三列改为纵向 4 帧 7 FPS，桥下改用三层横向 4 帧河面 |
| P2 | level-content | 矿区仅有入口和散落石堆 | 补完整双立柱木架、木料和货架作业区 |
| P3 | level-content | 森林树木孤立，三个区域像并排测试图 | 增加远/中景树群、岸边色彩过渡和地形高低变化，保留河桥中央视线 |

## 验收结果

- 森林入口：玩家、抬高平台与 Bee 同屏；绿色树群有远近和大小变化，向右方向清楚。
- 林间河桥：桥头与普通地面同高；两侧使用课程河岸列，中间使用横向动态河面，不再出现瀑布式竖向纹理；没有草地尺寸突变、蓝色边缝、踏石或悬空岩石。
- 矿洞入口：入口成为主地标；矿石堆只承担视觉边界；建筑套件组成完整木架而非悬空碎片。
- 通路：自动玩家 8.80 秒抵达 `x=1842.704`，未跌出关卡。

## 自动化与证据

- Godot 4.7 headless import：PASS。
- 素材关卡定向单测：4/4 PASS。
- 完整 GdUnit4：37 套件，196/196 PASS。
- Headless 场景装载：PASS。
- 自动通路：PASS。
- 截图：
  - `reports/playtest/asset_showcase_level/forest_entrance.png`
  - `reports/playtest/asset_showcase_level/river_ford.png`
  - `reports/playtest/asset_showcase_level/mine_entrance.png`

## 未验证内容

- 本关卡不是正式章节，没有检查点、奖励和出口流程。
- 当前素材库缺少专用矿区 Geometry Terrain，因此矿区仍使用森林 Terrain 作为连续碰撞，只表现到洞口，不冒充矿洞内部。
