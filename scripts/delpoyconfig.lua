---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by Administrator.
--- DateTime: 2021/7/23 17:13
---
local Steps = {
    0.5, 0.8, 1, 1.2, 1.125, 1.44, 1.5, 1.8, 2, 2.25, 2.4, 2.5, 2.8125, 2.88, 3,
    3.6, 4, 4.5, 5, 5.625, 6, 7.2, 7.5, 8, 9, 10, 11.25, 12, 15, 18, 20, 22.5,
    24, 30, 36, 40, 45, 60, 72, 90, 120, 180, 360
}
local parm = {
    "step", "radius", "deploynum", "space", "spin", "range", "interval",
    "shape", "custom", "corners", "lockitem", "crowded", "coordinate", "layer",
    "direction", "order","scheme"
}
local userparmPATH = (TUNING.RCROOT or '') .. "scripts/userparm.json"
local SHAPEPATH = (TUNING.RCROOT or '') .. "scripts/specialshape.json"
local relationaltable = require('relationaltable')

local function Rotate(x, y, radin)
    return x * math.cos(radin) - y * math.sin(radin),
           x * math.sin(radin) + y * math.cos(radin)
end
local function PointToPointDistance(x1, x2, y1, y2)
    return math.sqrt((x1 - x2) ^ 2 + (y1 - y2) ^ 2)
end
local function calNumber(self)
    local a = self.interval
    local oldstep = math.deg(math.acos((2 * self.radius ^ 2 - a ^ 2) /
                                           (2 * self.radius ^ 2)))
    if self.crowded then
        self.step = oldstep
        self.deploynum = math.floor(self.range / oldstep)
    else
        local flags = true
        for k, v in ipairs(Steps) do
            if oldstep <= v then
                self.step = v
                self.deploynum = math.floor(self.range / v)
                flags = false
                break
            end
        end
        if flags then
            self.step = oldstep
            self.deploynum = math.floor(self.range / oldstep)
        end
    end
    if self.deploynum < 1 then self.deploynum = 1 end
end

local function write(path,str)
    local fp = io.open(path,"w")
    if  fp then
        fp:write(str)
        fp:close()
    end
end
local function read(path)
    local fp = io.open(path, 'r')
    local str = "{}"
    if  fp then
        str = fp:read("*a")
        fp:close()
    end
    return str
end
local DeployCalc = Class(function(self, inst)
    self.inst = inst
    self.center_x = 0
    self.center_z = 0
    -- 参数
    self.step = 8 -- 圆心角
    self.radius = 14.8 -- 半径
    self.deploynum = 45 -- 部署数量
    self.space = 0.5 -- 层间额外间隔
    self.spin = 0 -- 旋转角度
    self.range = 360 -- 部署的范围
    self.interval = 2 -- 间隔
    -- 形状
    self.shape = "circle" -- 形状
    -- 功能
    self.custom = false -- 自定义半径和数量
    self.corners = true -- 边角中心
    self.lockitem = false -- 锁定物品
    self.crowded = false -- 紧密模式
    self.coordinate = true -- 显示坐标
    self.layer = false -- 满层
    self.recordmode = false --记录模式

    self.direction = true -- 方向
    self.order = true -- 顺序
    self.key_screen = 106
    self.key_deploy = 110
    self.key_placer = 112
    self.guideline = nil -- 范围
    self.gridplacer = nil -- 圆心
    self.scheme = nil -- 自定义图案
    self.userscheme = {}
    self.userparm = {{
        delblock = true,
        name = "默认",
        data = {
            radius = 14.8,
            deploynum = 45,
            interval = 2,
            spin = 0,
            range = 360,
            space = 0.5
        }
    },
    {
        name = "五锅",
        data = {
            spin = 0,
            deploynum = 5,
            space = 0.5,
            interval = 3.2,
            range = 360,
            radius = 2.73
        }
    }}
    self.ents = {}
    self:Init()
end)

function DeployCalc:Init()
    TheSim:GetPersistentString("rounddeployconfig", function(load_success, str)
        if load_success then
            local r, data = pcall(json.decode, str)
            if r then
                if type(data.key_screen) == "number" then
                    self.key_screen = data.key_screen
                end
                if type(data.key_deploy) == "number" then
                    self.key_deploy = data.key_deploy
                end
                if type(data.key_placer) == "number" then
                    self.key_placer = data.key_placer
                end
            end
            for _, v in ipairs(parm) do
                if data[v] ~= nil then self[v] = data[v] end
            end
        end
    end)
    TheSim:GetPersistentString("rounddeployuserdata", function(load_success, str)
        if load_success then
            local r, data = pcall(json.decode, str)
            if r then
                self.userscheme = data.userscheme
                self.userparm = data.userparm
            end
        end
    end)
end

function DeployCalc:Save()
    local tb = {}
    for k, v in ipairs(parm) do if self[v] ~= nil then tb[v] = self[v] end end
    tb.key_screen = self.key_screen
    tb.key_deploy = self.key_deploy
    tb.key_placer = self.key_placer
    local r, j = pcall(json.encode, tb)
    if r then TheSim:SetPersistentString("rounddeployconfig", j, true) end
    local res, js = pcall(json.encode, {userscheme=self.userscheme,userparm=self.userparm})
    if res then TheSim:SetPersistentString("rounddeployuserdata", js, true) end
end
function DeployCalc:SetR(value)
    self.radius = value
    if not self.custom then calNumber(self) end
end

function DeployCalc:SetN(value)
    value = math.floor(value)
    self.step = self.range / value
    self.deploynum = value
    if not self.custom then
        local a = self.interval
        local A = self.step
        local cos = math.cos(math.rad(90 - A / 2))
        local radius =
            math.abs(cos) > 0.001 and a / (2 * cos) or self.interval / 2
        self.radius = value ~= 1 and math.ceil(radius * 100 + 1) / 100 or
                          self.interval / 2
        --[[这里可能会出现cos90°然后除零的情况，不过编译器中精度问题cos90°
            并不等于于零,在计算半径时也会出现偏差,当数量只有一个的时候种在圆心就好了]] --
    end
end

function DeployCalc:SetI(value)
    self.interval = value
    if not self.custom and value < 2 * self.radius then calNumber(self) end
end

function DeployCalc:SetS(value)
    value = math.fmod(value, 360)
    if value == -0 then value = 0 end
    self.spin = value
end

function DeployCalc:SetA(value)
    value = math.fmod(value, 360)
    if value == 0 then value = 360 end
    self.range = value
    if not self.custom then calNumber(self) end
end

function DeployCalc:SetL(value) self.space = value end

function DeployCalc:SetDefault()
    self.step = 8 -- 圆心角
    self.radius = 14.8 -- 半径
    self.deploynum = 45 -- 部署数量
    self.space = 0.5 -- 层间额外间隔
    self.spin = 0 -- 旋转角度
    self.range = 360 -- 部署的范围
    self.interval = 2 -- 间隔
end

function DeployCalc:calStep(radius, inv)
    if radius == inv / 2 then
        return 360
    elseif radius < inv / 2 then
        return 180
    end
    local oldstep = math.deg(math.acos((2 * radius ^ 2 - inv ^ 2) /
                                           (2 * radius ^ 2)))
    if self.crowded then
        return oldstep
    else
        for k, v in pairs(Steps) do if oldstep <= v then return v end end
        return oldstep
    end
end

function DeployCalc:GetCirclePosition()
    local DeployPosition = {}
    local step = self.step
    local startAngle = self.spin
    local endAngle = self.direction and self.spin + self.range or self.spin -
                         self.range
    local radiuslist = {self.radius}
    if self.layer and not self.custom then
        radiuslist = {}
        for i = self.radius, self.interval / 2, -(self.interval + self.space) do
            table.insert(radiuslist, i)
        end
        if self.order then radiuslist = table.reverse(radiuslist) end
    end
    local x, z
    local playercontroller = ThePlayer.components.playercontroller
    local skin = playercontroller.placer_recipe_skin
    local theta = startAngle * DEGREES
    for _, radius in ipairs(radiuslist) do
        if  self.custom then
            step = 360 / self.deploynum
            local i = 0
            for Angle = startAngle, endAngle, step do
                theta = Angle * DEGREES
                x = math.cos(theta) * radius
                z = math.sin(theta) * radius
                table.insert(DeployPosition,{x = x + self.center_x,z =  z + self.center_z, rot = step * i,skin = skin})
                i = i + 1
            end
        else
            local new_step = self:calStep(radius, self.interval)
            step = self.direction and new_step or -new_step
            local i = 0
            for Angle = startAngle, endAngle, step do
                theta = Angle * DEGREES
                x = math.cos(theta) * radius
                z = math.sin(theta) * radius
                table.insert(DeployPosition,{x = x + self.center_x,z =  z + self.center_z, rot = step * i,skin = skin})
                i = i + 1
            end
        end
        if theta > (endAngle - step) * DEGREES + 0.01 and not self.custom then
            table.remove(DeployPosition)
        end
    end
    return DeployPosition
end

function DeployCalc:GetCardioidPosition()
    local pos, pos2 = {}, {}
    local center_x, center_z = self.center_x, self.center_z
    local inv, radius = self.interval, self.radius
    local x1, y1 = 0, radius * 6 / 16
    local x2, y2
    local spin = self.spin * DEGREES
    local x, y = Rotate(x1, y1, spin)
    table.insert(pos, Vector3(center_x + x, 0, center_z + y))
    for i = 0, math.pi, 0.001 do
        x2 = radius * (math.sin(i) ^ 3)
        y2 = radius *
                 (13 * math.cos(i) - 5 * math.cos(i * 2) - 2 * math.cos(3 * i) -
                     math.cos(4 * i)) / 16
        if PointToPointDistance(x1, x2, y1, y2) > inv and x2 > inv / 2 then
            x1 = x2
            y1 = y2
            x, y = Rotate(x1, y1, spin)
            table.insert(pos, Vector3(center_x + x, 0, center_z + y))
            x, y = Rotate(-x1, y1, spin)
            table.insert(pos2, Vector3(center_x + x, 0, center_z + y))
        end
    end
    y2 = y1 - x1 * math.sqrt(3) / 2
    x, y = Rotate(0, y2, spin)
    table.insert(pos, Vector3(center_x + x, 0, center_z + y))
    local len = #pos + 1
    for k, v in pairs(pos2) do table.insert(pos, len, v) end
    return pos
end

function DeployCalc:GetStraightPosition()
    local DeployPosition = {}
    for i = 0, self.radius * 2, (self.interval + 0.0001) do
        local x, y = Rotate(0, i, self.spin * DEGREES)
        table.insert(DeployPosition,
                     Vector3(self.center_x + x, 0, self.center_z + y))
    end
    return DeployPosition
end

function DeployCalc:GetSquarePosition()
    local DeployPosition = {}
    local num = math.floor(math.abs(self.radius) / self.interval)
    local flags = true
    local length = (num - 1) * (self.interval + 0.02) / 2
    for i = length, -length, -(self.interval + 0.001) do
        if flags then
            for j = -length, length, self.interval + 0.001 do
                local x, y = Rotate(j, i, (self.spin + 90) * DEGREES)
                table.insert(DeployPosition,
                             Vector3(self.center_x + x, 0, self.center_z + y))
            end
        else
            for j = length, -length, -(self.interval + 0.001) do
                local x, y = Rotate(j, i, (self.spin + 90) * DEGREES)
                table.insert(DeployPosition,
                             Vector3(self.center_x + x, 0, self.center_z + y))
            end
        end
        flags = not flags
    end
    return DeployPosition
end
function DeployCalc:FivePointedStar()
    local DeployPosition = {}
    return DeployPosition
end

function DeployCalc:GetHexagramPosition()

    local DeployPosition, T2, T3, T4, T5, T6 = {}, {}, {}, {}, {}, {}
    local length = math.sqrt(3) * self.radius
    local num = math.floor(length / self.interval)
    local inv = length / num
    local xx1, yy1 = Rotate(self.radius * math.cos(math.pi / 2),
                            self.radius * math.sin(math.pi / 2),
                            self.spin * DEGREES)
    local xx2, yy2 = Rotate(self.radius * math.cos(math.pi / 6),
                            self.radius * math.sin(math.pi / 6),
                            self.spin * DEGREES)
    local xx3, yy3 = Rotate(self.radius * math.cos(-math.pi / 6),
                            self.radius * math.sin(-math.pi / 6),
                            self.spin * DEGREES)

    for i = 0, length + 0.01, (inv + 0.0001) do
        local x1, y1 = Rotate(i, 0, (-120 + self.spin) * DEGREES)
        table.insert(DeployPosition, Vector3(self.center_x + x1 + xx1, 0,
                                             self.center_z + y1 + yy1))

        local x2, y2 = Rotate(i, 0, self.spin * DEGREES)
        table.insert(T2, Vector3(self.center_x + x2 - xx2, 0,
                                 self.center_z + y2 - yy2))

        local x3, y3 = Rotate(i, 0, (120 + self.spin) * DEGREES)
        table.insert(T3, Vector3(self.center_x + x3 + xx3, 0,
                                 self.center_z + y3 + yy3))

        local x4, y4 = Rotate(i, 0, self.spin * DEGREES)
        table.insert(T4, Vector3(self.center_x + x4 - xx3, 0,
                                 self.center_z + y4 - yy3))

        local x5, y5 = Rotate(i, 0, (-120 + self.spin) * DEGREES)
        table.insert(T5, Vector3(self.center_x + x5 + xx2, 0,
                                 self.center_z + y5 + yy2))

        local x6, y6 = Rotate(i, 0, (120 + self.spin) * DEGREES)
        table.insert(T6, Vector3(self.center_x + x6 - xx1, 0,
                                 self.center_z + y6 - yy1))
    end

    for _, v in ipairs(T2) do table.insert(DeployPosition, v) end
    for _, v in ipairs(T3) do table.insert(DeployPosition, v) end
    for _, v in ipairs(T4) do table.insert(DeployPosition, v) end
    for _, v in ipairs(T5) do table.insert(DeployPosition, v) end
    for _, v in ipairs(T6) do table.insert(DeployPosition, v) end
    return DeployPosition
end
--ThePlayer.components.deploydata.scheme
function DeployCalc:GetSpecialPosition()
    local pos = {}
    local customscheme = self.userscheme[self.scheme]
    if  not customscheme then
        return pos
    end
    for _, v in ipairs(customscheme.data) do
        local spin = v.spin or 0
        local x, z = Rotate(v.x, v.z, (spin + self.spin) * DEGREES)
        local skin = Profile:GetLastUsedSkinForItem(v.prefab)
        table.insert(pos, {
            act = v.act,
            prefab = v.prefab,
            skin = v.skin or skin,
            x = x + self.center_x,
            z = z + self.center_z,
            rot = v.rot
        })
    end
    return pos
end
function DeployCalc:GetRwKey()
    return self.key_screen, self.key_deploy, self.key_placer
end
function DeployCalc:GetParmValue()
    return {
        self.spin, self.radius, self.interval, self.space, self.deploynum,
        self.range
    }
end
function DeployCalc:GetShapeValue() return self.shape end

function DeployCalc:GetFuncValue()
    return {
        self.layer, self.custom, self.corners, self.lockitem, self.crowded,
        self.coordinate
    }
end
function DeployCalc:GetFunc2Value() return {self.direction, self.order} end
--自定义参数
function DeployCalc:Deluserparm(t)
    local tab = {}
    for i,v in ipairs(self.userparm) do
        if  not t[i] then
            table.insert(tab,v)
        end
    end
    self.userparm = tab
    local r,js = pcall(json.encode,self.userparm)
    if  r then
        write(userparmPATH,js)
    end
end
function DeployCalc:SetParmName(index,name)
    if  self.userparm[index] then
        self.userparm[index].name = name
    end
    local r,js = pcall(json.encode,self.userparm)
    if  r then
        write(userparmPATH,js)
    end
end

function DeployCalc:SetDefaultParm(index)
    local parms = self.userparm[index]
    if  parms then
        for k, v in pairs(parms.data) do
            self[k] = v
        end
    end
end
function DeployCalc:SaveParmData(name)
    table.insert(self.userparm,{
        name = name,
        data = {
            spin = self.spin,
            deploynum = self.deploynum,
            radius = self.radius,
            space = self.space,
            range = self.range,
            interval = self.interval
        }
    })
    self:Save()
end
--自定义形状
function DeployCalc:DelShape(t)
    local tab = {}
    for i,v in ipairs(self.userscheme) do
        if  not t[i] then
            table.insert(tab,v)
        end
    end
    self.userscheme = tab
    local r,js = pcall(json.encode,self.userscheme)
    if  r then
        write(SHAPEPATH,js)
    end
end
function DeployCalc:SetShapeName(index,name)
    if  self.userscheme[index] then
        self.userscheme[index].name = name
    end
    local r,js = pcall(json.encode,self.userscheme)
    if  r then
        write(SHAPEPATH,js)
    end
end

function DeployCalc:GetSpecShapeName()
    return self.userscheme[self.scheme] and self.userscheme[self.scheme].name or '无自定义方案'
end



function DeployCalc:GetActionFromEntity(ent)
    if  relationaltable['builder'][ent.prefab] then
        return "builder",relationaltable.builder[ent.prefab]
    elseif relationaltable['deploy'][ent.prefab] then
        return "deploy",relationaltable.deploy[ent.prefab]
    elseif  ent.replica.inventoryitem and ent.replica.inventoryitem:CanBePickedUp() then
        return "drop",ent.prefab
    elseif AllRecipes[ent.prefab] and not AllRecipes[ent.prefab].is_deconstruction_recipe then
        return "builder",ent.prefab
    end
end
function DeployCalc:SelectEntity(entity)
    if  not self.candeploy then
        return
    end
    local act = self:GetActionFromEntity(entity)
    if  not act then
        return
    end
    local ents = {}
    for _, v in ipairs(self.ents) do
        if   v and v:IsValid() then
            table.insert(ents,v)
        end
    end
    self.ents = ents
    local ent = false
    for i, v in ipairs(self.ents) do
        if  v == entity then
            if  v.rctitle ~= nil then
                v.rctitle:Remove()
                v.rctitle = nil
            end
            v.AnimState:SetAddColour(0,0,0,0)
            table.remove(self.ents,i)
            ent = true
            break
        end
    end
    if  not ent then
        entity.AnimState:SetAddColour(.25, .25, .75, 0)
        table.insert(self.ents,entity)
    end
    self:RefreshEntity()
end
function DeployCalc:RefreshEntity()
    for i, v in ipairs(self.ents) do
        if  v.rctitle == nil then
            v.rctitle = SpawnPrefab("rctitle")
            v.rctitle.entity:SetParent(v.entity)
        end
        v.rctitle:SetText(("%d"):format(i))
    end
end

function DeployCalc:SaveEntityConfig(name)
    local presets = {}
    for _, v in ipairs(self.ents) do
        if  v and v:IsValid() then
            local act,prefab = self:GetActionFromEntity(v)
            local x,_,z = v.Transform:GetWorldPosition()
            x = x - self.center_x
            z = z - self.center_z
            if  act == "drop" then
                table.insert(presets,{act = "drop", prefab = prefab,x = x,z = z})
            elseif act == "builder" then
                local skin = v.GetSkinName and v:GetSkinName()
                table.insert(presets,{act = "builder", prefab = prefab,x = x,z = z,skin = skin})
            elseif act == "deploy" then
                table.insert(presets,{act = "deploy", prefab = prefab,x = x,z = z})
            end
        end
    end
    if  #presets == 0 then
        return false
    end
    table.insert(self.userscheme,{name = name ,data = presets})
    self:Save()
    self:ClearEntity()
end
function DeployCalc:ClearEntity()
    for _, v in ipairs(self.ents) do
        if  v.rctitle ~= nil then
            v.rctitle:Remove()
            v.rctitle = nil
        end
        if  v and v:IsValid() then
            v.AnimState:SetAddColour(0,0,0,0)
        end
    end
    self.ents = {}
end
function  DeployCalc:ChangeRecordMode()
    if  self.recordmode then
        self.recordmode = false
        self:ClearEntity()
    else
        self.recordmode = true
    end
end

function DeployCalc:SaveCustomConfig(name)
    if  self.recordmode then
        self:SaveEntity(name)
    else
        self:SaveParmData(name)
    end
end

return DeployCalc
