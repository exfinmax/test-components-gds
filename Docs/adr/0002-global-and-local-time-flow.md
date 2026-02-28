# ADR-0002: 全局时间与局部时间域模型

## Status

Accepted

## Context

项目中存在两类时间控制需求：

1. **全局时间控制**：例如冻结帧、全局慢放、音频同步补偿
2. **局部时间控制**：例如某个子树暂停、慢放、快进，不影响全局

Godot 默认没有节点级 `time_scale` 属性，局部时间只能通过“适配协议”实现。

## Decision Drivers

- 全局冻结帧必须统一收口，避免多处直接改 `Engine.time_scale`
- 局部时间必须显式接入，避免隐式副作用
- 尽量减少对现有组件侵入

## Considered Options

### Option 1: 所有时间控制都直接改 `Engine.time_scale`

- Pros: 实现简单
- Cons: 无法表达局部时间；并发触发易冲突

### Option 2: 每个组件自行实现时间缩放

- Pros: 单组件自治
- Cons: 代码重复且不一致，难维护

### Option 3: 全局控制器 + 局部时间域模板（显式适配）

- Pros: 全局与局部分层清晰，职责明确
- Cons: 需要为局部可控组件增加适配方法

## Decision

采用 **Option 3**：

- `TimeController` 负责全局时间与冻结帧（并发安全）
- `LocalTimeDomain` 作为局部时间父节点模板
- 组件通过 `_local_time_process/_local_time_physics_process` 显式适配

## Consequences

### Positive

- 全局冻结帧行为一致且可观测
- 局部时间可以独立暂停/慢放/快进
- 适配边界清晰，便于增量迁移

### Negative

- 未适配组件不会自动受局部时间影响
- 需要维护局部时间参与者注册逻辑

### Risks

- 误把全局逻辑放入局部域会导致行为偏差
- 需要在文档中明确“何时用全局、何时用局部”

## Implementation Notes

- `TimeController.frame_freeze()` 采用计数栈，解决连续触发恢复错乱
- `FreezeFrameEffect` 仅作为模板包装，内部调用 `TimeController`
- `TickSchedulerComponent` 已示例接入 `LocalTimeDomain`
- 新建模板场景：`Templates/Time/local_time_domain_root.tscn`

## Related Decisions

- ADR-0001: 全局服务边界与单一事实来源
- ADR-0003: 去除多余适配层并引入可复制组件包规范
