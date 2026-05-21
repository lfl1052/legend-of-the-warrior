# Sprint 1 — 2026-05-21 to 2026-06-03

## Sprint Goal
锁定基础系统：用单元测试覆盖核心数据契约，补齐缺失的 JSON 配置，让现有 demo 关卡的所有代码路径都有测试覆盖或真实数据。

## Capacity
- Total days: 10（两周工作日）
- Buffer (20%): 2 天
- Available: 8 天

## Tasks

### Must Have (Critical Path)

| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------------|-----------|--------------|---------------------|
| 1-1 | 创建 5 份起步 JSON 配置文件 | gameplay-programmer | 1.0 | None | `data/loot.json`、`progression.json`、`chapters.json`、`scene_links.json`、`ui_strings.json` 全部存在；`RuntimeData` 启动无 push_warning；至少 demo 关卡所需条目齐全 |
| 1-2 | DataManager save/load 往返单元测试 | godot-gdscript-specialist | 1.0 | 1-1 | 3 个用例：`test_data_manager_save_writes_schema_v1` / `test_data_manager_load_restores_float_data` / `test_data_manager_corrupted_file_quarantines_to_bak`；全部 PASS |
| 1-3 | Attack 攻击冷却逻辑单元测试 | godot-gdscript-specialist | 0.5 | None | 3 个用例：one-shot 模式仅命中一次 / repeat 模式遵守 attack_rate / 目标退出后冷却清除；全部 PASS |
| 1-4 | PlayerProgression 代币逻辑单元测试 | godot-gdscript-specialist | 0.5 | 1-1 | 3 个用例：宝箱奖励正确累加 / 重复开宝箱不发放 / 解锁槽位幂等；全部 PASS |
| 1-5 | 冒烟测试整理 + GdUnit4 集成验证 | godot-gdscript-specialist | 0.5 | 1-2,1-3,1-4 | `runtest.cmd` 跑通所有 unit 测试；`tests/smoke_test.gd` 在文档里标注独立运行方式；测试目录结构符合 `tests/unit` + `tests/e2e` |

### Should Have

| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------------|-----------|--------------|---------------------|
| 1-6 | BossEnemy 专属 skill_state 实现 | ai-programmer | 1.5 | None | 至少 1 个可用 boss 技能状态；CHASE → SKILL → CHASE 切换闭环；附带 1 个集成测试场景 |
| 1-7 | dev-only validator: 检查 GameSceneResource.scene_path 文件存在 | gameplay-programmer | 0.5 | None | 编辑器内运行的工具脚本，扫描 `data/*.tres`，输出缺失文件列表；可挂在 `Tools/` 下 |

### Nice to Have

| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------------|-----------|--------------|---------------------|
| 1-8 | 第二关脚手架 + chapter 关联 | level-designer | 1.0 | 1-1 | `scenes/levels/level_2.tscn` 基础结构；`data/scene_level_2.tres`；`chapters.json` 中 chapter_1 包含两关 |

## Carryover from Previous Sprint

| Task | Reason | New Estimate |
|------|--------|--------------|
| (无) | Sprint 1，无前序 | — |

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| GdUnit4 在 Windows 下首跑可能需要环境变量调试 | 中 | 中 | 1-5 留 0.5 天 buffer，必要时改用 GUT |
| Boss skill_state 涉及动画资源缺失 | 中 | 低 | Should Have 优先级，可降级为占位逻辑 |
| JSON 字段约定与代码隐式期望不一致 | 中 | 高 | 1-1 完成后立即跑 1-2/1-4 验证读路径 |

## Dependencies on External Factors
- 无外部依赖（单人 / 离线项目）

## Definition of Done for this Sprint
- [ ] 所有 Must Have 任务完成
- [ ] 所有任务通过验收标准
- [ ] QA 计划存在（`production/qa/qa-plan-sprint-1.md`）
- [ ] 所有逻辑/集成 stories 单元测试 PASS
- [ ] Smoke check 通过（`/smoke-check sprint`）
- [ ] QA 签核：APPROVED 或 APPROVED WITH CONDITIONS
- [ ] Demo 关卡无 S1/S2 bug
- [ ] 设计文档随实现偏离同步更新
- [ ] 代码评审 + 合并

> **Scope check**: 本 sprint 全部 stories 都是 Sprint 0 阶段报告中明确的 gap 收尾，未引入新 epic。如果后续 1-6 / 1-8 拆出更多子任务，再跑 `/scope-check`。
