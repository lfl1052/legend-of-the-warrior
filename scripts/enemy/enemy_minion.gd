class_name EnemyMinion
extends Enemy
## 杂兵（替代 Unity 项目里的 EnemyMinion）
##
## 与 Enemy 的区别：杂兵只有 Patrol/Chase 两种主行为，无 SKILL 状态时退化为 Chase。
## 子类（Bee/Boar/Snail）会在 _setup_states 注入具体状态。
