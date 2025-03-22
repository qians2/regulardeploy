GLOBAL.setmetatable(env, {
    __index = function(t, k) return GLOBAL.rawget(GLOBAL, k) end
})
PrefabFiles = {"deployrange", "rctitle"}
Assets = {}
TUNING.RCLANG = GetModConfigData("language")
TUNING.RCROOT = MODROOT
if TheNet:GetServerGameMode() == "lavaarena" then return end
CONFIG = {}
local function cd(ti)
    local t = ti
    local last = -ti
    return function()
        local ct = GetTime()
        if (ct - t) > last then
            last = ct
            return true
        end
        return false
    end
end

local function RCMakeWidgetMovable(s, name, pos, data) -- 使UI可移动 
    -- 第一个参数为UI实体 第二个参数为 位置存档的名称 注意如果是一个UI的多个实体 记得不同名称
    -- 第三个参数为默认位置 要求为Vector3 或者为空
    -- 第四个参数为扩展属性 是一个table 或者 nil 描述了实体的对齐的问题
    s.onikirimovable = {}
    local m = s.onikirimovable
    m.nullfn = function() end
    m.name = name or "default"
    m.self = s
    m.downtime = 0
    m.whiletime = 0.4
    m.cd = cd(0.5)
    m.dpos = pos or Vector3(0, 0, 0)
    m.pos = pos or Vector3(0, 0, 0)
    m.ha = data and data.ha or 1
    m.va = data and data.va or 2

    m.x, m.y = TheSim:GetScreenSize()
    TheSim:GetPersistentString(m.name, function(load_success, str)
        if load_success then
            local fn = loadstring(str)
            if type(fn) == "function" then
                m.pos = fn()
                if not (type(m.pos) == "table" and m.pos.Get) then
                    m.pos = pos
                end
            end
        end
    end)
    s:SetPosition(m.pos:Get())
    m.OnControl = s.OnControl or m.nullfn
    s.OnControl = function(self, control, down)
        if self.focus and control == CONTROL_ACCEPT then
            if down then
                if not m.down then
                    m.down = true
                    m.downtime = 0
                end
            else
                if m.down then
                    m.down = false
                    m.OnClick(self)
                end
            end
        end
        return m.OnControl(self, control, down)
    end
    m.OnRawKey = s.OnRawKey or m.nullfn
    s.OnRawKey = function(self, key, down, ...)
        if s.focus and key == KEY_SPACE and not down and not m.cd() then
            s:SetPosition(m.dpos:Get())
            TheSim:SetPersistentString(m.name, string.format(
                                           "return Vector3(%d,%d,%d)",
                                           m.dpos:Get()), false)
        end
        return m.OnRawKey(self, key, down, ...)
    end

    m.OnClick = function(self)
        m:StopFollowMouse()
        if m.downtime > m.whiletime then
            local newpos = self:GetPosition()
            if TUNING.FLDEBUGCOMMAND then
                print(s, name, newpos:Get())
            end
            TheSim:SetPersistentString(m.name, string.format(
                                           "return Vector3(%f,%f,%f)",
                                           newpos:Get()), false)
        end
        if m.lastx and m.lasty and s.o_pos then
            s.o_pos = Vector3(m.lastx, m.lasty, 0)
        end
    end

    m.OnUpdate = s.OnUpdate or m.nullfn
    s.OnUpdate = function(self, dt)
        if m.down then if m.whiledown then m.whiledown(self) end end
        return m.OnUpdate(self, dt)
    end
    m.whiledown = function(self)
        m.downtime = m.downtime + 0.033
        if m.downtime > m.whiletime then m.FollowMouse(self) end
    end
    m.UpdatePosition = function(self, x, y)
        local sx, sy = s.parent.GetScale(s.parent):Get()
        local ox, oy = s.parent.GetWorldPosition(s.parent):Get()
        local nx = (x - ox) / sx
        if m.ha == 0 then
            x = x - m.x / 2
            nx = (x - ox) / sx
        elseif m.ha == 2 then
            x = x - m.x
            nx = (x - ox) / sx
        end
        local ny = (y - oy) / sy
        if m.va == 0 then
            y = y - m.y / 2
            ny = (y - oy) / sy
        elseif m.va == 1 then
            y = y - m.y
            ny = (y - oy) / sy
        end
        m.lastx = nx
        m.lasty = ny
        s.SetPosition(self, nx, ny, 0)
    end
    m.FollowMouse = function(self)
        if m.followhandler == nil then
            m.followhandler = TheInput:AddMoveHandler(function(x, y)
                m.UpdatePosition(self, x, y)
            end)
            local spos = TheInput:GetScreenPosition()
            m.UpdatePosition(self, spos.x, spos.y)
            -- self:SetPosition()
        end
    end

    m.StopFollowMouse = function(self)
        if m.followhandler ~= nil then
            m.followhandler:Remove()
            m.followhandler = nil
        end
    end
    s:StartUpdating()
end
Config = require("delpoyconfig")()
_G.RDConfig = Config
local ut = require("deployutil")
local function HighlightCenterDeploy()
    local center_x, center_z
    local x, _, z = TheInput:GetWorldPosition():Get()
    if Config.corners then
        center_x = math.floor(x / 2 + 0.5) * 2
        center_z = math.floor(z / 2 + 0.5) * 2
    else
        center_x = x
        center_z = z
    end
    if Config.lockitem then
        local inst = ConsoleWorldEntityUnderMouse()
        if inst then
            center_x, _, center_z = inst.Transform:GetWorldPosition()
        end
    end
    Config.center_x = center_x
    Config.center_z = center_z
    if not Config.guideline then
        Config.guideline = SpawnPrefab("deployrange")
    end
    if not Config.guideline:IsValid() then
        Config.guideline = SpawnPrefab("deployrange")
    end
    local scale = math.sqrt(Config.radius * 0.16)
    Config.guideline.Transform:SetPosition(center_x, 0, center_z)
    Config.guideline.Transform:SetScale(scale, scale, scale)
    Config.guideline:Show()
    if not Config.gridplacer then
        if PrefabExists("buildgridplacer") then
            Config.gridplacer = SpawnPrefab("buildgridplacer")
            Config.gridplacer.AnimState:PlayAnimation("on", true)
            Config.gridplacer.Transform:SetScale(1.7, 1.7, 1.7)
        else
            Config.gridplacer = SpawnPrefab("gridplacer")
        end
    end
    if not Config.gridplacer:IsValid() then
        if PrefabExists("buildgridplacer") then
            Config.gridplacer = SpawnPrefab("buildgridplacer")
            Config.gridplacer.AnimState:PlayAnimation("on", true)
            Config.gridplacer.Transform:SetScale(1.7, 1.7, 1.7)
        else
            Config.gridplacer = SpawnPrefab("gridplacer")
        end
    end
    Config.gridplacer:Show()
    Config.gridplacer.Transform:SetPosition(center_x, 0, center_z)
    Config.candeploy = true
end

local function IsWalkButtonDown()
    return ThePlayer.components.playercontroller:IsAnyOfControlsPressed(
               CONTROL_MOVE_UP, CONTROL_MOVE_DOWN, CONTROL_MOVE_LEFT,
               CONTROL_MOVE_RIGHT)
end

local function RCScreenPush(self)
    local cls = require "screens/rounddeployscreen"
    self.RCScreen = cls(self.owner)
    if ThePlayer.components.playercontroller.placer then
        local pc = ThePlayer.components.playercontroller
        self.RCScreen.min_spacing = pc.placer_recipe.min_spacing
    else
        self.RCScreen.min_spacing = nil
    end
    self:OpenScreenUnderPause(self.RCScreen)
    RCMakeWidgetMovable(self.RCScreen.inputwidget.root, "inputwidget")
    RCMakeWidgetMovable(self.RCScreen.keymapwidget.root, "keymapwidget")
    return true
end
local function RCScreenPop(self)
    self.RCScreen:Close()
    self.RCScreen = nil
end

local function show_position(self)
    local DPWidget = require("widgets/displayposition")
    self.rcdp = self:AddChild(DPWidget(ThePlayer))
    local w, h = TheSim:GetScreenSize()
    self.rcdp:SetPosition(200, h - 30)
    self.owner:DoTaskInTime(1, function()
        if not Config.coordinate then self:Hide() end
    end)
    self.owner:ListenForEvent("coordinateschange", function()
        if Config.coordinate then
            self.rcdp:Show()
        else
            self.rcdp:Hide()
        end
    end)
end
AddClassPostConstruct("widgets/controls", show_position)

AddClassPostConstruct("screens/playerhud", function(self)
    self.RCScreenOpen = RCScreenPush
    self.RCScreenClose = RCScreenPop
    self.inst:DoTaskInTime(0.1, function()
        local old_key = self.OnRawKey
        function self:OnRawKey(key, down, ...)
            if old_key(self, key, down, ...) then return true end
            if IsWalkButtonDown() then ut:ClearStationThread() end
            local key1, key2, key3 = Config:GetRwKey() -- 界面,摆放,预 览
            if key == key1 and down then
                if not self.RCScreen or self.RCScreen.inactive then
                    ThePlayer.HUD:RCScreenOpen()
                elseif not self.RCScreen.keymapwidget.focus then
                    ThePlayer.HUD:RCScreenClose()
                end
            elseif key == key2 and not down then
                -- ut:ClearStationThread()
                if TheInput:IsControlPressed(CONTROL_FORCE_TRADE) then
                    if Config.gridplacer and Config.gridplacer:IsValid() then
                        Config.gridplacer:Hide()
                    end
                    if Config.guideline and Config.guideline:IsValid() then
                        Config.guideline:Hide()
                    end
                    Config.candeploy = false
                elseif TheInput:IsControlPressed(CONTROL_FORCE_STACK) then
                    HighlightCenterDeploy()
                elseif Config.center_x and Config.center_z and Config.candeploy then
                    ut:StartAutoDeploy()
                end
            elseif key == key3 then
                if down and not self.rcplacer then
                    self.rcplacer = true
                    ut:ShowPlacer()
                elseif not down then
                    self.rcplacer = false
                    ut:HidePlacer()
                end
            end
        end
        local old_control = self.OnControl
        function self:OnControl(control, down, ...)
            if control == CONTROL_PRIMARY or control == CONTROL_SECONDARY then
                ut:ClearStationThread()
            end
            if Config.recordmode and
                TheInput:IsControlPressed(CONTROL_FORCE_INSPECT) and down then
                local entity = ConsoleWorldEntityUnderMouse()
                if control == CONTROL_ACCEPT then
                    if entity then
                        Config:SelectEntity(entity)
                        return false
                    end
                end
            end
            return old_control(self, control, down, ...)
        end
    end)
end)
