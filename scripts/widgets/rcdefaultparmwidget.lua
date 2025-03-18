local Image = require "widgets/image"
local Widget = require "widgets/widget"
local TextButton = require("widgets/textbutton")
local Text = require "widgets/text"
local ImageButton = require "widgets/imagebutton"
local TEMPLATES = require "widgets/redux/templates"
local Writeable = require("widgets/rcwriteablewidget")
local L = TUNING.RCLANG == "ch_s" and true or false
-------------------------------------------------------------------------------------------------------
local RCDPWidget = Class(Widget, function(self,mainscreen)
    Widget._ctor(self, "RCDefaultParmWidget")
    self.mainscreen = mainscreen
    self.root = self:AddChild(Widget("root"))
    self.root:SetPosition(0, -70)
    self.root:MoveToFront()
    local backdrop = self.root:AddChild(Image("images/quagmire_recipebook.xml",
                                              "quagmire_recipe_menu_bg.tex"))
    backdrop:ScaleToSize(480, 400)
    self.cancelbutton = self.root:AddChild(ImageButton("images/global_redux.xml", "close.tex", "close.tex"))
    self.cancelbutton:SetScale(0.5, 0.5)
    self.cancelbutton:SetOnClick(function()
        self:Close()
    end)
    self.cancelbutton:SetPosition(205, 165)

    self.deletebtn = self.root:AddChild(TextButton(BODYTEXTFONT))
    self.deletebtn:SetTextSize(32)

    self.deletebtn:SetPosition(0, -170, 0)
    self.deletebtn:SetTextColour(UICOLOURS.WHITE)
    self.deletebtn:SetText(L and "修改预设" or "Setting")
    self.deletebtn:SetOnClick(function()
        if  self.dests_scroll_list then
            self.dests_scroll_list:Kill()
            self.dests_scroll_list = nil
            self.deletebtn:SetTextColour(UICOLOURS.RED)
            self:MakeDelScreen()
            self.determine:Show()
        elseif self.dests_scroll_list_del then
            self.dests_scroll_list_del:Kill()
            self.dests_scroll_list_del = nil
            self.deletebtn:SetTextColour(UICOLOURS.WHITE)
            self.determine:Hide()
            self:MakeNormalScreen()
        end
        self.selectdest = {}
    end)

    self.determine = self.root:AddChild(TextButton(BODYTEXTFONT))
    self.determine:SetTextSize(32)
    self.determine:SetPosition(160, -170, 0)
    self.determine:SetTextColour(UICOLOURS.RED)
    self.determine:SetText(L and "确定" or "OK")
    self.determine:SetOnClick(function()
        ThePlayer.components.deploydata:DelCustomParm(self.selectdest)
        if self.dests_scroll_list_del then
            self.dests_scroll_list_del:Kill()
            self.dests_scroll_list_del = nil
            self.deletebtn:SetTextColour(UICOLOURS.WHITE)
            self.determine:Hide()
            self.selectdest = {}
            self:MakeNormalScreen()
        end
    end)
    self.determine:Hide()
    self.selectdest = {}
    self:MakeNormalScreen()
end)
function RCDPWidget:DestDeleteListItem()
    local item_width, item_height = 360, 60
    local dest = Widget("destination")
    dest.backing = dest:AddChild(TEMPLATES.ListItemBackground(item_width,
    item_height))
    dest.backing:SetPosition(-30, 0, 0)

    dest.parmname = dest:AddChild(Text(BODYTEXTFONT, 24))
    dest.parmname:SetPosition(-18, 12, 0)
    dest.parmname:SetHAlign(ANCHOR_LEFT)
    dest.parmname:SetRegionSize(item_width,item_height)
    dest.parmname:SetColour(.25, .75, .75, 1)
    
    dest.parmvalue = dest:AddChild(Text(BODYTEXTFONT, 24))
    dest.parmvalue:SetPosition(-18, -12, 0)
    dest.parmvalue:SetHAlign(ANCHOR_LEFT)
    dest.parmvalue:SetRegionSize(item_width,item_height)
    dest.parmvalue:SetColour(.25, .75, .75, 1)
    -- dest.parmname:SetVAlign(ANCHOR_RIGHT)
    dest.delbtn = dest:AddChild(TextButton(BODYTEXTFONT))
    dest.delbtn:SetTextSize(32)
    dest.delbtn:SetPosition(170, 0, 0)
    dest.delbtn:SetTextColour(UICOLOURS.RED)
    dest.delbtn:SetText("删除")
    dest.SetInfo = function(_,index,data)
            dest.parmname:SetString(data.name)
            local valuestr = L and "旋转:%s 半径:%s 间隔:%s 层距:%s 数量:%s 范围:%s" or "spin:%s radius:%s interval:%s layerspac:%s number:%s range:%s"
            valuestr = valuestr:format(data.data.spin,data.data.radius,data.data.interval,data.data.space,data.data.deploynum,data.data.range)
            dest.parmvalue:SetString(valuestr)
            if  data.delblock == true then
                --dest.delblock = true
                dest.delbtn:Hide()
            else
                dest.delbtn:Show()
            end
            dest.delbtn:SetOnClick(function()
                self.selectdest[index] = not self.selectdest[index]
                --self.mainscreen:OnUpdate()
                --self:Close()
                if  self.selectdest[index] then
                    dest.parmname:SetColour(UICOLOURS.RED)
                else
                    dest.parmname:SetColour(.25, .75, .75, 1)
                end
                dest.backing:SetOnClick(function()
                    --self.root:AddChild()
            end)
        end)
        if  self.selectdest[index] then
            dest.parmname:SetColour(UICOLOURS.RED)
        else
            dest.parmname:SetColour(.25, .75, .75, 1)
        end
        dest.backing:SetOnClick(function ()
            if  self.writable then
                self.writable:Kill()
            end
            self.writable = self.root:AddChild(Writeable(function (name)
                ThePlayer.components.deploydata:SetParmName(index,name)
                dest.parmname:SetString(name)
            end))
        end) 
    end
    return dest
end
function RCDPWidget:DestNormalListItem()
    local item_width, item_height = 380, 60
    local dest = Widget("destination")
    dest.backing = dest:AddChild(TEMPLATES.ListItemBackground(item_width,
    item_height, function() end))
    dest.backing:SetPosition(0, 0, 0)
    dest.parmname = dest:AddChild(Text(BODYTEXTFONT, 24))
    dest.parmname:SetPosition(5, 12, 0)
    dest.parmname:SetHAlign(ANCHOR_LEFT)
    dest.parmname:SetRegionSize(item_width - 10,item_height)
    dest.parmname:SetColour(.25, .75, .75, 1)

    dest.parmvalue = dest:AddChild(Text(BODYTEXTFONT, 24))
    dest.parmvalue:SetPosition(5, -12, 0)
    dest.parmvalue:SetHAlign(ANCHOR_LEFT)
    dest.parmvalue:SetRegionSize(item_width - 10,item_height)
    dest.parmvalue:SetColour(.25, .75, .75, 1)

    dest.SetInfo = function(_,index,data)
        dest.parmname:SetString(data.name)
        local valuestr = L and "旋转:%s 半径:%s 间隔:%s 层距:%s 数量:%s 范围:%s" or "spin:%s radius:%s interval:%s layerspac:%s number:%s range:%s"
        valuestr = valuestr:format(data.data.spin,data.data.radius,data.data.interval,data.data.space,data.data.deploynum,data.data.range)
        dest.parmvalue:SetString(valuestr)
        dest.backing:SetOnClick(function()
            ThePlayer.components.deploydata:SetDefaultParm(index)
                self.mainscreen:OnUpdate()
                self:Close()
        end)
    end
    return dest
end
function RCDPWidget:MakeDelScreen()
    local function ScrollWidgetsCtor(context, index)
        local widget = Widget("widget-" .. index)
        widget:SetOnGainFocus(function()
            self.dests_scroll_list_del:OnWidgetFocus(widget)
        end)
        widget.destitem = widget:AddChild(self:DestDeleteListItem())
        return widget
    end
    local function ApplyDataToWidget(context, widget, data, index)
        widget.destitem:Hide()
        if not data then
            return
        end
        widget.destitem:SetInfo(index,data)
        widget.destitem:Show()
    end
    if  not self.dests_scroll_list_del then
        self.dests_scroll_list_del = self.root:AddChild(TEMPLATES.ScrollingGrid(ThePlayer.components.deploydata.customparm, {
                context = {""},
                widget_width = 420,
                widget_height = 60,
                num_visible_rows = 5,
                num_columns = 1,
                item_ctor_fn = ScrollWidgetsCtor,
                apply_fn = ApplyDataToWidget,
                scrollbar_offset = 5,
                scrollbar_height_offset = -100,
                peek_percent = 0, -- may init with few clientmods, but have many servermods.
                allow_bottom_empty_row = true -- it's hidden anyway
            }))

        self.dests_scroll_list_del:SetPosition(0, 0)

        self.dests_scroll_list_del:SetFocusChangeDir(MOVE_DOWN, self.cancelbutton)
        self.dests_scroll_list_del:SetFocusChangeDir(MOVE_UP, self.dests_scroll_list_del)
    end

end

function RCDPWidget:MakeNormalScreen()
    local function ScrollWidgetsCtor(context, index)
        local widget = Widget("widget-" .. index)
        widget:SetOnGainFocus(function()
            self.dests_scroll_list:OnWidgetFocus(widget)
        end)
        widget.destitem = widget:AddChild(self:DestNormalListItem())
        return widget
    end
    local function ApplyDataToWidget(context, widget, data, index)
        widget.destitem:Hide()
        if not data then
            return
        end
        widget.destitem:Show()
        local dest = widget.destitem
        dest:SetInfo(index,data)
    end
    if  not self.dests_scroll_list then
        self.dests_scroll_list = self.root:AddChild(TEMPLATES.ScrollingGrid(ThePlayer.components.deploydata.customparm, {
                context = {""},
                widget_width = 420,
                widget_height = 60,
                num_visible_rows = 5,
                num_columns = 1,
                item_ctor_fn = ScrollWidgetsCtor,
                apply_fn = ApplyDataToWidget,
                scrollbar_offset = 5,
                scrollbar_height_offset = -100,
                peek_percent = 0, -- may init with few clientmods, but have many servermods.
                allow_bottom_empty_row = true -- it's hidden anyway
            }))

        self.dests_scroll_list:SetPosition(0, 0)

        self.dests_scroll_list:SetFocusChangeDir(MOVE_DOWN, self.cancelbutton)
        self.cancelbutton:SetFocusChangeDir(MOVE_UP, self.dests_scroll_list)
    end

end

function RCDPWidget:Close() self:Kill() end

function RCDPWidget:OnUpdate() end

function RCDPWidget:OnRawKey(key, down, ...) end

function RCDPWidget:OnControl(control, down)
    if RCDPWidget._base.OnControl(self, control, down) then return true end
    if not down and control == CONTROL_CANCEL then self:Close()return true end
end

function RCDPWidget:GetHelpText() end

return RCDPWidget
