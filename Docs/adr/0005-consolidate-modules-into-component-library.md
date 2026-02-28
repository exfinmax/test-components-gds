# ADR-0005: 合并 Modules 到 ComponentLibrary 并执行移动式去重

## Status

Accepted

## Context

仓库同时存在 `Modules/` 与 `ComponentLibrary/` 两套组件目录，导致：

- 同类能力分散，维护路径不唯一；
- 扩展时容易“新增一份”而不是复用原组件；
- 用户反馈场景与脚本接入成本高，目录显得臃肿。

项目目标是组件可复制、可分类、可演示，因此需要把历史组件统一归档到单一入口。

## Decision Drivers

- 组件路径必须唯一，避免重复实现
- 迁移优先“移动原文件”，不是复制一份
- 目录层次要能支撑跨品类扩展

## Considered Options

### Option 1: 保持 Modules 和 ComponentLibrary 并存

- Pros: 改动小
- Cons: 重复问题持续，认知成本高

### Option 2: 新增第三套目录做映射层

- Pros: 兼容路径
- Cons: 新增抽象层，违背“不要过度封装”

### Option 3: 直接移动 Modules 组件到 ComponentLibrary（本次采用）

- Pros: 单一事实来源，分类清晰，后续扩展更直接
- Cons: 需要一次性调整目录与文档

## Decision

采用 **Option 3**：

1. 将历史 `Modules/*/Components` 全量移动到 `ComponentLibrary/Packs/*/Components`；
2. 删除空的 `Modules/` 目录；
3. 按功能分层新增 Pack：`Foundation`、`Action`、`Time`、`UI`、`VFX`；
4. `Platformer` 由新增组件与历史平台跳跃组件合并；
5. 去除重复实现：删除 `SequenceLockComponent`，统一改用原有 `SequenceSwitchComponent`；
6. 把基类依赖移动到 `ComponentLibrary/Dependencies`：
   - `component_base.gd`
   - `character_component_base.gd`

## Consequences

### Positive

- 组件库入口统一，避免重复维护
- 分类粒度更清晰，便于拷贝和分享
- 未来新增组件默认落在 `ComponentLibrary/Packs`

### Negative

- 一次性目录变化较大
- 需要持续维护 Pack 索引与 demo 列表

### Risks

- 历史文档路径可能滞后
- 部分外部脚本若硬编码旧路径需要手工调整

## Implementation Notes

- 新增 Demo 分类：Foundation/Action/Time/UI/VFX
- Demo 脚本改为弱类型节点引用，降低类注册异常导致的场景失效风险
- 统一检查 `.tscn` 资源路径，确保无失效 `ext_resource`

## Related Decisions

- ADR-0003: 去除多余适配层并引入可复制组件包规范
- ADR-0004: 组件库插件化分发与 Demo 验收基线
