--[[
    ToyTools 诊断脚本
    用于快速诊断插件问题
]]

local function DiagnosePlugin()
    print("=== ToyTools 诊断报告 ===")
    
    -- 检查插件对象
    if ToyTools then
        print("✅ ToyTools 插件对象存在")
    else
        print("❌ ToyTools 插件对象不存在")
        return
    end
    
    -- 检查数据库
    if ToyTools.db then
        print("✅ 数据库已初始化")
        
        if ToyTools.db.profile then
            print("✅ 配置文件存在")
            print("  自动填充删除确认: " .. (ToyTools.db.profile.autoDelete and "开启" or "关闭"))
            print("  自动最小化追踪栏: " .. (ToyTools.db.profile.minimizeTracking and "开启" or "关闭"))
            print("  调试模式: " .. (ToyTools.db.profile.debugMode and "开启" or "关闭"))
        else
            print("❌ 配置文件不存在")
        end
    else
        print("❌ 数据库未初始化")
    end
    
    -- 检查UI元素
    if ObjectiveTrackerFrame then
        print("✅ 目标追踪栏存在")
    else
        print("❌ 目标追踪栏不存在")
    end
    
    -- 检查设置界面
    if ToyTools.settingsCategoryID then
        print("✅ 设置界面已注册")
    else
        print("❌ 设置界面未注册")
    end
    
    -- 检查命令
    local commands = {"toytools", "tt", "toytoolstest", "toytoolsmin", "toytoolsdebug"}
    for _, cmd in ipairs(commands) do
        if ToyTools:IsChatCommandRegistered(cmd) then
            print("✅ 命令 /" .. cmd .. " 已注册")
        else
            print("❌ 命令 /" .. cmd .. " 未注册")
        end
    end
    
    print("=== 诊断完成 ===")
end

-- 注册诊断命令
SLASH_TOYTOOLSDIAGNOSE1 = "/diagnose"
SlashCmdList["TOYTOOLSDIAGNOSE"] = DiagnosePlugin

-- 只在调试模式下显示加载信息
if ToyTools and ToyTools.db and ToyTools.db.profile and ToyTools.db.profile.debugMode then
    print("|cFF00FF00[ToyTools]|r 诊断脚本已加载，输入 /diagnose 运行诊断")
end 