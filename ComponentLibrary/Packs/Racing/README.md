# Racing Pack

## 组件

- `LapCheckpointComponent`

## 依赖

- 无硬依赖

## 使用

- 配置 `checkpoint_order`
- 每次经过检查点调用 `pass_checkpoint(checkpoint_id)`
- 监听 `lap_completed` 统计圈数
