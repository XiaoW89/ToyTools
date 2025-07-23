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
        -- 自动售卖相关默认值
        autoSellEnable = false,
        autoSellIlvlMin = 0,
        autoSellIlvlMax = 999,
        autoSellLegendary = false,
        moveConfirmPopupToCursor = false, -- 新增：移动丢弃确认框到鼠标位置
        showInstanceDifficulty = true, -- 新增：显示副本难度
    }
}

-- 插件初始化
function ToyTools:OnInitialize()
    -- 初始化数据库
    self.db = LibStub("AceDB-3.0"):New("ToyToolsDB", defaults)
    self.pendingDifficultyAnnounce = nil -- 用于暂存需要显示的难度信息
    
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
    self:RegisterChatCommand("tttest", "PrintAutoSellItemCount")
    self:RegisterChatCommand("ttd", "TestDifficulty") -- 新增：手动测试难度提示
    
    if self.db.profile.debugMode then
        print("|cFF00FF00[ToyTools]|r 聊天命令注册完成")
    end
    
    -- 注册事件
    self:RegisterEvent("PLAYER_LOGIN")
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
    self:RegisterEvent("ADDON_LOADED")
    self:RegisterEvent("MERCHANT_SHOW")
    self:RegisterEvent("BAG_OPEN")
    self:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    self:RegisterEvent("LOADING_SCREEN_DISABLED") -- 监听加载界面消失
    
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
    self:StartPeriodicBagCache()
    self:CreateInstanceDifficultyAnnouncer()
end

-- 新增：手动测试难度提示功能
function ToyTools:TestDifficulty()
    if not self.db.profile.showInstanceDifficulty then
        print("|cFFFF0000[ToyTools]|r 副本难度提示功能已禁用。")
        return
    end
    if not self.difficultyFrame then
        self:CreateInstanceDifficultyAnnouncer()
    end
    local testText = "史诗难度 (测试)"
    print(string.format("|cFF00FF00[ToyTools]|r [调试] 手动触发难度提示: %s", testText))
    self.difficultyFrame.text:SetText(testText)
    self.difficultyFrame.animGroup:Stop() -- 先停止之前的动画
    self.difficultyFrame:SetAlpha(0) -- 重置透明度
    self.difficultyFrame.animGroup:Play()
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

-- 创建副本难度提示UI
function ToyTools:CreateInstanceDifficultyAnnouncer()
    if self.difficultyFrame then return end

    local frame = CreateFrame("Frame", "ToyToolsDifficultyFrame", UIParent)
    frame:SetSize(600, 120)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 250)
    frame:SetFrameStrata("HIGH")
    frame:SetAlpha(0)
    self.difficultyFrame = frame

    local text = frame:CreateFontString(nil, "OVERLAY")
    text:SetAllPoints(true)
    text:SetFont("Fonts\\FRIZQT__.TTF", 72, "THICKOUTLINE")
    text:SetTextColor(1, 0.82, 0, 1)
    text:SetJustifyH("CENTER")
    text:SetJustifyV("MIDDLE")
    frame.text = text

    local animGroup = frame:CreateAnimationGroup()
    frame.animGroup = animGroup

    local fadeIn = animGroup:CreateAnimation("Alpha")
    fadeIn:SetFromAlpha(0)
    fadeIn:SetToAlpha(1)
    fadeIn:SetDuration(0.3)
    fadeIn:SetOrder(1)

    local fadeOut = animGroup:CreateAnimation("Alpha")
    fadeOut:SetFromAlpha(1)
    fadeOut:SetToAlpha(0)
    fadeOut:SetStartDelay(4)
    fadeOut:SetOrder(1)
    
    animGroup:SetScript("OnFinished", function()
        frame:SetAlpha(0)
    end)
end


-- 区域变化事件处理
function ToyTools:ZONE_CHANGED_NEW_AREA()
    if not self.db.profile.showInstanceDifficulty then return end

    local name, instanceType, difficultyID, difficultyName = GetInstanceInfo()

    if (instanceType == "party" or instanceType == "raid") and difficultyName and difficultyName ~= "" then
        C_Timer.After(1.2, function()
            if not self.difficultyFrame then
                self:CreateInstanceDifficultyAnnouncer()
            end
            self.difficultyFrame.text:SetText(difficultyName)
            self.difficultyFrame.animGroup:Stop()
            self.difficultyFrame:SetAlpha(0)
            self.difficultyFrame.animGroup:Play()
        end)
    end
end

-- 加载界面消失事件处理
function ToyTools:LOADING_SCREEN_DISABLED()
    -- This event is no longer used for the difficulty announcer logic,
    -- but is kept for potential future use or debugging.
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
            print("  移动丢弃确认框到鼠标位置: " .. (self.db.profile.moveConfirmPopupToCursor and "开启" or "关闭"))
        else
            print("  设置未初始化")
        end
    end
end

-- 运行测试
function ToyTools:RunTest()
    self._diagnoseMode = true
    print("|cFF00FF00[ToyTools]|r 开始功能测试...")
    if self.db and self.db.profile then
        print("✓ 设置已初始化")
        print("  自动填充删除确认: " .. (self.db.profile.autoDelete and "开启" or "关闭"))
        print("  自动最小化追踪栏: " .. (self.db.profile.minimizeTracking and "开启" or "关闭"))
        print("  显示副本难度: " .. (self.db.profile.showInstanceDifficulty and "开启" or "关闭"))
        print("  调试模式: " .. (self.db.profile.debugMode and "开启" or "关闭"))
        print("  自动售卖: " .. (self.db.profile.autoSellEnable and "开启" or "关闭"))
        print("  售卖装等范围: " .. (self.db.profile.autoSellIlvlMin or 0) .. "-" .. (self.db.profile.autoSellIlvlMax or 999))
        print("  橙装自动售卖: " .. (self.db.profile.autoSellLegendary and "是" or "否"))
        print("  移动丢弃确认框到鼠标位置: " .. (self.db.profile.moveConfirmPopupToCursor and "开启" or "关闭"))
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
    self._diagnoseMode = false
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
        
        -- 缩进距离（一个TAB约40像素）
        local indent = 40

        -- 自动删除相关分组标题
        local autoDeleteTitle = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        autoDeleteTitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -20)
        autoDeleteTitle:SetText("自动删除相关设置：")
        -- 自动填充删除确认选项（缩进）
        local autoDeleteCheckbox = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
        autoDeleteCheckbox:SetPoint("TOPLEFT", autoDeleteTitle, "BOTTOMLEFT", indent, -10)
        autoDeleteCheckbox.Text:SetText("自动填充删除确认")
        autoDeleteCheckbox.tooltipText = "在删除物品时自动填充'DELETE'"
        autoDeleteCheckbox:SetChecked(ToyTools.db.profile.autoDelete)
        autoDeleteCheckbox:SetScript("OnClick", function(self)
            ToyTools.db.profile.autoDelete = self:GetChecked()
            if self:GetChecked() then
                ToyTools:EnableAutoDelete()
            end
        end)

        -- 移动确认框到鼠标位置选项（与自动填充删除确认缩进一致）
        local moveConfirmPopupCheckbox = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
        moveConfirmPopupCheckbox:SetPoint("TOPLEFT", autoDeleteCheckbox, "BOTTOMLEFT", 0, -10)
        moveConfirmPopupCheckbox.Text:SetText("移动丢弃确认框到鼠标位置")
        moveConfirmPopupCheckbox.tooltipText = "开启后，丢弃物品时确认框会自动移动到鼠标位置，方便点击“是”按钮"
        moveConfirmPopupCheckbox:SetChecked(ToyTools.db.profile.moveConfirmPopupToCursor)
        moveConfirmPopupCheckbox:SetScript("OnClick", function(self)
            ToyTools.db.profile.moveConfirmPopupToCursor = self:GetChecked()
        end)

        -- 其他设置分组标题
        local otherOptionsTitle = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        otherOptionsTitle:SetPoint("TOPLEFT", moveConfirmPopupCheckbox, "BOTTOMLEFT", -indent, -20)
        otherOptionsTitle:SetText("其他设置：")
        -- 自动最小化目标追踪栏选项（缩进）
        local minimizeTrackingCheckbox = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
        minimizeTrackingCheckbox:SetPoint("TOPLEFT", otherOptionsTitle, "BOTTOMLEFT", indent, -10)
        minimizeTrackingCheckbox.Text:SetText("自动最小化目标追踪栏")
        minimizeTrackingCheckbox.tooltipText = "登录时自动最小化目标追踪栏"
        minimizeTrackingCheckbox:SetChecked(ToyTools.db.profile.minimizeTracking)
        minimizeTrackingCheckbox:SetScript("OnClick", function(self)
            ToyTools.db.profile.minimizeTracking = self:GetChecked()
        end)

        -- 新增：显示副本难度选项
        local showDifficultyCheckbox = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
        showDifficultyCheckbox:SetPoint("TOPLEFT", minimizeTrackingCheckbox, "BOTTOMLEFT", 0, -10)
        showDifficultyCheckbox.Text:SetText("显示副本难度提示")
        showDifficultyCheckbox.tooltipText = "进入副本时在屏幕中央显示当前副本难度"
        showDifficultyCheckbox:SetChecked(ToyTools.db.profile.showInstanceDifficulty)
        showDifficultyCheckbox:SetScript("OnClick", function(self)
            ToyTools.db.profile.showInstanceDifficulty = self:GetChecked()
        end)

        -- 调试模式选项（缩进）
        local debugModeCheckbox = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
        debugModeCheckbox:SetPoint("TOPLEFT", showDifficultyCheckbox, "BOTTOMLEFT", 0, -10)
        debugModeCheckbox:SetPoint("LEFT", showDifficultyCheckbox, "LEFT", 0, 0)
        debugModeCheckbox.Text:SetText("调试模式")
        debugModeCheckbox.tooltipText = "显示详细的操作信息"
        debugModeCheckbox:SetChecked(ToyTools.db.profile.debugMode)
        debugModeCheckbox:SetScript("OnClick", function(self)
            ToyTools.db.profile.debugMode = self:GetChecked()
        end)

        -- 自动售卖功能分组标题（无缩进）
        local autoSellTitle = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        autoSellTitle:SetPoint("TOPLEFT", debugModeCheckbox, "BOTTOMLEFT", -indent, -20)
        autoSellTitle:SetText("自动售卖相关设置：")
        -- 自动售卖功能勾选框（缩进）
        local autoSellCheckbox = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
        autoSellCheckbox:SetPoint("TOPLEFT", autoSellTitle, "BOTTOMLEFT", indent, -10)
        autoSellCheckbox.Text:SetText("启用自动售卖灰色和指定装等装备")
        autoSellCheckbox.tooltipText = "开启后，打开商人界面自动售卖灰色物品和指定装等范围的装备"
        autoSellCheckbox:SetChecked(ToyTools.db.profile.autoSellEnable)
        autoSellCheckbox:SetScript("OnClick", function(self)
            ToyTools.db.profile.autoSellEnable = self:GetChecked()
        end)
        -- 橙装自动售卖勾选框（与autoSellCheckbox左对齐，移动到最低装等上方）
        local legendaryCheckbox = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
        legendaryCheckbox:SetPoint("TOPLEFT", autoSellCheckbox, "BOTTOMLEFT", 0, -10)
        legendaryCheckbox.Text:SetText("橙装自动售卖")
        legendaryCheckbox.tooltipText = "选中后，橙色品质装备也会自动售卖"
        legendaryCheckbox:SetChecked(ToyTools.db.profile.autoSellLegendary)
        legendaryCheckbox:SetScript("OnClick", function(self)
            ToyTools.db.profile.autoSellLegendary = self:GetChecked()
        end)

        -- 装等范围输入框（最低，缩进，与autoSellCheckbox左对齐）
        local ilvlMinLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        ilvlMinLabel:SetPoint("TOPLEFT", legendaryCheckbox, "BOTTOMLEFT", 0, -10)
        ilvlMinLabel:SetText("最低装等：")

        local ilvlMinEditBox = CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
        ilvlMinEditBox:SetSize(90, 25)
        ilvlMinEditBox:SetPoint("LEFT", ilvlMinLabel, "RIGHT", 5, 0)
        ilvlMinEditBox:SetAutoFocus(false)
        ilvlMinEditBox:SetNumeric(true)
        ilvlMinEditBox:SetNumber(ToyTools.db.profile.autoSellIlvlMin or 0)
        ilvlMinEditBox:SetScript("OnEnterPressed", function(self)
            local val = tonumber(self:GetText()) or 0
            ToyTools.db.profile.autoSellIlvlMin = val
            self:ClearFocus()
        end)
        ilvlMinEditBox:SetScript("OnEditFocusLost", function(self)
            local val = tonumber(self:GetText()) or 0
            ToyTools.db.profile.autoSellIlvlMin = val
        end)
        ilvlMinEditBox:SetScript("OnShow", function(self)
            self:SetNumber(ToyTools.db.profile.autoSellIlvlMin or 0)
            self:ClearFocus()
            self:SetCursorPosition(0)
            self:SetCursorPosition(-1)
        end)
        C_Timer.After(0, function()
            if ilvlMinEditBox and ilvlMinEditBox:IsVisible() then
                ilvlMinEditBox:SetNumber(ToyTools.db.profile.autoSellIlvlMin or 0)
                ilvlMinEditBox:ClearFocus()
                ilvlMinEditBox:SetCursorPosition(0)
                ilvlMinEditBox:SetCursorPosition(-1)
            end
        end)

        -- 装等范围输入框（最高，紧跟最低装等右侧）
        local ilvlMaxLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        ilvlMaxLabel:SetPoint("LEFT", ilvlMinEditBox, "RIGHT", 20, 0)
        ilvlMaxLabel:SetText("最高装等：")

        local ilvlMaxEditBox = CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
        ilvlMaxEditBox:SetSize(90, 25)
        ilvlMaxEditBox:SetPoint("LEFT", ilvlMaxLabel, "RIGHT", 5, 0)
        ilvlMaxEditBox:SetAutoFocus(false)
        ilvlMaxEditBox:SetNumeric(true)
        ilvlMaxEditBox:SetNumber(ToyTools.db.profile.autoSellIlvlMax or 999)
        ilvlMaxEditBox:SetScript("OnEnterPressed", function(self)
            local val = tonumber(self:GetText()) or 999
            ToyTools.db.profile.autoSellIlvlMax = val
            self:ClearFocus()
        end)
        ilvlMaxEditBox:SetScript("OnEditFocusLost", function(self)
            local val = tonumber(self:GetText()) or 999
            ToyTools.db.profile.autoSellIlvlMax = val
        end)
        ilvlMaxEditBox:SetScript("OnShow", function(self)
            self:SetNumber(ToyTools.db.profile.autoSellIlvlMax or 999)
            self:ClearFocus()
            self:SetCursorPosition(0)
            self:SetCursorPosition(-1)
        end)
        C_Timer.After(0, function()
            if ilvlMaxEditBox and ilvlMaxEditBox:IsVisible() then
                ilvlMaxEditBox:SetNumber(ToyTools.db.profile.autoSellIlvlMax or 999)
                ilvlMaxEditBox:ClearFocus()
                ilvlMaxEditBox:SetCursorPosition(0)
                ilvlMaxEditBox:SetCursorPosition(-1)
            end
        end)
        
        -- 运行测试按钮
        local testButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
        testButton:SetPoint("TOPLEFT", ilvlMaxEditBox, "BOTTOMLEFT", 0, -20)
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

-- 自动售卖相关优化：基于TinyInspect思路，监听GET_ITEM_INFO_RECEIVED事件，提升物品信息获取效率
ToyTools.pendingSellItems = {}
ToyTools._itemInfoEventRegistered = false
ToyTools._autoSellTimeoutTimer = nil

function ToyTools:StartPeriodicBagCache()
    if self._periodicBagCacheTimer then
        self._periodicBagCacheTimer:Cancel()
    end
    local function cacheFunc()
        for bag = 0, 4 do
            local numSlots = C_Container.GetContainerNumSlots(bag)
            for slot = 1, numSlots do
                local itemLink = C_Container.GetContainerItemLink(bag, slot)
                if type(itemLink) == "string" and string.find(itemLink, "item:") then
                    GetItemInfo(itemLink)
                end
            end
        end
        -- 每5秒再次缓存
        self._periodicBagCacheTimer = C_Timer.NewTimer(5, cacheFunc)
    end
    cacheFunc()
end

function ToyTools:MERCHANT_SHOW(event, ...)
    self.pendingSellItems = {}
    self._itemInfoEventRegistered = false
    if self._autoSellTimeoutTimer then
        self._autoSellTimeoutTimer:Cancel()
        self._autoSellTimeoutTimer = nil
    end
    self:PreCacheAllBagItems()
    self:CheckAndSellAll()
end

-- 主动批量缓存所有背包物品信息
function ToyTools:PreCacheAllBagItems()
    for bag = 0, 4 do
        local numSlots = C_Container.GetContainerNumSlots(bag)
        for slot = 1, numSlots do
            local itemLink = C_Container.GetContainerItemLink(bag, slot)
            if type(itemLink) == "string" and string.find(itemLink, "item:") then
                GetItemInfo(itemLink)
            end
        end
    end
end

function ToyTools:CheckAndSellAll()
    if not self.db.profile.autoSellEnable then return end
    local hasUncached = false
    self.pendingSellItems = {}
    for bag = 0, 4 do
        local numSlots = C_Container.GetContainerNumSlots(bag)
        for slot = 1, numSlots do
            local itemLink = C_Container.GetContainerItemLink(bag, slot)
            if type(itemLink) == "string" and string.find(itemLink, "item:") then
                local itemName = GetItemInfo(itemLink)
                if not itemName then
                    hasUncached = true
                    local itemID = tonumber(itemLink:match("item:(%d+)") or "0")
                    if itemID and itemID > 0 then
                        self.pendingSellItems[itemID] = true
                    end
                end
            end
        end
    end
    if hasUncached then
        if not self._itemInfoEventRegistered then
            self:RegisterEvent("GET_ITEM_INFO_RECEIVED")
            self._itemInfoEventRegistered = true
        end
        -- 超时保护，5秒后强制执行售卖
        if self._autoSellTimeoutTimer then
            self._autoSellTimeoutTimer:Cancel()
        end
        self._autoSellTimeoutTimer = C_Timer.NewTimer(5, function()
            if self._itemInfoEventRegistered then
                self:UnregisterEvent("GET_ITEM_INFO_RECEIVED")
                self._itemInfoEventRegistered = false
            end
            self:DoFinalAutoSell()
        end)
        if self.db.profile.debugMode then
            print("[ToyTools] 检测到有未缓存物品，等待物品信息到齐后自动售卖（最多等待5秒）...")
        end
        return
    end
    -- 数据全部缓存，打印提示（无论是否有可售卖物品）
    print("|cFF00FF00[ToyTools]|r 背包物品信息已全部缓存，准备自动售卖。")
    if self._itemInfoEventRegistered then
        self:UnregisterEvent("GET_ITEM_INFO_RECEIVED")
        self._itemInfoEventRegistered = false
    end
    if self._autoSellTimeoutTimer then
        self._autoSellTimeoutTimer:Cancel()
        self._autoSellTimeoutTimer = nil
    end
    self:DoFinalAutoSell()
end

function ToyTools:GET_ITEM_INFO_RECEIVED(event, itemID, success)
    itemID = tonumber(itemID)
    if self.pendingSellItems and self.pendingSellItems[itemID] then
        self.pendingSellItems[itemID] = nil
    end
    -- 检查是否所有待处理物品都已缓存
    local stillPending = false
    for _, v in pairs(self.pendingSellItems) do
        if v then
            stillPending = true
            break
        end
    end
    if not stillPending then
        if self._itemInfoEventRegistered then
            self:UnregisterEvent("GET_ITEM_INFO_RECEIVED")
            self._itemInfoEventRegistered = false
        end
        if self._autoSellTimeoutTimer then
            self._autoSellTimeoutTimer:Cancel()
            self._autoSellTimeoutTimer = nil
        end
        self:DoFinalAutoSell()
    end
end

function ToyTools:DoFinalAutoSell()
    if self.db.profile.debugMode then
        print("[ToyTools] 所有物品数据已缓存，开始一次性自动售卖...")
    end
    local toSell = {}
    local ilvlMin = tonumber(self.db.profile.autoSellIlvlMin) or 0
    local ilvlMax = tonumber(self.db.profile.autoSellIlvlMax) or 999
    local sellLegendary = self.db.profile.autoSellLegendary
    for bag = 0, 4 do
        local numSlots = C_Container.GetContainerNumSlots(bag)
        for slot = 1, numSlots do
            local itemLink = C_Container.GetContainerItemLink(bag, slot)
            if type(itemLink) == "string" and string.find(itemLink, "item:") then
                local itemName, _, itemQuality, itemLevel, _, itemType, itemSubType, _, _, itemIcon, _, classID, subclassID = GetItemInfo(itemLink)
                local realIlvl = GetDetailedItemLevelInfo(itemLink) or itemLevel or 0
                -- 灰色物品
                if itemQuality == 0 then
                    table.insert(toSell, {bag=bag, slot=slot, name=(itemName or "未知物品"), link=itemLink})
                -- 装备
                elseif classID == 2 or classID == 4 then
                    if realIlvl >= ilvlMin and realIlvl <= ilvlMax then
                        if itemQuality == 5 then -- 橙装
                            if sellLegendary then
                                table.insert(toSell, {bag=bag, slot=slot, name=(itemName or "未知橙装"), link=itemLink})
                            end
                        else
                            table.insert(toSell, {bag=bag, slot=slot, name=(itemName or "未知装备"), link=itemLink})
                        end
                    end
                end
            end
        end
    end

    if #toSell == 0 then
        print("[ToyTools] 本次未找到可售卖物品。")
        return
    end

    local soldLines = {}
    local function sellNext(index)
        if index > #toSell then
            print("|cFF00FF00[ToyTools]|r 已自动售卖以下物品：")
            for _, line in ipairs(soldLines) do
                print(line)
            end
            return
        end
        local item = toSell[index]
        C_Container.UseContainerItem(item.bag, item.slot)
        table.insert(soldLines, string.format("|cFF00FF00[ToyTools]|r %s", item.link or item.name))
        C_Timer.After(0.15, function() sellNext(index + 1) end)
    end

    sellNext(1)
end

function ToyTools:AutoSellRetry()
    if self._autoSellRetried then return end
    self._autoSellRetried = true
    if self.db.profile.debugMode then print("[ToyTools] 自动售卖重试开始...") end
    local soldItems = {}
    local ilvlMin = tonumber(self.db.profile.autoSellIlvlMin) or 0
    local ilvlMax = tonumber(self.db.profile.autoSellIlvlMax) or 999
    local sellLegendary = self.db.profile.autoSellLegendary
    for bag = 0, 4 do
        local numSlots = C_Container.GetContainerNumSlots(bag)
        for slot = 1, numSlots do
            local itemLink = C_Container.GetContainerItemLink(bag, slot)
            if type(itemLink) == "string" and string.find(itemLink, "item:") then
                local itemName, _, itemQuality, itemLevel, _, itemType, itemSubType, _, _, itemIcon, _, classID, subclassID = GetItemInfo(itemLink)
                if itemName then
                    local realIlvl = GetDetailedItemLevelInfo(itemLink) or itemLevel or 0
                    -- 灰色物品
                    if itemQuality == 0 then
                        C_Container.UseContainerItem(bag, slot)
                        table.insert(soldItems, (itemName or "未知物品"))
                    -- 装备
                    elseif classID == 2 or classID == 4 then
                        if realIlvl >= ilvlMin and realIlvl <= ilvlMax then
                            if itemQuality == 5 then -- 橙装
                                if sellLegendary then
                                    C_Container.UseContainerItem(bag, slot)
                                    table.insert(soldItems, (itemName or "未知橙装"))
                                end
                            else
                                C_Container.UseContainerItem(bag, slot)
                                table.insert(soldItems, (itemName or "未知装备"))
                            end
                        end
                    end
                end
            end
        end
    end
    if #soldItems > 0 and (self.db.profile.debugMode or self._diagnoseMode) then
        print("|cFF00FF00[ToyTools]|r 已自动售卖(重试)：" .. table.concat(soldItems, "，"))
    elseif self.db.profile.debugMode then
        print("[ToyTools] 本次未找到可售卖物品(重试)。")
    end
    self._autoSellRetried = false
end 

-- 新增：监听背包打开事件，打印满足自动售卖条件的装备件数
function ToyTools:BAG_OPEN()
    local count = 0
    local ilvlMin = tonumber(self.db.profile.autoSellIlvlMin) or 0
    local ilvlMax = tonumber(self.db.profile.autoSellIlvlMax) or 999
    local sellLegendary = self.db.profile.autoSellLegendary
    for bag = 0, 4 do
        local numSlots = C_Container.GetContainerNumSlots(bag)
        for slot = 1, numSlots do
            local itemLink = C_Container.GetContainerItemLink(bag, slot)
            if type(itemLink) == "string" and string.find(itemLink, "item:") then
                local itemName, _, itemQuality, itemLevel, _, _, _, _, _, _, _, classID = GetItemInfo(itemLink)
                local realIlvl = GetDetailedItemLevelInfo(itemLink) or itemLevel or 0
                if itemQuality == 0 then
                    count = count + 1
                elseif classID == 2 or classID == 4 then
                    if realIlvl >= ilvlMin and realIlvl <= ilvlMax then
                        if itemQuality == 5 then
                            if sellLegendary then
                                count = count + 1
                            end
                        else
                            count = count + 1
                        end
                    end
                end
            end
        end
    end
    print("|cFF00FF00[ToyTools]|r 当前背包中满足自动售卖条件的装备件数：" .. count)
end 

function ToyTools:PrintAutoSellItemCount()
    local count = 0
    local ilvlMin = tonumber(self.db.profile.autoSellIlvlMin) or 0
    local ilvlMax = tonumber(self.db.profile.autoSellIlvlMax) or 999
    local sellLegendary = self.db.profile.autoSellLegendary
    local detailLines = {}
    for bag = 0, 4 do
        local numSlots = C_Container.GetContainerNumSlots(bag)
        for slot = 1, numSlots do
            local itemLink = C_Container.GetContainerItemLink(bag, slot)
            if type(itemLink) == "string" and string.find(itemLink, "item:") then
                local itemName, _, itemQuality, itemLevel, _, _, _, _, _, _, _, classID = GetItemInfo(itemLink)
                local realIlvl = GetDetailedItemLevelInfo(itemLink) or itemLevel or 0
                local match = false
                local reason = ""
                if itemQuality == 0 then
                    match = true
                    reason = "灰色物品"
                elseif classID == 2 or classID == 4 then
                    if realIlvl >= ilvlMin and realIlvl <= ilvlMax then
                        if itemQuality == 5 then
                            if sellLegendary then
                                match = true
                                reason = "橙装"
                            end
                        else
                            match = true
                            reason = "装备"
                        end
                    end
                end
                if match then
                    count = count + 1
                    table.insert(detailLines, string.format("[%d包%d格] %s (品质:%d 装等:%d) - %s", bag, slot, itemName or "未知", itemQuality or -1, realIlvl or 0, reason))
                end
            end
        end
    end
    print("|cFF00FF00[ToyTools]|r 当前背包中满足自动售卖条件的装备件数：" .. count)
    for _, line in ipairs(detailLines) do
        print("|cFF00FF00[ToyTools]|r " .. line)
    end
end 

-- 新增：移动丢弃确认框到鼠标位置
local function MoveDeletePopupToCursor(which)
    if not ToyTools.db.profile.moveConfirmPopupToCursor then return end
    C_Timer.After(0.1, function()
        local frame = StaticPopup_FindVisible(which)
        if frame then
            local x, y = GetCursorPosition()
            local scale = UIParent:GetEffectiveScale()
            frame:ClearAllPoints()
            frame:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x/scale, y/scale)
        end
    end)
end

hooksecurefunc("StaticPopup_Show", function(which, ...)
    if which == "DELETE_ITEM" or which == "DELETE_GOOD_ITEM" then
        MoveDeletePopupToCursor(which)
    end
end)