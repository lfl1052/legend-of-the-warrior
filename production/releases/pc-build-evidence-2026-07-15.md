# Windows / Linux 独立构建证据（2026-07-15）

## 结论

- Windows Desktop release 导出成功，独立程序在编辑器外启动后持续运行 8 秒，启动日志正常且 stderr 为空。
- Linux release 导出成功，产物文件头确认为 64 位 ELF；当前 Windows 主机未安装 WSL，也没有可用的 Linux 实机，因此尚未完成 Linux 运行时冒烟验证。
- 后续精简复验已为两个预设加入开发内容过滤并移除 MCP 运行时 Autoload；过滤后的 Windows/Linux PCK 均可生成，真实目录枚举不含测试、插件、报告或设计文档。当前会话缺少 4.7 导出模板，因此尚未把过滤后的 PCK 重新封装成 EXE/ELF。

## 工具链

- Godot：`4.7.stable.official.5b4e0cb0f`
- 编辑器：`E:\Godot\4.7-stable\editor\Godot_v4.7-stable_win64_console.exe`
- 模板目录：`%APPDATA%\Godot\export_templates\4.7.stable`
- 官方发布来源：Godot GitHub Release `4.7-stable`

下载文件与官方 `SHA512-SUMS.txt` 匹配：

| 文件 | SHA-512 |
| --- | --- |
| `Godot_v4.7-stable_win64.exe.zip` | `41645a908eb3181d6f2d1201ed7b6d6f095f6a23aaed8903d5d255277cc8d142814f3e6817f865b3cac142c39b8aff99280091d3bbdaa301517730b3ba0522b9` |
| `Godot_v4.7-stable_export_templates.tpz` | `1035dfde4edcc2472bb0c0b9610ce3ee9302642c2b9957e9066372f9f6bb759ab250c8887551a66f0bc5f51bbd9a58bb45e33a0f29844e97615a9b1138c1120e` |

## 导出预设

仓库根目录的 `export_presets.cfg` 定义：

| 预设 | 架构 | Release 输出 |
| --- | --- | --- |
| `Windows Desktop` | x86_64 | `build/windows/LegendOfTheWarrior.exe` |
| `Linux` | x86_64 | `build/linux/LegendOfTheWarrior.x86_64` |

两者均嵌入 PCK，构建目录由 `.gitignore` 排除，不提交二进制和本地日志。

## 验证记录

### Headless import

```powershell
& 'E:\Godot\4.7-stable\editor\Godot_v4.7-stable_win64_console.exe' --headless --path . --quit --import
```

- 退出码：`0`
- 未发现脚本解析错误、缺失资源或 `ERROR/WARNING/Failed`。
- gdUnit4 检测到测试环境后未加载编辑器插件；MCP 插件按设计在 headless 模式禁用。

### Windows Desktop release

```powershell
& 'E:\Godot\4.7-stable\editor\Godot_v4.7-stable_win64_console.exe' `
  --headless --path . `
  --export-release 'Windows Desktop' `
  'build\windows\LegendOfTheWarrior.exe'
```

- 退出码：`0`
- 导出日志结束于 `[ DONE ] savepack`，未发现 `ERROR/WARNING/Failed`。
- 文件大小：`116,613,800` bytes
- SHA-256：`852C762812FF2464A1D6EB40E2414FB9069AF713073DC2DEF7A4AD29B71B89B0`
- 独立运行：直接启动导出的 EXE，不传入编辑器专用参数；8 秒后进程仍存活，由验证脚本主动结束。
- stdout：Godot `4.7.stable.official.5b4e0cb0f` 启动，D3D12 Forward+ 使用 NVIDIA GeForce RTX 3060 Ti；项目 logger 注册完成。
- stderr：空。

### Linux release

```powershell
& 'E:\Godot\4.7-stable\editor\Godot_v4.7-stable_win64_console.exe' `
  --headless --path . `
  --export-release 'Linux' `
  'build\linux\LegendOfTheWarrior.x86_64'
```

- 退出码：`0`
- 导出日志结束于 `[ DONE ] savepack`，未发现 `ERROR/WARNING/Failed`。
- 文件大小：`80,986,584` bytes
- SHA-256：`373AE1B4BBEADE86E9557116292024CAB256CA22ABC1BBF60F27A94AD3474425`
- 文件头：`7F 45 4C 46 02 01 01`，即 64 位 little-endian ELF。
- 运行限制：`wsl.exe -l -q` 返回 `1` 并提示安装 WSL；本机没有 Linux 运行环境，因此未执行 Linux 独立包启动、图形/音频、权限和 `user://` 存档验证。

## 尚未关闭的发布风险

- 当前环境的 `%APPDATA%/Godot/export_templates/4.7.stable` 为空，过滤后的 EXE/ELF 重导出受模板安装阻塞；此前验证的独立二进制使用精简前 PCK。
- Windows 包未签名，Linux 包未在原生 Linux/CI runner 启动。
- 尚未执行干净用户目录下的新游戏、继续游戏、跨场景存档、全屏切换、音频、退出和崩溃恢复检查。
- 本轮没有替代完整回归、性能测试、发行平台打包或发布签署。

## 发布精简复验

- `export_presets.cfg` 排除 `tests/`、`addons/gdUnit4/`、`addons/godot_ai/`、`reports/`、`production/`、`docs/`、`design/`、构建输出与编辑器资产展示内容。
- `project.godot` 不再注册 `_mcp_game_helper`；MCP 只保留为编辑器插件。
- 主菜单课程视觉收口后重新生成最终 Windows/Linux PCK，二者均为 `4,056,980` bytes，SHA-256 均为 `87371E99F3F87B6CFE98090D4BC393AD2E7A309A322422EB378A41B2A787D5D0`；资源文件集合未新增开发目录，沿用隔离枚举的 308 个真实条目、开发目录 0 条目结论。
- Windows Godot 4.7 引擎以 `--main-pack` 挂载最新精简 PCK 并运行 120 帧，退出码 0。
- `--export-release` 明确报告缺少 `windows_debug_x86_64.exe` / `windows_release_x86_64.exe` 模板；官方 GitHub 与镜像下载在当前网络分别被重置和超时，因此没有虚报独立可执行重导出完成。
