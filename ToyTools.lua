--[[
    ToyTools - 玩具工具插件
    功能：自动填充删除确认、自动最小化目标追踪栏
]]

-- 创建插件对象
local ToyTools = LibStub("AceAddon-3.0"):NewAddon("ToyTools", "AceEvent-3.0", "AceConsole-3.0")

-- 将插件对象暴露为全局变量
_G.ToyTools = ToyTools

-- 默认设置
local defaults = {
    profile = {
        autoDelete = true,
        minimizeTracking = true,
        debugMode = false,
    }
}

-- 插件初始化
function ToyTools:OnInitialize()
    -- 初始化数据库
    self.db = LibStub("AceDB-3.0"):New("ToyToolsDB", defaults)
    
    if not self.db then
        print("|cFFFF0000[ToyTools]|r 数据库初始化失败")
        return
    end
    
    if self.db.profile.debugMode then
        print("|cFF00FF00[ToyTools]|r 开始初始化插件...")
        print("|cFF00FF00[ToyTools]|r 数据库初始化成功")
    end
    
    -- 注册聊天命令
    self:RegisterChatCommand("toytools", "OpenConfig")
    self:RegisterChatCommand("tt", "OpenConfig")
    self:RegisterChatCommand("toytoolstest", "RunTest")
    self:RegisterChatCommand("toytoolsmin", "MinimizeTrackingBar")
    self:RegisterChatCommand("toytoolsdebug", "ToggleDebug")
    
    if self.db.profile.debugMode then
        print("|cFF00FF00[ToyTools]|r 聊天命令注册完成")
    end
    
    -- 注册事件
    self:RegisterEvent("PLAYER_LOGIN")
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
    self:RegisterEvent("ADDON_LOADED")
    
    if self.db.profile.debugMode then
        print("|cFF00FF00[ToyTools]|r 事件注册完成")
    end
    
    -- 启用自动填充删除确认
    if self.db.profile.autoDelete then
        self:EnableAutoDelete()
    end
    
    if self.db.profile.debugMode then
        print("|cFF00FF00[ToyTools]|r 插件初始化完成")
        print("|cFF00FF00[ToyTools]|r 使用 /toytools 打开设置界面")
        print("|cFF00FF00[ToyTools]|r 使用 /testtoytools 运行测试")
    else
        print("|cFF00FF00[ToyTools]|r 插件已加载，使用 /toytools 打开设置")
    end
end

-- 启用自动填充删除确认
function ToyTools:EnableAutoDelete()
    if not self.db.profile.autoDelete then
        if self.db.profile.debugMode then
            print("|cFFFF0000[ToyTools]|r 自动填充删除确认功能已关闭")
        end
        return
    end
    
    if self.deleteHookInstalled then
        if self.db.profile.debugMode then
            print("|cFFFF0000[ToyTools]|r 自动填充删除确认功能已启用，跳过重复安装")
        end
        return
    end
    
    if self.db.profile.debugMode then
        print("|cFF00FF00[ToyTools]|r 开始安装自动填充删除确认钩子...")
    end
    
    self.deleteHookInstalled = true
    hooksecurefunc("StaticPopup_Show", function(popupType, ...)
        if popupType == "DELETE_GOOD_ITEM" or popupType == "DELETE_GOOD_ITEM_CONFIRM" then
            if self.db.profile.debugMode then
                print("|cFF00FF00[ToyTools]|r 检测到删除确认对话框: " .. popupType)
            end
            
            C_Timer.After(0.1, function()
                local dialog = StaticPopup_FindVisible(popupType)
                if dialog and dialog.editBox then
                    dialog.editBox:SetText("DELETE")
                    dialog.editBox:SetCursorPosition(0)
                    dialog.editBox:HighlightText()
                    
                    if self.db.profile.debugMode then
                        print("|cFF00FF00[ToyTools]|r 已自动填充 'DELETE'")
                    end
                else
                    if self.db.profile.debugMode then
                        print("|cFFFF0000[ToyTools]|r 未找到编辑框，无法填充")
                    end
                end
            end)
        end
    end)
    
    if self.db.profile.debugMode then
        print("|cFF00FF00[ToyTools]|r 自动填充删除确认功能已启用")
    end
end

-- 最小化目标追踪栏
function ToyTools:MinimizeTrackingBar()
    if not self.db.profile.minimizeTracking then
        if self.db.profile.debugMode then
            print("|cFFFF0000[ToyTools]|r 自动最小化功能已关闭")
        end
        return
    end
    
    if not ObjectiveTrackerFrame then
        if self.db.profile.debugMode then
            print("|cFFFF0000[ToyTools]|r 目标追踪栏不存在")
        end
        return
    end
    
    if not ObjectiveTrackerFrame:IsVisible() then
        if self.db.profile.debugMode then
            print("|cFFFF0000[ToyTools]|r 目标追踪栏不可见")
        end
        return
    end
    
    if ObjectiveTrackerFrame:IsCollapsed() then
        if self.db.profile.debugMode then
            print("|cFFFF0000[ToyTools]|r 目标追踪栏已经是最小化状态")
        end
        return
    end
    
    if self.db.profile.debugMode then
        print("|cFF00FF00[ToyTools]|r 开始最小化目标追踪栏...")
    end
    
    ObjectiveTrackerFrame:SetCollapsed(true)
    
    C_Timer.After(0.1, function()
        if ObjectiveTrackerFrame:IsCollapsed() then
            if self.db.profile.debugMode then
                print("|cFF00FF00[ToyTools]|r 目标追踪栏已成功最小化")
            end
        else
            if self.db.profile.debugMode then
                print("|cFFFF0000[ToyTools]|r 目标追踪栏最小化失败")
            end
        end
    end)
end

-- 玩家登录事件
function ToyTools:PLAYER_LOGIN()
    if self.db.profile.debugMode then
        print("|cFF00FF00[ToyTools]|r 收到 PLAYER_LOGIN 事件")
    end
    
    -- 多次尝试最小化
    local attempts = {0.5, 1.0, 1.5, 2.0, 2.5, 3.0, 4.0, 5.0}
    for _, delay in ipairs(attempts) do
        C_Timer.After(delay, function()
            if self.db.profile.debugMode then
                print("|cFF00FF00[ToyTools]|r 尝试最小化目标追踪栏 (延迟: " .. delay .. "秒)")
            end
            self:MinimizeTrackingBar()
        end)
    end
end

-- 进入世界事件
function ToyTools:PLAYER_ENTERING_WORLD()
    if self.db.profile.debugMode then
        print("|cFF00FF00[ToyTools]|r 收到 PLAYER_ENTERING_WORLD 事件")
    end
    
    local attempts = {0.5, 1.0, 1.5, 2.0}
    for _, delay in ipairs(attempts) do
        C_Timer.After(delay, function()
            if self.db.profile.debugMode then
                print("|cFF00FF00[ToyTools]|r PLAYER_ENTERING_WORLD 尝试最小化 (延迟: " .. delay .. "秒)")
            end
            self:MinimizeTrackingBar()
        end)
    end
end

-- 插件加载事件
function ToyTools:ADDON_LOADED(event, addonName)
    if self.db.profile.debugMode then
        print("|cFF00FF00[ToyTools]|r 插件加载: " .. addonName)
    end
    
    if addonName == "ElvUI" or addonName == "ElvUI_Config" then
        if self.db.profile.debugMode then
            print("|cFF00FF00[ToyTools]|r ElvUI 加载完成，准备最小化目标追踪栏")
        end
        C_Timer.After(1, function()
            self:MinimizeTrackingBar()
        end)
    end
end

-- 打开设置界面
function ToyTools:OpenConfig()
    if self.db.profile.debugMode then
        print("|cFF00FF00[ToyTools]|r 尝试打开设置界面...")
    end
    
    -- 使用Settings框架
    if Settings and Settings.OpenToCategory and self.settingsCategoryID then
        if self.db.profile.debugMode then
            print("|cFF00FF00[ToyTools]|r 使用Settings框架打开设置界面，分类ID: " .. self.settingsCategoryID)
        end
        
        if SettingsPanel and SettingsPanel:IsShown() then
            HideUIPanel(SettingsPanel)
            C_Timer.After(0.1, function()
                Settings.OpenToCategory(self.settingsCategoryID)
                if self.db.profile.debugMode then
                    print("|cFF00FF00[ToyTools]|r 已重新打开ToyTools设置界面")
                end
            end)
        else
            Settings.OpenToCategory(self.settingsCategoryID)
            if self.db.profile.debugMode then
                print("|cFF00FF00[ToyTools]|r 已打开ToyTools设置界面")
            end
        end
        return
    end
    
    -- 备用方案：显示设置信息
    if self.db.profile.debugMode then
        print("|cFF00FF00[ToyTools]|r 当前设置:")
        if self.db and self.db.profile then
            print("  自动填充删除确认: " .. (self.db.profile.autoDelete and "开启" or "关闭"))
            print("  自动最小化追踪栏: " .. (self.db.profile.minimizeTracking and "开启" or "关闭"))
            print("  调试模式: " .. (self.db.profile.debugMode and "开启" or "关闭"))
        else
            print("  设置未初始化")
        end
    end
end

-- 运行测试
function ToyTools:RunTest()
    if not self.db.profile.debugMode then
        print("|cFF00FF00[ToyTools]|r 请先开启调试模式查看详细测试信息")
        return
    end
    
    print("|cFF00FF00[ToyTools]|r 开始功能测试...")
    
    if self.db and self.db.profile then
        print("✓ 设置已初始化")
        print("  自动填充删除确认: " .. (self.db.profile.autoDelete and "开启" or "关闭"))
        print("  自动最小化追踪栏: " .. (self.db.profile.minimizeTracking and "开启" or "关闭"))
        print("  调试模式: " .. (self.db.profile.debugMode and "开启" or "关闭"))
    else
        print("✗ 设置未初始化")
    end
    
    if ObjectiveTrackerFrame then
        print("✓ 目标追踪栏已找到")
        print("  当前状态: " .. (ObjectiveTrackerFrame:IsCollapsed() and "已最小化" or "已展开"))
    else
        print("✗ 目标追踪栏未找到")
    end
    
    print("|cFF00FF00[ToyTools]|r 测试完成！")
end

-- 切换调试模式
function ToyTools:ToggleDebug()
    self.db.profile.debugMode = not self.db.profile.debugMode
    print("|cFF00FF00[ToyTools]|r 调试模式: " .. (self.db.profile.debugMode and "开启" or "关闭"))
end

-- 创建设置选项
local function CreateOptions()
    -- 检查是否已经注册过设置界面
    if ToyTools.settingsCategoryID then
        if ToyTools.db.profile.debugMode then
            print("|cFFFF0000[ToyTools]|r 设置界面已注册，跳过重复注册")
        end
        return
    end
    
    -- 检查是否使用新的Settings框架
    if Settings then
        -- 使用新的Settings框架
        local panel = CreateFrame("Frame")
        panel.name = "ToyTools"
        
        -- 创建标题
        local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
        title:SetPoint("TOPLEFT", 16, -16)
        title:SetText("ToyTools 设置")
        
        -- 自动填充删除确认选项
        local autoDeleteCheckbox = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
        autoDeleteCheckbox:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -20)
        autoDeleteCheckbox.Text:SetText("自动填充删除确认")
        autoDeleteCheckbox.tooltipText = "在删除物品时自动填充'DELETE'"
        autoDeleteCheckbox:SetChecked(ToyTools.db.profile.autoDelete)
        autoDeleteCheckbox:SetScript("OnClick", function(self)
            ToyTools.db.profile.autoDelete = self:GetChecked()
            if self:GetChecked() then
                ToyTools:EnableAutoDelete()
            end
        end)
        
        -- 自动最小化目标追踪栏选项
        local minimizeTrackingCheckbox = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
        minimizeTrackingCheckbox:SetPoint("TOPLEFT", autoDeleteCheckbox, "BOTTOMLEFT", 0, -10)
        minimizeTrackingCheckbox.Text:SetText("自动最小化目标追踪栏")
        minimizeTrackingCheckbox.tooltipText = "登录时自动最小化目标追踪栏"
        minimizeTrackingCheckbox:SetChecked(ToyTools.db.profile.minimizeTracking)
        minimizeTrackingCheckbox:SetScript("OnClick", function(self)
            ToyTools.db.profile.minimizeTracking = self:GetChecked()
        end)
        
        -- 调试模式选项
        local debugModeCheckbox = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
        debugModeCheckbox:SetPoint("TOPLEFT", minimizeTrackingCheckbox, "BOTTOMLEFT", 0, -10)
        debugModeCheckbox.Text:SetText("调试模式")
        debugModeCheckbox.tooltipText = "显示详细的操作信息"
        debugModeCheckbox:SetChecked(ToyTools.db.profile.debugMode)
        debugModeCheckbox:SetScript("OnClick", function(self)
            ToyTools.db.profile.debugMode = self:GetChecked()
        end)
        
        -- 运行测试按钮
        local testButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
        testButton:SetPoint("TOPLEFT", debugModeCheckbox, "BOTTOMLEFT", 0, -20)
        testButton:SetSize(120, 25)
        testButton:SetText("运行测试")
        testButton:SetScript("OnClick", function()
            ToyTools:RunTest()
        end)
        
        -- 手动最小化按钮
        local minimizeButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
        minimizeButton:SetPoint("LEFT", testButton, "RIGHT", 10, 0)
        minimizeButton:SetSize(120, 25)
        minimizeButton:SetText("手动最小化")
        minimizeButton:SetScript("OnClick", function()
            ToyTools:MinimizeTrackingBar()
        end)
        
        -- 注册到Settings框架
        if Settings.RegisterCanvasLayoutCategory then
            local category = Settings.RegisterCanvasLayoutCategory(panel, "ToyTools")
            Settings.RegisterAddOnCategory(category)
            ToyTools.settingsCategoryID = category:GetID()
            
            if ToyTools.db.profile.debugMode then
                print("|cFF00FF00[ToyTools]|r 已使用Settings框架注册设置界面")
                print("|cFF00FF00[ToyTools]|r 设置分类ID: " .. ToyTools.settingsCategoryID)
            end
            
            ToyTools.settingsPanel = panel
            ToyTools.settingsCategory = category
        else
            if ToyTools.db.profile.debugMode then
                print("|cFFFF0000[ToyTools]|r Settings.RegisterCanvasLayoutCategory不可用")
            end
        end
    else
        if ToyTools.db.profile.debugMode then
            print("|cFFFF0000[ToyTools]|r Settings框架不可用")
        end
    end
end

-- 延迟创建设置界面
C_Timer.After(2, CreateOptions) 