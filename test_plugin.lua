--[[
    ToyTools 插件测试脚本
    用于验证插件功能是否正常
]]

-- 测试插件是否加载
local function TestPluginLoad()
    if not ToyTools then
        return false
    end
    
    if not ToyTools.db or not ToyTools.db.profile.debugMode then
        return ToyTools ~= nil
    end
    
    print("=== ToyTools 插件测试 ===")
    
    if not ToyTools then
        print("❌ ToyTools 插件对象未找到")
        return false
    end
    
    print("✅ ToyTools 插件对象已找到")
    
    if not ToyTools.db then
        print("❌ ToyTools 数据库未初始化")
        return false
    end
    
    print("✅ ToyTools 数据库已初始化")
    
    if not ToyTools.db.profile then
        print("❌ ToyTools 配置文件未找到")
        return false
    end
    
    print("✅ ToyTools 配置文件已找到")
    
    return true
end

-- 测试设置
local function TestSettings()
    if not ToyTools or not ToyTools.db or not ToyTools.db.profile.debugMode then
        return
    end
    
    print("\n=== 设置测试 ===")
    
    if ToyTools.db.profile.autoDelete then
        print("✅ 自动填充删除确认: 开启")
    else
        print("❌ 自动填充删除确认: 关闭")
    end
    
    if ToyTools.db.profile.minimizeTracking then
        print("✅ 自动最小化追踪栏: 开启")
    else
        print("❌ 自动最小化追踪栏: 关闭")
    end
    
    if ToyTools.db.profile.debugMode then
        print("✅ 调试模式: 开启")
    else
        print("❌ 调试模式: 关闭")
    end
end

-- 测试UI元素
local function TestUIElements()
    if not ToyTools or not ToyTools.db or not ToyTools.db.profile.debugMode then
        return
    end
    
    print("\n=== UI元素测试 ===")
    
    if ObjectiveTrackerFrame then
        print("✅ 目标追踪栏已找到")
        print("  状态: " .. (ObjectiveTrackerFrame:IsCollapsed() and "已最小化" or "已展开"))
        print("  可见: " .. (ObjectiveTrackerFrame:IsVisible() and "是" or "否"))
    else
        print("❌ 目标追踪栏未找到")
    end
    
    if Settings then
        print("✅ Settings框架可用")
    else
        print("❌ Settings框架不可用")
    end
    
    if ToyTools.settingsCategoryID then
        print("✅ 设置界面已注册，ID: " .. ToyTools.settingsCategoryID)
    else
        print("❌ 设置界面未注册")
    end
end

-- 测试命令
local function TestCommands()
    if not ToyTools or not ToyTools.db or not ToyTools.db.profile.debugMode then
        return
    end
    
    print("\n=== 命令测试 ===")
    
    local commands = {
        "toytools",
        "tt", 
        "toytoolstest",
        "toytoolsmin",
        "toytoolsdebug"
    }
    
    for _, cmd in ipairs(commands) do
        if ToyTools:IsChatCommandRegistered(cmd) then
            print("✅ 命令 /" .. cmd .. " 已注册")
        else
            print("❌ 命令 /" .. cmd .. " 未注册")
        end
    end
end

-- 运行所有测试
local function RunAllTests()
    if not ToyTools then
        print("|cFFFF0000[ToyTools]|r 插件未加载，无法运行测试")
        return
    end
    
    -- 强制开启调试模式进行测试
    local originalDebugMode = false
    if ToyTools.db and ToyTools.db.profile then
        originalDebugMode = ToyTools.db.profile.debugMode
        ToyTools.db.profile.debugMode = true
    end
    
    if not TestPluginLoad() then
        print("\n❌ 插件加载测试失败，停止测试")
        if ToyTools.db and ToyTools.db.profile then
            ToyTools.db.profile.debugMode = originalDebugMode
        end
        return
    end
    
    TestSettings()
    TestUIElements()
    TestCommands()
    
    print("\n=== 测试完成 ===")
    print("如果所有测试都通过，插件应该正常工作")
    print("如果有失败的测试，请检查相应的功能")
    
    -- 恢复原始调试模式
    if ToyTools.db and ToyTools.db.profile then
        ToyTools.db.profile.debugMode = originalDebugMode
    end
end

-- 注册测试命令
SLASH_TOYTOOLSTEST1 = "/testtoytools"
SlashCmdList["TOYTOOLSTEST"] = RunAllTests

-- 只在调试模式下显示加载信息
if ToyTools and ToyTools.db and ToyTools.db.profile and ToyTools.db.profile.debugMode then
    print("|cFF00FF00[ToyTools]|r 测试脚本已加载")
    print("输入 /testtoytools 运行完整测试")
end 