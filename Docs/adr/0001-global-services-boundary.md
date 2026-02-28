# ADR-0001: 全局服务边界与单一事实来源

## Status

Accepted

## Context

当前仓库同时存在：

- 全局 `EventBus` 与局部 `EventChannelComponent`
- 全局 `ObjectPool` 与局部 `ObjectPoolComponent`
- 全局时间控制与局部冻结逻辑

这会导致“同类能力双轨并存”，带来以下问题：

- 行为不一致：同一个概念在不同模块表现不同
- 维护成本高：修一个 bug 需要查两套实现
- 接入困难：新组件不知道应该依赖哪套能力

## Decision Drivers

- 必须降低系统重复实现
- 必须保留可扩展性与场景级适配能力
- 必须尽量兼容现有组件调用方式

## Considered Options

### Option 1: 保留双轨并继续共存

- Pros: 兼容性最高，短期改动最小
- Cons: 技术债持续累积，长期不可维护

### Option 2: 全部迁移到模块内局部实现

- Pros: 场景自治更强
- Cons: 违背“跨场景共享”能力的本质，重复建设更多

### Option 3: 全局服务为唯一事实来源，模块组件转为适配层

- Pros: 统一能力边界，便于维护；模块仍可提供场景友好 API
- Cons: 需要一次性梳理并重构现有重复组件

## Decision

采用 **Option 3**：

- `EventBus` 作为唯一全局事件总线
- `ObjectPool` 作为唯一全局对象池
- `Modules/Foundation` 中同类组件改为“适配器/门面”，不再维护并行实现

## Consequences

### Positive

- 同类能力收敛，减少重复逻辑
- 新组件接入路径明确
- 模块层仍可提供低耦合封装（如命名空间、默认配置）

### Negative

- 需要迁移已有组件依赖
- 适配层设计不当会引入间接调用调试成本

### Risks

- 旧场景可能仍依赖局部实现细节
- 需要提供过渡期兼容 API

## Implementation Notes

- `EventChannelComponent` 仅负责：
  - 本地信号分发
  - 可选转发到全局 `EventBus`（支持命名空间）
- `ObjectPoolComponent` 仅负责：
  - 自动注册/注销全局池
  - 借出/回收的便捷包装

## Related Decisions

- ADR-0002: 全局时间与局部时间域模型

