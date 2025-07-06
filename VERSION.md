# ToyTools v1.0

## 精简版本说明

### 已删除的文件
- 所有调试脚本 (*_debug.lua, *_test.lua)
- 所有修复脚本 (*_fix.lua)
- 简化版本文件 (ToyTools_simple.*)
- 版本切换脚本 (switch_version.*)
- 详细文档文件 (*.md，除README.md外)

### 保留的核心文件
- `ToyTools.toc` - 插件配置文件
- `ToyTools.lua` - 主插件文件
- `README.md` - 使用说明
- `Ace3-r1364-alpha/` - Ace3库文件

### 功能完整性
✅ 自动填充删除确认功能  
✅ 自动最小化目标追踪栏功能  
✅ 设置界面和聊天命令  
✅ 设置保存和加载  
✅ 调试模式切换  

### 代码优化
- 移除了所有调试输出（除非调试模式开启）
- 简化了函数逻辑
- 优化了代码结构
- 减少了不必要的检查

### 使用方式
1. 将整个文件夹复制到 `World of Warcraft/_retail_/Interface/AddOns/ToyTools/`
2. 启动游戏
3. 使用 `/toytools` 打开设置界面

---

**注意**: 此版本为精简版本，移除了所有调试和测试功能，专注于核心功能。 