# Strategy Pack

## 组件

- `ProductionQueueComponent`

## 依赖

- 无硬依赖
- 可选接入 `LocalTimeDomain`（实现 `_local_time_process`）

## 使用

- 生产队列入队：`enqueue_job("worker", 3.0, {"cost": 50})`
- 监听 `job_completed` 执行产出逻辑
