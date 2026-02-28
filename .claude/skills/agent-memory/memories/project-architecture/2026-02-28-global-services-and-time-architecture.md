---
summary: "仓库架构从“局部适配封装”进一步收敛为“全局服务直连 + 统一依赖目录 + 可复制组件包”。"
created: 2026-02-28
updated: 2026-02-28
status: resolved
tags: [architecture, component-library, godot, refactor, reusable]
related:
  - Docs/adr/0001-global-services-boundary.md
  - Docs/adr/0002-global-and-local-time-flow.md
  - Docs/adr/0003-portable-component-pack-and-dependency-hub.md
  - ComponentLibrary/README.md
  - Modules/VFX/Common/Components/impact_vfx_component.gd
---

# 背景

用户明确要求：

1. 删除多余封装，不要过度抽象；
2. 组件仓库要跨品类扩展，不局限当前项目玩法；
3. 组件应可复制，依赖应统一集中。

# 本轮关键调整

1. 全局服务边界继续收紧：
   - 删除 `EventChannelComponent`（不再保留局部事件总线包装）。
   - `ImpactVFXComponent` 直接接入全局 `ObjectPool`。
2. 新增 ADR-0003：
   - 明确“去适配层 + 依赖中枢 + 组件包化”。
3. 新增 `ComponentLibrary/`：
   - `Dependencies/`：统一依赖脚本
   - `Packs/`：Shooter / RPG / Strategy / Survival / Card
4. 安装了技能：
   - `develop-web-game`
   - `doc`

# 仍待继续

1. 把旧 `Modules/*` 组件逐步迁移为“可复制包”目录风格。
2. 为每个组件包补一个演示场景（含最小输入与日志输出）。
3. 清理未跟踪 `.uid` 与实验插件目录，减少仓库噪音。

