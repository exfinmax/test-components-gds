# ComponentLibrary 项目规划文档

> **创建日期**: 2026-03-01  
> **状态**: 架构重构中  
> **负责人**: AI辅助开发

---

## 📋 执行概要

本项目是Godot 4.6组件库系统，目标为时间操控横板跑酷游戏提供可复用组件。当前面临分类混乱和插件功能不完善的问题，需要进行系统性重构。

### 关键成果（2026-03-01）

✅ **已完成**:
1. 修复15个demo文件的语法错误（缩进、继承、API兼容）
2. 创建缺失的time_controller.gd依赖文件
3. 设计新的三层分类架构（Core/Modules/Systems）
4. 开发增强版插件（Dock面板、搜索、浏览）
5. 编写完整架构设计文档（ARCHITECTURE.md）

🔄 **进行中**:
- 目录结构重组规划
- 插件功能增强

⏸️ **待处理**:
- 实际文件迁移
- 文档编写
- 测试验证

---

## 🎯 项目目标

### 短期目标（本周）
1. **清理目录结构** - 删除测试文件夹，整理分类
2. **部署增强插件** - 替换旧插件，启用新功能
3. **完善核心模块** - 确保Combat、Movement模块完整可用

### 中期目标（本月）
1. **完成分类迁移** - 所有组件按新架构重组
2. **补充文档** - 每个模块包含README和示例
3. **测试覆盖** - 关键组件有可运行的Demo

### 长期目标（季度）
1. **扩展组件库** - 添加更多时间操控相关组件
2. **性能优化** - 组件池化、批处理
3. **C#版本** - 核心组件提供C#实现
4. **在线文档** - 构建文档站点

---

## 📊 当前状态分析

### 项目规模
- **组件总数**: ~50个组件文件
- **Pack数量**: 23个（包含无效的）
- **Demo场景**: 15个
- **系统数量**: 13个子系统

### 分类现状

#### 有效Pack（保留）
```
✅ Combat/          - 7个组件（health, hitbox, attack等）
✅ Time/            - 6个组件（时间操控相关）
✅ VFX/             - 5个组件 + 模板
✅ UI/              - 1个组件 + Transition模板
✅ RPG/             - 1个组件（attribute_set）
✅ Strategy/        - 1个组件（production_queue）
✅ Roguelike/       - 1个组件（weighted_spawn）
✅ Platformer/      - 3个组件（jump, fall_damage等）
✅ Racing/          - 1个组件（lap_checkpoint）
✅ Shooter/         - 1个组件（projectile_emitter）
✅ Survival/        - 1个组件（status_effect）
✅ Card/            - Demo存在，组件待补充
✅ Puzzle/          - Demo存在，组件待补充
✅ Foundation/      - Demo存在，组件待补充
✅ Builder/         - Demo存在，组件待补充
✅ Action/          - Demo存在，组件待补充
```

#### 需要重组
```
🔄 Character/       → 合并到 Movement/
🔄 Helpers/         → 移动到 Core/utils/
🔄 Systems/         → 展开13个子系统到Systems/
```

#### 需要删除
```
❌ 111/            - 测试文件夹
❌ SamplePackage/  - 示例文件夹
❌ Core/           - 空文件夹
```

### 依赖关系

#### 核心依赖（Dependencies/）
1. `component_base.gd` - 所有组件的基类
2. `character_component_base.gd` - 角色组件基类
3. `event_bus.gd` - 全局事件总线  
4. `object_pool.gd` - 对象池
5. `time_controller.gd` - 时间控制器（已修复）
6. `local_time_domain.gd` - 局部时间域

#### 循环依赖检查
- ✅ 无循环依赖发现
- ⚠️ 部分Demo假设组件类已注册但未实现

---

## 🏗️ 新架构设计

### 三层分类系统

```
ComponentLibrary/
├── Core/               # 第1层：核心基础设施
│   ├── base/          # 基础类
│   ├── events/        # 事件系统
│   ├── pools/         # 对象池
│   ├── time/          # 时间系统
│   └── utils/         # 工具函数
│
├── Modules/           # 第2层：功能模块
│   ├── Combat/        # 战斗系统
│   ├── Movement/      # 移动系统
│   ├── Input/         # 输入系统
│   ├── Animation/     # 动画系统
│   ├── Time/          # 时间能力
│   ├── VFX/           # 视觉特效
│   ├── UI/            # 用户界面
│   └── GameLogic/     # 游戏逻辑
│       ├── Foundation/
│       ├── Card/
│       ├── RPG/
│       ├── Roguelike/
│       ├── Strategy/
│       └── Puzzle/
│
└── Systems/           # 第3层：全局服务
    ├── Camera/        # 摄像机系统
    ├── Audio/         # 音频系统
    ├── Save/          # 存档系统
    ├── Level/         # 关卡系统
    ├── Replay/        # 回放系统
    ├── Score/         # 分数系统
    ├── Debug/         # 调试系统
    └── Platform/      # 平台系统
```

### 迁移映射表

| 当前路径 | 目标路径 | 状态 |
|---------|---------|------|
| `Packs/Combat/` | `Modules/Combat/` | 保持 |
| `Packs/Time/` | `Modules/Time/` | 保持 |
| `Packs/VFX/` | `Modules/VFX/` | 保持 |
| `Packs/UI/` | `Modules/UI/` | 保持 |
| `Packs/Platformer/` | `Modules/Movement/` | 合并 |
| `Packs/Character/` | `Modules/Movement/` | 合并 |
| `Packs/Foundation/` | `Modules/GameLogic/Foundation/` | 移动 |
| `Packs/Card/` | `Modules/GameLogic/Card/` | 移动 |
| `Packs/RPG/` | `Modules/GameLogic/RPG/` | 移动 |
| `Packs/Roguelike/` | `Modules/GameLogic/Roguelike/` | 移动 |
| `Packs/Strategy/` | `Modules/GameLogic/Strategy/` | 移动 |
| `Packs/Puzzle/` | `Modules/GameLogic/Puzzle/` | 移动 |
| `Packs/Helpers/` | `Core/utils/` | 移动 |
| `Packs/Systems/*` | `Systems/*` | 展开 |
| `Packs/111/` | - | 删除 |
| `Packs/SamplePackage/` | - | 删除 |

---

## 🔧 插件增强计划

### 原插件问题

1. **功能单一**: 只有Open Demo、New Pack、New Component
2. **无分类**: 把所有文件夹平等对待
3. **无搜索**: 无法快速找到组件
4. **无详情**: 点击后无信息显示
5. **性能差**: 每次重新创建对话框

### 增强版插件特性

✨ **新增功能**:
1. **Dock面板** - 常驻右下角，即时访问
2. **树形浏览** - 三层分类，可折叠展开
3. **搜索过滤** - 实时搜索组件名称
4. **信息面板** - 显示组件详情和操作按钮
5. **快速打开** - 双击打开脚本或Demo
6. **组件计数** - 显示每个Pack的组件数量

📄 **文件对比**:
- 旧版: `plugin.gd` (251行)
- 新版: `plugin_enhanced.gd` (500+行)

### 启用方法

```bash
# 1. 备份旧插件
mv plugin.gd plugin_old.gd

# 2. 启用新插件
mv plugin_enhanced.gd plugin.gd

# 3. 重启编辑器
# Project -> Reload Current Project
```

---

## 📐 开发规范

### 文件命名
- 组件: `feature_component.gd` (snake_case)
- 系统: `feature_system.gd` 或 `feature_manager.gd`
- Demo: `pack_name_demo.gd`
- 配置: `feature_config.gd` 或 `feature_data.tres`

### 目录结构
```
ModuleName/
├── Components/         # 必需
│   └── *.gd
├── Demo/              # 必需
│   ├── demo.tscn
│   ├── demo.gd
│   └── preview.png
├── Templates/         # 可选：预制场景
├── Resources/         # 可选：配置资源
└── README.md         # 必需
```

### 组件模板

```gdscript
extends ComponentBase  # 或 CharacterComponentBase
class_name MyComponent

## Component: My Component
## Description: What this component does
## 
## Properties:
## - property_name: Type - Description
## 
## Signals:
## - signal_name(param) - Description

signal something_happened

@export var my_property: float = 1.0

func _ready() -> void:
	super._ready()
	# Initialization

func _on_enable() -> void:
	# Called when enabled = true
	pass

func _on_disable() -> void:
	# Called when enabled = false
	pass

func get_component_data() -> Dictionary:
	return {
		"my_property": my_property,
		"enabled": enabled
	}
```

### README模板

```markdown
# ModuleName

## Overview
Brief description of what this module provides.

## Components

### component_name.gd
- **Purpose**: Clear one-line description
- **Dependencies**: List required components/systems
- **Signals**: 
  - `signal_name(params)` - What triggers it
- **Properties**:
  - `property: Type` - What it controls

## Usage Example

\```gdscript
var component = MyComponent.new()
component.my_property = 2.0
add_child(component)
\```

## Demo

Run `Demo/demo.tscn` to see all components in action.
```

---

## 📈 实施路线图

### Phase 1: 清理和修复（本周）

**优先级: P0 - 立即**

- [x] 修复time_controller.gd缺失
- [x] 修复所有Demo语法错误
- [x] 创建ARCHITECTURE.md设计文档
- [x] 开发plugin_enhanced.gd
- [ ] 删除测试文件夹（111, SamplePackage）
- [ ] 备份当前状态（git commit）
- [ ] 启用增强插件

**验收标准**:
- 所有Demo无语法错误
- 插件正常加载
- Dock面板可见且功能正常

---

### Phase 2: 重组核心（本周）

**优先级: P0 - 关键**

- [ ] 创建新目录结构（Core, Modules, Systems）
- [ ] 迁移Dependencies → Core/
- [ ] 迁移Helpers → Core/utils/
- [ ] 展开Systems子系统
- [ ] 更新插件扫描逻辑

**验收标准**:
- Core/目录包含所有依赖
- Systems/展开所有13个子系统
- 插件能正确识别新结构

---

### Phase 3: 迁移模块（下周）

**优先级: P1 - 重要**

- [ ] 迁移Combat模块（保持原样）
- [ ] 合并移动相关到Movement/
- [ ] 整理GameLogic子分类
- [ ] 迁移VFX、UI、Time模块
- [ ] 更新所有import路径

**验收标准**:
- 所有组件按新分类存放
- 无损坏的引用
- Demo仍能正常运行

---

### Phase 4: 文档和测试（2周）

**优先级: P1 - 重要**

- [ ] 为每个模块编写README
- [ ] 改进Demo质量和覆盖率
- [ ] 添加组件使用示例
- [ ] 创建快速开始指南
- [ ] 录制演示视频

**验收标准**:
- 每个模块有README
- 主要组件有可运行Demo
- 新用户能在10分钟内上手

---

### Phase 5: 功能扩展（1月）

**优先级: P2 - 改进**

- [ ] 添加组件依赖检查
- [ ] 实现一键导入功能
- [ ] 添加组件模板生成器
- [ ] 支持标签和分类过滤
- [ ] 集成文档预览器

**验收标准**:
- 插件能检测依赖问题
- 可以快速创建新组件
- 搜索和过滤高效

---

### Phase 6: 质量提升（持续）

**优先级: P3 - 优化**

- [ ] 添加单元测试框架
- [ ] 性能基准测试
- [ ] 内存泄漏检查
- [ ] C#版本组件
- [ ] 在线文档站点

---

## 🎓 技术决策记录

### ADR-001: 采用三层架构

**日期**: 2026-03-01  
**状态**: 已接受

**背景**: 原始的扁平Pack结构导致分类混乱，难以维护。

**决策**: 采用Core/Modules/Systems三层架构。

**理由**:
- Core层提供稳定的基础设施
- Modules层按功能清晰分类
- Systems层独立管理全局服务
- 易于扩展和维护

**后果**:
+ 分类清晰，易于查找
+ 依赖关系明确
- 需要大量文件迁移工作
- 旧项目需要更新路径

---

### ADR-002: 插件使用Dock面板

**日期**: 2026-03-01  
**状态**: 已接受

**背景**: 原插件使用菜单+对话框，访问不便。

**决策**: 使用常驻Dock面板提供组件浏览。

**理由**:
- 即时访问，无需打开菜单
- 树形结构更适合分类浏览
- 可以显示详细信息
- 支持搜索和过滤

**后果**:
+ 用户体验大幅提升
+ 开发效率提高
- 占用编辑器空间
- 代码复杂度增加

---

## 📚 参考资源

### 文档
- [ARCHITECTURE.md](ARCHITECTURE.md) - 详细架构设计
- [README.md](README.md) - 项目说明
- [CONTEXT.md](../CONTEXT.md) - 项目上下文

### 代码
- `plugin_enhanced.gd` - 增强版插件
- `pack_demo.gd` - Demo基类
- `Dependencies/` - 核心依赖

### 外部资源
- [Godot 4 文档](https://docs.godotengine.org/en/stable/)
- [GDScript风格指南](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html)
- [组件设计模式](https://gameprogrammingpatterns.com/component.html)

---

## ✅ 检查清单

### 开发前
- [x] 阅读ARCHITECTURE.md
- [x] 理解三层架构
- [x] 了解现有组件
- [ ] 备份当前项目

### 添加新组件
- [ ] 选择合适的模块
- [ ] 创建组件脚本（使用模板）
- [ ] 添加class_name声明
- [ ] 编写文档注释
- [ ] 创建Demo场景
- [ ] 更新模块README
- [ ] 测试组件功能

### 提交代码
- [ ] 代码格式正确（tab缩进）
- [ ] 无语法错误
- [ ] Demo可运行
- [ ] 文档完整
- [ ] Git commit message clear

---

## 🔗 联系和支持

**问题反馈**: 在项目仓库创建Issue  
**功能建议**: 提交Feature Request  
**紧急问题**: 联系项目维护者

**最后更新**: 2026-03-01
