# Dependencies

复制组件包前，建议先复制本目录。

## 文件

- `event_bus.gd`: 全局事件总线（建议 Autoload 名为 `EventBus`）
- `object_pool.gd`: 全局对象池（建议 Autoload 名为 `ObjectPool`）
- `time_controller.gd`: 全局时间控制（建议 Autoload 名为 `TimeController`）
- `local_time_domain.gd`: 局部时间域父节点模板

## 兼容规则

- 组件通常先尝试使用这些全局服务。
- 若全局服务不存在，组件应尽量回退到非池化/非总线逻辑。
