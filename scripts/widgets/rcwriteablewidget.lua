local Image = require "widgets/image"
local Widget = require "widgets/widget"
local TextButton = require("widgets/textbutton")
local Text = require "widgets/text"
local ImageButton = require "widgets/imagebutton"
local TextEdit = require "widgets/textedit"
local L = TUNING.RCLANG == "ch_s" and true or false
-------------------------------------------------------------------------------------------------------
local RCDPWidget = Class(Widget, function(self,callback)
    Widget._ctor(self, "RCWriteableWidget")
    self.callback = callback
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
    self.root = self:AddChild(Widget("writeableroot"))
    self.root:SetPosition(0, 0)
    self.root:MoveToFront()
    
    local backdrop = self.root:AddChild(Image("images/quagmire_recipebook.xml",
                                              "quagmire_recipe_menu_bg.tex"))
    backdrop:ScaleToSize(240, 160)

    self.titlle = self.root:AddChild(Text(CHATFONT, 24))
    self.titlle:SetPosition(0, 60)
    self.titlle:SetColour(UICOLOURS.RED)
	self.titlle:SetString("输入预设名:")

    self.edit_text = self.root:AddChild(TextEdit(BUTTONFONT, 24, ""))
    self.edit_text:SetColour(0, 0, 0, 1)
    self.edit_text:SetForceEdit(true)
    self.edit_text:SetPosition(0, 0, 0)
    self.edit_text:SetRegionSize(160, 60)
    self.edit_text:SetHAlign(ANCHOR_LEFT)
    self.edit_text:SetVAlign(ANCHOR_MIDDLE)
    self.edit_text:SetTextLengthLimit(200)
    self.edit_text:EnableWordWrap(true)
    self.edit_text:EnableWhitespaceWrap(true)
    self.edit_text:EnableRegionSizeLimit(true)
    self.edit_text:EnableScrollEditWindow(false)

    self.determinebtn = self.root:AddChild(TextButton("images/ui.xml", "blank.tex"))
    self.determinebtn:SetText("确定")
    self.determinebtn:SetTextSize(24)
    self.determinebtn:SetPosition(60, -50)
    self.determinebtn:SetOnClick(function()
        local str = self.edit_text:GetString()
        if  str:len() <= 0 then
            return
        end
        if  self.callback then
            self.callback(self.edit_text:GetString())
        end
        self:Close()
    end)
    self.cancelbtn = self.root:AddChild(TextButton("images/ui.xml", "blank.tex"))
    self.cancelbtn:SetText("取消")
    self.determinebtn:SetTextSize(24)
    self.cancelbtn:SetOnClick(function()
        self:Close()
    end)
    self.cancelbtn:SetPosition(-60, -50)
end)


function RCDPWidget:Close() self:Kill() end

function RCDPWidget:OnUpdate() end

function RCDPWidget:OnRawKey(key, down, ...) end

function RCDPWidget:OnControl(control, down)
    if RCDPWidget._base.OnControl(self, control, down) then return true end
    if not down and control == CONTROL_CANCEL then self:Close() return true end
end

function RCDPWidget:GetHelpText() end

return RCDPWidget
