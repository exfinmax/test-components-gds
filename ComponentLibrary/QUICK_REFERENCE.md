# ComponentLibrary 快速参考

> **状态**: 2026-03-01 架构重构完成  
> **提交**: 32770f9 - feat: 重构ComponentLibrary架构和增强插件功能

---

## ✅ 已完成工作

### 1. 修复15个Demo文件语法错误
- **问题**: 缩进混用、继承方式不一致、API不兼容
- **修复**: 
  - 统一使用tab缩进
  - `extends "path"` → `extends PackDemo`
  - `._ready()` → `super._ready()`
  - `rect_position` → `position`
  - `.format(x)` → `% x`
  - `connect("signal", Callable())` → `signal.connect()`
- **文件**: Foundation, Card, Puzzle, RPG, Roguelike, Strategy, UI, VFX, Action, Shooter, Racing, Builder, Platformer, Survival, Time

### 2. 补充缺失依赖
- **创建**: `ComponentLibrary/Dependencies/time_controller.gd`
- **功能**: 全局时间控制器（时间缩放、暂停、子弹时间）

### 3. 设计新架构
- **文档**: `ComponentLibrary/ARCHITECTURE.md`
- **分类**: Core（基础） / Modules（功能） / Systems（服务）
- **迁移计划**: 详细的文件迁移映射表

### 4. 开发增强版插件
- **文件**: `addons/component_library_share/plugin_enhanced.gd`
- **新功能**:
  - 🎨 Dock常驻面板 - 右下角实时访问
  - 🌳 树形浏览 - 分类清晰，可折叠
  - 🔍 搜索过滤 - 快速定位组件
  - 📊 信息面板 - 显示详情和操作
  - ⚡ 快速打开 - 双击打开脚本/Demo
  - 🔢 组件计数 - 每个Pack显示数量

### 5. 完整项目规划
- **文档**: `ComponentLibrary/PROJECT_PLAN.md`
- **内容**:
  - 项目现状分析
  - 6个阶段的实施路线图
  - 技术决策记录（ADR）
  - 开发规范和模板
  - 检查清单

---

## 🚀 启用增强插件

### 方法1：替换插件（推荐）
```bash
cd addons/component_library_share/
mv plugin.gd plugin_old.gd
mv plugin_enhanced.gd plugin.gd
```
然后在Godot编辑器中：Project → Reload Current Project

### 方法2：在plugin.cfg中修改
```ini
[plugin]
script="plugin_enhanced.gd"  # 改为增强版
```

### 验证
1. 打开Godot编辑器
2. 检查右下角是否有"ComponentLibrary" Dock面板
3. 面板应显示树形分类和搜索框
4. 选择组件应显示详细信息

---

## 📋 下一步行动

### 立即需要做的（P0）
1. ⚠️ **删除测试文件夹**
   ```bash
   rm -rf ComponentLibrary/Packs/111
   rm -rf ComponentLibrary/Packs/SamplePackage
   ```

2. ⚠️ **启用增强插件** - 按上述方法操作

3. ⚠️ **创建备份分支**
   ```bash
   git checkout -b backup-before-restructure
   git checkout main
   ```

### 本周完成（P0-P1）
1. 创建新目录结构
   ```bash
   mkdir -p ComponentLibrary/Core/{base,events,pools,time,utils}
   mkdir -p ComponentLibrary/Modules/{Combat,Movement,Input,Animation,Time,VFX,UI}
   mkdir -p ComponentLibrary/Modules/GameLogic/{Foundation,Card,RPG,Roguelike,Strategy,Puzzle}
   mkdir -p ComponentLibrary/Systems/{Camera,Audio,Save,Level,Replay,Score,Debug,Platform}
   ```

2. 迁移文件（参考ARCHITECTURE.md迁移映射表）

3. 更新插件扫描逻辑（在plugin.gd或plugin_enhanced.gd中）

4. 测试验证所有组件正常加载

### 本月完成（P1）
- 为每个模块编写README.md
- 改进Demo质量
- 补充缺失组件实现
- 创建快速开始指南

---

## 📖 文档索引

| 文档 | 用途 | 路径 |
|------|------|------|
| **ARCHITECTURE.md** | 详细架构设计 | `ComponentLibrary/ARCHITECTURE.md` |
| **PROJECT_PLAN.md** | 项目规划和路线图 | `ComponentLibrary/PROJECT_PLAN.md` |
| **QUICK_REFERENCE.md** | 快速参考（本文档） | `ComponentLibrary/QUICK_REFERENCE.md` |
| **README.md** | 项目说明 | `ComponentLibrary/README.md` |
| **CONTEXT.md** | 项目上下文 | `CONTEXT.md` |

---

## 🔧 常用命令

### 插件管理
```bash
# 重新加载插件
# Godot: Project → Reload Current Project

# 查看插件状态
# Godot: Project → Project Settings → Plugins

# 禁用/启用插件
# 在Plugins面板中勾选/取消勾选
```

### 组件开发
```bash
# 创建新组件
# 使用插件: ComponentLibrary → Create New Pack
# 或手动: cp template_component.gd Modules/YourModule/Components/

# 创建Demo场景
# File → New Scene → 选择Node作为根节点
# 添加脚本: extends PackDemo
```

### 测试
```bash
# 运行Demo
# 双击Pack名称，或在面板中点击"Open Demo"按钮

# 检查错误
# 打开Demo场景，点击F5运行
# 查看Output面板的错误信息
```

---

## 🐛 常见问题

### Q: 插件无法加载
**A**: 检查以下几点：
1. Project Settings → Plugins 中插件是否启用
2. plugin.cfg 文件是否正确
3. script路径是否正确（plugin.gd或plugin_enhanced.gd）
4. 重启编辑器试试

### Q: Demo运行报错 "Could not find class"
**A**: 可能原因：
1. 组件类没有正确注册
2. 组件文件缺少`class_name`声明
3. 插件未正确扫描组件目录
4. 解决：确保组件有`class_name`，重新加载插件

### Q: 找不到time_controller依赖
**A**: 已修复，文件位于：
`ComponentLibrary/Dependencies/time_controller.gd`
如果仍报错，检查plugin.gd中的路径配置

### Q: Demo缩进混乱
**A**: 已全部修复为tab缩进
如果新建Demo，使用以下设置：
Editor → Editor Settings → Text Editor → Indent → Type = Tabs

### Q: format()函数报错
**A**: Godot 4中语法变化：
- ❌ `"text %s".format(value)`
- ✅ `"text %s" % value`
- ✅ `"text %s %d" % [str, num]`

---

## 📞 获取帮助

### 资源
- **项目文档**: 查看ComponentLibrary/下的所有.md文件
- **Godot文档**: https://docs.godotengine.org/en/stable/
- **问题追踪**: 项目仓库Issues

### 联系
有问题时请提供：
1. Godot版本
2. 错误信息截图或日志
3. 复现步骤
4. 相关代码片段

---

**最后更新**: 2026-03-01  
**Git提交**: 32770f9
