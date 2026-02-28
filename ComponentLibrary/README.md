# ComponentLibrary

该目录用于“复制即用”的通用组件包。

## 目录约定

- `Dependencies/`：统一依赖（可先整体复制）
- `Packs/`：按游戏品类拆分的组件包

## 使用方式

1. 先复制 `Dependencies/` 到目标项目。
2. 再复制所需 `Packs/<Genre>/`。
3. 在目标项目中按需注册 Autoload：
   - `EventBus`
   - `ObjectPool`
   - `TimeController`
4. 组件有局部时间需求时，把节点放到 `LocalTimeDomain` 子树下。

## 设计约束

- 组件必须允许“无依赖降级运行”（例如没有 ObjectPool 时仍能工作）。
- 组件尽量只依赖 Godot 原生节点和本目录依赖文件。
- 跨包引用优先通过信号，不强绑具体业务脚本。
