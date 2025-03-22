local Screen = require "widgets/screen"
local Widget = require "widgets/widget"
local ImageButton = require "widgets/imagebutton"
local Text = require("widgets/text")
local TextButton = require("widgets/textbutton")
local Image = require("widgets/image")
local RCInput = require "widgets/rcinputwidget"
local RCKeyMap = require "widgets/rckeymapwidget"
local RCShape = require "widgets/rcspecialshapewidget"
local RCParm = require "widgets/rcdefaultparmwidget"
local Writeable = require("widgets/rcwriteablewidget")
local Config  = _G.RDConfig 
local L = TUNING.RCLANG == "ch_s" and true or false
local parm = {
    [1] = {
        name = "spin",
        text = "旋转角度",
        honver_text = "设置旋转的角度",
        text_en = "spin",
        honver_text_en = "Set the angle of rotation"
    },
    [2] = {
        name = "radius",
        text = "半    径",
        honver_text = "设置半径",
        text_en = "radius",
        honver_text_en = "Set the Radius"
    },
    [3] = {
        name = "interval",
        text = "间    隔",
        honver_text = "设置放置物品间的距离",
        text_en = "interval",
        honver_text_en = "Set the distance between items"
    },
    [4] = {
        name = "layerspac",
        text = "层    距",
        honver_text = "层与层之间额外距离",
        text_en = "layerspac",
        honver_text_en = "Additional distance between layers"
    },
    [5] = {
        name = "number",
        text = "数    量",
        honver_text = "设置摆放物品的数量(圆形且单层)",
        text_en = "number",
        honver_text_en = "Set the number of items placed (round and single layer)"
    },
    [6] = {
        name = "angle",
        text = "部署角度",
        honver_text = "设置放置的范围",
        text_en = "angle",
        honver_text_en = "Set placement range(0 ~360)"
    }
}

local shapes = {
    [1] = {
        name = "circle",
        text = "圆    形",
        honver_text = "修改形状为圆形",
        text_en = "circle",
        honver_text_en = "Change the shape to a circle"
    },
    [2] = {
        name = "cardioid",
        text = "心    形",
        honver_text = "修改形状为心形",
        text_en = "cardioid",
        honver_text_en = "Change the shape to a cardioid"
    },
    [3] = {
        name = "straight",
        text = "直    线",
        honver_text = "修改形状为直线形",
        text_en = "straight",
        honver_text_en = "Change the shape to a cardioid"
    },
    [4] = {
        name = "square",
        text = "正 方 形",
        honver_text = "修改形状为正方形",
        text_en = "square",
        honver_text_en = "Change the shape to a square"
    },
    -- [5] = {
    --     name = "five_pointed_star",
    --     text = "五 角 星",
    --     honver_text = "修改形状为五角星",
    --     text_en = "five_p_s",
    --     honver_text_en = "Change the shape to a five_pointed_star"
    -- },
    [5] = {
        name = "hexagram",
        text = "六 芒 星",
        honver_text = "修改形状为六芒星",
        text_en = "hexagram",
        honver_text_en = "Change the shape to a hexagram"
    }
}
local func = {
    [1] = {
        name = "layer",
        text = "满层摆放",
        honver_text = "切换是否放满整个圆",
        text_en = "full_layer",
        honver_text_en = "Toggle whether to fill the whole circle"
    },
    [2] = {
        name = "custom",
        text = "自由摆放",
        honver_text = "切换是否取消半径和数量的关联",
        text_en = "custom",
        honver_text_en = "Toggle whether to disassociate radius and quantity"
    },
    [3] = {
        name = "corners",
        text = "锁定边角",
        honver_text = "切换中心点是否在边与角或中心上",
        text_en = "corners",
        honver_text_en = "Toggle whether the center point is on the edge and corner or center"
    },
    [4] = {
        name = "lockitem",
        text = "锁定物品",
        honver_text = "设置中心点是否为鼠标位置的物品",
        text_en = "lock_item",
        honver_text_en = "Set whether the center point is an item at the mouse position"
    },
    [5] = {
        name = "crowded",
        text = "紧密模式",
        honver_text = "在该半径下尽可能多的放置物品",
        text_en = "crowded",
        honver_text_en = "Place as many items as possible this radius"
    },
    [6] = {
        name = "coordinate",
        text = "显示坐标",
        honver_text = "在左上角显示当前角色坐标",
        text_en = "coordinate",
        honver_text_en = "Display the current character coordinates in the upper left corner"
    }
}
local func2 = {
    [1] = {
        name = "direction",
        text = "逆 时 针",
        honver_text = "逆时针摆放物品",
        text_en = "direction",
        honver_text_en = "Place items counterclockwise"
    },
    [2] = {
        name = "order",
        text = "内 - 外",
        honver_text = "多层时先放最内层",
        text_en = "order",
        honver_text_en = "Put the innermost layer first when there are multiple layers"
    }
}

local keylist = {"key_screen", "key_deploy", "key_placer"}

local function AddHoverText(widget, params, labelText)
    params = params or {}
    params.offset_x = params.offset_x or 2
    params.offset_y = params.offset_y or 75
    local sign = params.offset_y < 0 and -1 or 1
    params.offset_y = params.offset_y + sign *
                          (labelText:match("\n") and 30 or 0)
    params.colour = params.colour or UICOLOURS.BLUE
    local text = widget.text
    widget.text = nil
    widget:SetHoverText(labelText, params)
    widget.text = text
end
local RCScreen = Class(Screen, function(self, owner)
    self.owner = owner
    Screen._ctor(self, "RCScreen")
    local black = self:AddChild(ImageButton("images/global.xml", "square.tex"))
    black.image:SetVRegPoint(ANCHOR_MIDDLE)
    black.image:SetHRegPoint(ANCHOR_MIDDLE)
    black.image:SetVAnchor(ANCHOR_MIDDLE)
    black.image:SetHAnchor(ANCHOR_MIDDLE)
    black.image:SetScaleMode(SCALEMODE_FILLSCREEN)
    black.image:SetTint(0, 0, 0, 0)
    black:SetOnClick(function()
        self:Close()
    end)
    self.root = self:AddChild(Widget("root"))
    self.root:SetScaleMode(SCALEMODE_PROPORTIONAL)
    self.root:SetHAnchor(ANCHOR_MIDDLE)
    self.root:SetVAnchor(ANCHOR_MIDDLE)
    self.root:SetPosition(0, 0)
    self.backdrop = self.root:AddChild(Image("images/quagmire_recipebook.xml", "quagmire_recipe_menu_bg.tex"))
    self.backdrop:ScaleToSize(600, 280)
    self.backdrop:SetPosition(-8, 0)

	self.specialshapename = self.root:AddChild(Text(CHATFONT, 24))
	self.specialshapename:SetPosition(0, 100)
    self.specialshapename:SetColour(UICOLOURS.RED)
	self.specialshapename:SetString("当前自定义方案:无自定义方案")
    self.specialshapename:Hide()
    self:Draw()
    self.inputwidget = self.root:AddChild(RCInput(self))
    self.inputwidget:Hide()

    self.keymapwidget = self.root:AddChild(RCKeyMap(owner))
    self.keymapwidget:Hide()
end)

function RCScreen:Draw()
    local x_offset = -200
    for k, v in ipairs(parm) do
        self[v.name] = self.root:AddChild(
                           TextButton("images/ui.xml", "blank.tex"))
        self[v.name]:SetPosition(x_offset, 60)
        self[v.name]:SetText(L and v.text .. "\n" or v.text_en .. "\n")
        self[v.name]:SetTextSize(25)
        self[v.name]:SetTextColour(UICOLOURS.SILVER)
        self[v.name]:SetOnClick(function()
            self[v.name]:OnLoseFocus()
            self.inputwidget.key = v.name
            self.inputwidget:OnUpdate()
            self.inputwidget:Show()
        end)
        AddHoverText(self[v.name], {offset_x = -4, offset_y = 50},
                     L and v.honver_text or v.text_en)
        x_offset = x_offset + 80
    end
    x_offset = -200
    for k, v in ipairs(shapes) do
        self[v.name] = self.root:AddChild(
                           TextButton("images/ui.xml", "blank.tex"))
        self[v.name]:SetPosition(x_offset, 10)
        self[v.name]:SetText(L and v.text or v.text_en)
        self[v.name]:SetTextSize(25)
        self[v.name]:SetTextColour(UICOLOURS.SILVER)
        self[v.name]:SetOnClick(function()
            Config.shape = v.name
            Config.scheme = nil
            self:OnUpdate()
            self[v.name]:OnLoseFocus()
        end)
        AddHoverText(self[v.name], {offset_x = -4, offset_y = 30},
                     L and v.honver_text or v.honver_text_en)
        x_offset = x_offset + 80
    end

    self.recordmode = self.root:AddChild(
        TextButton("images/ui.xml", "blank.tex"))
    self.recordmode:SetPosition(x_offset, 10)
    self.recordmode:SetText(L and "记录模式" or "record-mode")
    self.recordmode:SetTextSize(25)
    self.recordmode:SetTextColour(UICOLOURS.SILVER)
    self.recordmode:SetOnClick(function()
        Config:ChangeRecordMode()
    self:OnUpdate()
    self.recordmode:OnLoseFocus()
    end)
    AddHoverText(self.recordmode, {offset_x = -4, offset_y = 30}, L and "进入记录模式" or "record mode")

    x_offset = -200
    for k, v in ipairs(func) do
        self[v.name] = self.root:AddChild(
                           TextButton("images/ui.xml", "blank.tex"))
        self[v.name]:SetPosition(x_offset, -40)
        self[v.name]:SetText(L and v.text or v.text_en)
        self[v.name]:SetTextSize(25)
        self[v.name]:SetTextColour(UICOLOURS.SILVER)
        self[v.name]:SetOnClick(function()
            local val = Config[v.name]
            Config[v.name] = not val
            if v.name == "coordinate" then
                self.owner:PushEvent("coordinateschange")
            end
            self:OnUpdate()
            self[v.name]:OnLoseFocus()
        end)
        AddHoverText(self[v.name], {offset_x = -4, offset_y = 30},
                     L and v.honver_text or v.text_en)
        x_offset = x_offset + 80
    end

    x_offset = -200
    for _, v in ipairs(func2) do
        self[v.name] = self.root:AddChild(
                           TextButton("images/ui.xml", "blank.tex"))
        self[v.name]:SetPosition(x_offset, -90)
        self[v.name]:SetText(L and v.text or v.text_en)
        self[v.name]:SetTextSize(25)
        self[v.name]:SetTextColour(UICOLOURS.SILVER)
        self[v.name]:SetOnClick(function()
            local val = Config[v.name]
            Config[v.name] = not val
            self:OnUpdate()
            self[v.name]:OnLoseFocus()
        end)
        AddHoverText(self[v.name], {offset_x = -4, offset_y = 30},
                     L and v.honver_text or v.text_en)
        x_offset = x_offset + 80
    end

    self.changekey =
        self.root:AddChild(TextButton("images/ui.xml", "blank.tex"))
    self.changekey:SetPosition(x_offset, -90)
    self.changekey:SetText(L and "修改按键" or "key")
    self.changekey:SetTextSize(25)
    self.changekey:SetTextColour(UICOLOURS.SILVER)
    self.changekey:SetOnClick(function()
        Config.block = true
        for k, v in ipairs(keylist) do
            self.keymapwidget.key_temp[k] = Config[v]
        end
        self.keymapwidget:OnUpdate()
        self.keymapwidget:Show()
    end)
    AddHoverText(self.changekey, {offset_x = -4, offset_y = 30},
                 L and "修改按键" or "Modify the key")
    x_offset = x_offset + 80

    self.specialshape = self.root:AddChild(
                          TextButton("images/ui.xml", "blank.tex"))
    self.specialshape:SetPosition(x_offset, -90)
    self.specialshape:SetText(L and "预设形状" or "sp-shape")
    self.specialshape:SetTextSize(25)
    self.specialshape:SetTextColour(UICOLOURS.SILVER)
    self.specialshape:SetOnClick(function()
        self.shapewidget = self.root:AddChild(RCShape(self))
    end)
    AddHoverText(self.specialshape, {offset_x = -4, offset_y = 30}, L and "一键六锅" or "Auto six cookpot")
    x_offset = x_offset + 80

    self.setdefault = self.root:AddChild(
                          TextButton("images/ui.xml", "blank.tex"))
    self.setdefault:SetPosition(x_offset, -90)
    self.setdefault:SetText(L and "预设参数" or "default")
    self.setdefault:SetTextSize(25)
    self.setdefault:SetTextColour(UICOLOURS.SILVER)
    self.setdefault:SetOnClick(function()
        self.shapewidget = self.root:AddChild(RCParm(self))
    end)
    AddHoverText(self.setdefault, {offset_x = -4, offset_y = 30}, L and
                     "选择已保存的参数" or
                     "Return parameters to default values")
    x_offset = x_offset + 80


    self.saveparm = self.root:AddChild(
                          TextButton("images/ui.xml", "blank.tex"))
    self.saveparm:SetPosition(x_offset, -90)
    self.saveparm:SetText(L and "保存预设" or "save-record")
    self.saveparm:SetTextSize(25)
    self.saveparm:SetTextColour(UICOLOURS.SILVER)
    self.saveparm:SetOnClick(function ()
        if  self.writable then
            self.writable:Kill()
        end
        self.writable = self.root:AddChild(Writeable(function (name)
            Config:SaveCustomData(name)
        end))
        if  Config.recordmode then
            self.writable.titlle:SetString("输入 预设形状 名:")
        else
            self.writable.titlle:SetString("输入 预设参数 名:")
        end
    end)
    AddHoverText(self.saveparm, {offset_x = -4, offset_y = 30}, L and  "保存记录的数据" or "Return parameters to default values")
    x_offset = x_offset + 80


    self.cancelbutton = self.root:AddChild(ImageButton("images/global_redux.xml", "close.tex", "close.tex"))
    self.cancelbutton:SetPosition(245, 100)
    self.cancelbutton:SetScale(0.5, 0.5)
    self.cancelbutton:SetOnClick(function() self:Close() end)
    AddHoverText(self.cancelbutton, {offset_x = -4, offset_y = 30},
                 L and "关闭界面" or "Close screen")
    --x_offset = x_offset + 100
    -- local i = -400
    -- local j = -200
    -- for k, v in pairs(UICOLOURS) do
    --     self[k] = self.root:AddChild(TextButton("images/ui.xml", "blank.tex"))
    --     self[k]:SetPosition(i, j, 0)
    --     self[k]:SetText(k)
    --     self[k]:SetTextSize(25)
    --     self[k]:SetTextColour(v)
    --     i = i + 150
    --     if i > 400 then
    --         i = -400
    --         j = j + 100
    --     end
    -- end
end

function RCScreen:RecordChange(key, number)
    if key == "interval" and (number == "" or number == nil) then
        local item = self.owner.replica.inventory:GetActiveItem()
        if self.min_spacing then
            number = self.min_spacing
        elseif item and item.replica.inventoryitem then
            number = item.replica.inventoryitem:DeploySpacingRadius()
        end
    end
    if number == "" or number == nil then return end
    number = tonumber(number)
    if number == 0 and (key == "radius" or key == "number" or key == "interval") then
        return
    end
    if key == "radius" then
        Config:SetR(number)
    elseif key == "number" then
        if number ~= "0" then
            Config:SetN(number)
        end
    elseif key == "interval" then
        Config:SetI(number)
    elseif key == "spin" then
        Config:SetS(number)
    elseif key == "angle" then
        Config:SetA(number)
    elseif key == "layerspac" then
        Config:SetL(number)
    end
    self:OnUpdate()
end

function RCScreen:OnUpdate()
    local parmvalue = Config:GetParmValue()
    local str
    for k, v in ipairs(parm) do
        str = string.format("%s\n%s", L and v.text or v.text_en, parmvalue[k])
        self[v.name]:SetText(str)
    end
    for _, v in ipairs(shapes) do
        self[v.name]:SetTextColour(UICOLOURS.SILVER)
    end

    if not Config.scheme then
        self.specialshapename:Hide()
        local shape = Config:GetShapeValue()
        if  self[shape]  then
            self[shape]:SetTextColour(UICOLOURS.RED)
        end
        self.specialshape:SetTextColour(UICOLOURS.SILVER)
    else
        self.specialshape:SetTextColour(UICOLOURS.RED)
        local SpecShapeName = Config:GetSpecShapeName()
        self.specialshapename:SetString("当前自定义方案:"..SpecShapeName)
        self.specialshapename:Show()
    end
    if  Config.recordmode then
        self.recordmode:SetTextColour(UICOLOURS.RED)
    else
        self.recordmode:SetTextColour(UICOLOURS.SILVER)
    end
    local fucnvalue = Config:GetFuncValue()
    for k, v in ipairs(func) do
        if fucnvalue[k] then
            self[v.name]:SetTextColour(UICOLOURS.RED)
        else
            self[v.name]:SetTextColour(UICOLOURS.SILVER)
        end
    end
    local fucn2value = Config:GetFunc2Value()
    for k, v in ipairs(func2) do
        if fucn2value[k] then
            self[v.name]:SetTextColour(UICOLOURS.RED)
        else
            self[v.name]:SetTextColour(UICOLOURS.SILVER)
        end
    end

end

function RCScreen:Close()
    Config:Save()
    TheFrontEnd:PopScreen(self)
    self.inactive = true
end

function RCScreen:OnDestroy() RCScreen._base.OnDestroy(self) end

function RCScreen:OnBecomeInactive() RCScreen._base.OnBecomeInactive(self) end

function RCScreen:OnBecomeActive() RCScreen._base.OnBecomeActive(self) end

function RCScreen:OnRawKey(key, down)
    if RCScreen._base.OnRawKey(self, key, down) then return true end
    if down and key == Config.key_screen and not self.keymapwidget.focus then
        self:Close()
    end
end

function RCScreen:OnControl(control, down)
    if RCScreen._base.OnControl(self, control, down) then return true end
    if not down and (control == CONTROL_MAP or control == CONTROL_CANCEL) and not self.keymapwidget.focus then
        self:Close()
        return true
    end
    return false
end

return RCScreen
