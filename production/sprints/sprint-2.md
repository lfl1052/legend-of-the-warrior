# Sprint 2 — 2026-05-27 to 2026-06-10

## Sprint Goal
完善核心系统：修复已知 bug，打磨战斗手感，扩展地图内容，添加可交互物品系统（宝箱/陶罐），为玩家提供更完整的游戏体验。

## Capacity
- Total days: 10（两周工作日）
- Buffer (20%): 2 天
- Available: 8 天

## Tasks

### Must Have (Critical Path)

| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------------|-----------|--------------|---------------------|
| 2-1 | 修复红色角色碰撞卡死 bug | gameplay-programmer | 0.5 | None | 识别导致卡死的红色角色（Boss/敌人），修复碰撞或状态机死循环；游戏不再卡死；添加回归测试 |
| 2-2 | 补充 level_2 集成测试证据 | godot-gdscript-specialist | 0.5 | 2-1 | `tests/integration/level_2_load_test.tscn` 或在 `smoke_test.gd` 中添加 level_2 验证；测试 PASS |
| 2-3 | 可交互物品系统 — 宝箱 | gameplay-programmer | 1.5 | None | `scripts/general/chest.gd` 支持打开动画、掉落物品、一次性标记；至少 1 个宝箱场景；单元测试覆盖 |
| 2-4 | 可交互物品系统 — 可破坏物（陶罐） | gameplay-programmer | 1.0 | 2-3 | `scripts/general/breakable.gd` 支持受击破碎、掉落物品；至少 1 个陶罐场景；单元测试覆盖 |
| 2-5 | 扩展 level_demo 地图长度 | level-designer | 1.5 | None | level_demo 地图长度扩展至少 2 倍；添加平台跳跃、敌人配置、宝箱/陶罐放置；TileMap 绘制完整 |

### Should Have

| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------------|-----------|--------------|---------------------|
| 2-6 | 战斗手感 — 攻击反馈强化 | gameplay-programmer | 1.0 | None | 攻击命中时：屏幕震动（camera shake）、受击顿帧（hitstop）、粒子特效；可配置强度 |
| 2-7 | AI 行为优化 — 巡逻边界检测 | ai-programmer | 0.5 | None | 敌人巡逻时正确检测边缘和墙壁，不会掉落或卡墙；PhysicsCheck 逻辑优化 |
| 2-8 | 基础音效系统 | audio-programmer | 1.0 | None | AudioManager 支持播放音效（攻击、受击、跳跃、开宝箱）；至少 5 个占位音效；音量可配置 |

### Nice to Have

| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------------|-----------|--------------|---------------------|
| 2-9 | 玩家技能 — 冲刺/闪避 | gameplay-programmer | 1.5 | None | 玩家按 K 键触发冲刺，短距离快速移动 + 无敌帧；冷却时间；动画支持 |
| 2-10 | 背景音乐系统 | audio-programmer | 0.5 | 2-8 | AudioManager 支持循环播放背景音乐；至少 1 首占位 BGM；场景切换时淡入淡出 |

## Carryover from Sprint 1

| Task | Reason | New Estimate |
|------|--------|--------------|
| Sprint 1 retrospective | 冒烟测试失败，未完成收尾流程 | 在 Sprint 2 开始前完成 |
| level_2 TileMap 绘制 | 场景结构已创建，但 TileMap 需要手动绘制 | 包含在 2-5 中 |

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| 红色角色 bug 难以重现或定位 | 中 | 高 | 2-1 预留 0.5 天，必要时请求用户提供详细重现步骤 |
| 地图扩展工作量超出预期 | 中 | 中 | 2-5 标记为 Must Have 但可降级为"部分扩展"；Nice to Have 可延后 |
| 音效资源缺失 | 高 | 低 | 2-8 使用占位音效，后续 Sprint 替换 |
| 可交互物品系统涉及新的碰撞层和保存逻辑 | 中 | 中 | 2-3/2-4 预留足够时间，复用现有 ISaveable 协议 |

## Dependencies on External Factors
- 美术资源：宝箱、陶罐、粒子特效（可使用占位资源）
- 音频资源：音效和 BGM（可使用占位资源）

## Definition of Done for this Sprint
- [x] 所有 Must Have 任务完成
- [x] 所有任务通过验收标准
- [x] QA 计划存在（`production/qa/qa-plan-sprint-2.md`）
- [x] 所有逻辑/集成 stories 单元测试 PASS（75/75）
- [x] Smoke check 通过（`/smoke-check sprint`）
- [x] QA 签核：APPROVED WITH CONDITIONS（`production/qa/qa-signoff-sprint-2-2026-05-25.md`）
- [x] 红色角色卡死 bug 已修复并验证
- [ ] level_demo 可玩时长至少 3-5 分钟
- [x] 设计文档随实现偏离同步更新（stories、sprint status、QA evidence）
- [ ] 代码评审 + 合并（代码评审已完成；合并待用户批准）

---

**Scope check**: 如果此 Sprint 包含超出原始 epic 范围的 stories，在实现开始前运行 `/scope-check [epic]` 以检测范围蔓延。
