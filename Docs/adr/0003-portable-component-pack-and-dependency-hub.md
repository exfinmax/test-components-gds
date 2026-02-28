# ADR-0003: 去除多余适配层并引入可复制组件包规范

## Status

Accepted

## Context

项目定位是“通用组件仓库”，目标是组件可以复制到其他项目直接使用。  
当前问题：

- 仍有多余适配层（局部 EventChannel/ObjectPool 封装）增加理解成本；
- 组件依赖分散，迁移时容易漏文件；
- 缺少跨品类组件包，偏向当前项目玩法。

## Decision Drivers

- 组件复制成本必须最低
- 架构层次必须简单，避免过度封装
- 支持跨品类复用（不局限当前游戏）

## Considered Options

### Option 1: 保留适配层并继续扩展

- Pros: 兼容已有结构
- Cons: 复杂度持续上升

### Option 2: 全部强依赖全局服务，不提供依赖打包

- Pros: 架构最简单
- Cons: 迁移项目时需要手工补依赖，易遗漏

### Option 3: 删除多余适配层 + 统一依赖目录 + 组件包化

- Pros: 调用路径简单，复制可用性强，符合仓库定位
- Cons: 需要一次重整文档和目录

## Decision

采用 **Option 3**：

- 移除多余局部封装（如 `EventChannelComponent`、`ObjectPoolComponent`）
- 全局服务直接使用：
  - `EventBus`
  - `ObjectPool`
  - `TimeController`
- 新增统一依赖目录与组件包目录，按“依赖 + 组件”打包复制

## Consequences

### Positive

- 组件可迁移性更强
- 架构认知负担降低
- 更容易扩展到不同游戏品类

### Negative

- 旧文档与旧示例需要同步迁移
- 个别组件需要重写依赖注入方式

### Risks

- 组件包与主工程实现可能出现漂移
- 需要建立依赖清单和版本说明

## Implementation Notes

- `ImpactVFXComponent` 直接接入全局 `ObjectPool`
- `FreezeFrameEffect` 仅调用全局 `TimeController.frame_freeze()`
- 新增 `ComponentLibrary/Dependencies` 与多品类 `ComponentLibrary/Packs`

## Related Decisions

- ADR-0001: 全局服务边界与单一事实来源（被本 ADR 收紧）
- ADR-0002: 全局时间与局部时间域模型
