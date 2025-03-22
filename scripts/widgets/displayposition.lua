local Text = require "widgets/text"
local Widget = require "widgets/widget"

local DPWidget = Class(Widget, function(self,owner)
    Widget._ctor(self, "CoordinatesWidget")
    self.num = self:AddChild(Text(NUMBERFONT, 30))
    self.num:SetHAlign(ANCHOR_MIDDLE)
    self.num:SetString("")
    self.num:SetPosition(0, -25)
    self:SetScaleMode(SCALEMODE_PROPORTIONAL)
    self:StartUpdating()
end)

function DPWidget:OnUpdate(dt)
    local x, _, z = ThePlayer.Transform:GetWorldPosition()
    local str = string.format("%.2f,%.2f", x,z)
    self.num:SetString(str)
end
return DPWidget
