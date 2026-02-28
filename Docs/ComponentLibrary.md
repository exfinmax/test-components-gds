# ComponentLibrary 使用说明

此文档介绍 ComponentLibrary 项目的结构、编辑器插件功能，以及如何添加新内容。 本库旨在提供可复用的 Godot 组件和演示。

## 目录结构

```
ComponentLibrary/
  Packs/                      # 按类型组织的子模块
    Action/
      Components/            # GDScript 组件
      Demo/                  # 演示场景
      Templates/             # 可实例化的模板资源
    UI/
    VFX/
    ... (其他 Pack)
  Dependencies/               # 通用依赖脚本（事件总线、对象池等）
  Shared/                     # 跨包共享脚本（例如 pack_demo.gd）
```

演示场景统一命名为 `<pack>_demo.tscn`，其脚本继承自
`res://ComponentLibrary/Shared/pack_demo.gd` 并通过 `pack_name`
属性指明所属包。 运行时这些脚本会自动实例化包内
`Components` 目录下的所有 `.tscn`。

## 编辑器插件（addons/component_library_share）

插件在编辑器中注册所有组件为自定义类型，方便拖放。其主要功能：

- 自动扫描 `Packs/*/Components` 并注册脚本为 `Node` 类型（名称
  来源于脚本的 `class_name` 或文件名）。
- 注册依赖脚本，如事件总线、计时器等。
- 在菜单 `ComponentLibrary` 下提供：
  - **Open Demo**：按包名打开对应的演示场景。
  - **New Pack**：弹出输入对话框，创建新的包目录结构并生成默认
    演示场景。
  - **New Component**：输入包名和蛇形命名组件名称，生成脚本模板并
    在编辑器中打开。

插件会在启动时动态收集现有 Pack 名称，因此新增包无需改动代码。

### 扩展插件

若需添加更多操作，可在 `addons/component_library_share/plugin.gd`
中添加相应菜单项和处理函数。注册类型的逻辑统一在
`_scan_and_register` 中，递归遍历目录并加载脚本。

## 添加新组件/包的流程

1. 从菜单选择 `ComponentLibrary > New Pack`，输入包名。
2. 在新创建的 `Packs/<name>/Components` 中新建脚本，或使用
   `New Component` 菜单。
3. （可选）在 `Packs/<name>/Templates` 下放置可实例化模板。
4. 编辑/demo 逻辑可以修改生成的 `<name>_demo.gd`。

## 版本打包

发布时只需将 `ComponentLibrary` 目录和 `addons/component_library_share`
以及 `Docs/ComponentLibrary.md` 压缩为一个插件包即可。

---

以上文档可作为 README 或进一步翻译为英文，便于分享。欢迎根据
项目需求补充更多示例与说明。
