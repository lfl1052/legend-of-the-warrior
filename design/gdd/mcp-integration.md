# 系统 GDD: MCP 集成（开发期）

## 元数据

| 字段 | 值 |
|------|-----|
| **System ID** | SYS-MCP |
| **系统名称** | MCP Bridge（Model Context Protocol） |
| **优先级** | 🟢 P3 |
| **状态** | ✅ 已实现 |
| **反向文档日期** | 2026-05-20 |
| **源码参考** | `mcp_bridge_game.gd`, `addons/mcp_bridge/` |

---

## 概述

MCP Bridge 为开发期工具链，通过 TCP 协议让外部编辑器（Claude Code / 其他 AI 工具）与运行中的 Godot 游戏实例通信。支持运行时截图、场景树查询、点击模拟。

**不参与发布后运行时逻辑**。

## 架构

```
外部客户端 (Claude Code / MCP 工具)
    ↓ TCP 127.0.0.1:9501
McpBridgeGame (autoload)
    ├─ TCP Server 监听
    ├─ JSON 协议解析
    └─ 命令路由
         ├─ screenshot → RenderingServer.force_draw → get_viewport → PNG base64
         ├─ get_runtime_tree → 递归序列化 scene tree → JSON
         └─ click → InputEventMouseButton → push_input
```

## MCP 插件（Editor 侧）

**文件**: `addons/mcp_bridge/plugin.gd` (~626 行)

作为 Godot Editor Plugin 运行，处理编辑器侧命令（如获取场景树、设置节点属性等）。

## 运行时桥（Game 侧）

**文件**: `mcp_bridge_game.gd` (~152 行)

Autoload 注册，启动时 TCP 监听 `127.0.0.1:9501`（端口从 `mcp_ports.cfg` 读取）。

### 支持的命令

| cmd | 参数 | 返回 |
|-----|------|------|
| `screenshot` | 无 | `{ok: true, image_base64: "..."}` PNG base64 |
| `get_runtime_tree` | 无 | `{ok: true, tree: {name, type, children}}` 递归 JSON |
| `click` | `x, y` | `{ok: true, x, y}` 左键点击模拟 |

### 协议

- 传输层: TCP (`StreamPeerTCP`)
- 格式: JSON + `\n` 分隔
- 连接: 每帧 `_process` 轮询 `tcp_server.is_connection_available()`
- 多客户端支持: `clients: Array[StreamPeerTCP]`

### 截图流程

`screenshot` 是异步的：
1. 收到请求 → 存 `pending_screenshot_client`
2. 调 `RenderingServer.force_draw()` 确保当前帧渲染完毕
3. `_on_frame_post_draw` 回调中取 viewport texture → `save_png_to_buffer` → base64 → 响应

## 端口配置

**文件**: `mcp_ports.cfg`

```ini
[mcp]
game_port = 9501
```

## 安全说明

- 仅监听 `127.0.0.1`（本地回环），不暴露到网络
- 点击模拟通过 `push_input` 注入到 viewport，与真实鼠标事件同等处理
- **发布版本禁用** MCP 运行时 Autoload，并通过导出过滤排除 `addons/godot_ai/` 与旧桥接脚本

## 依赖

| 依赖 | 类型 | 说明 |
|------|------|------|
| `TCPServer` | Godot 内置 | TCP 连接管理 |
| `RenderingServer` | Godot 内置 | `frame_post_draw` 信号用于截图 |
| `Marshalls` | Godot 内置 | base64 编码 |

## 待做

- [ ] 暂停游戏后 MCP 截图能力验证
- [ ] HTTP 协议升级（支持更丰富的 MCP 工具定义）
