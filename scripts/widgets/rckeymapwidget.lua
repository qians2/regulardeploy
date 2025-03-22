local Image = require "widgets/image"
local Widget = require "widgets/widget"
local Text = require("widgets/text")
local TextButton = require("widgets/textbutton")
local ImageButton = require "widgets/imagebutton"
local Config  = _G.RDConfig 
local L = TUNING.RCLANG == "ch_s" and true or false
local keylist = {
	{key = "key_screen", text = "设置键",text_en = "key_setting"},
	{key = "key_deploy",text = "放置键",text_en = "key_deploy"},
	{key = "key_placer",text = "预览键",text_en = "key_placer"}
}
local keys = { "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z", "F1", "F2", "F3", "F4", "F5", "F6", "F7", "F8", "F9", "F10", "F11", "F12", "LAlt", "RAlt", "LCtrl", "RCtrl", "LShift", "RShift", "Tab", "Capslock", "Space", "Minus", "Equals", "Backspace", "Insert", "Home", "Delete", "End", "Pageup", "Pagedown", "Print", "Scrollock", "Pause", "Period", "Slash", "Semicolon", "Leftbracket", "Rightbracket", "Backslash", "Up", "Down", "Left", "Right" }
local keyslist = {}
for _, v in ipairs(keys) do
	keyslist[_G["KEY_"..string.upper(v)]] = v
end

-------------------------------------------------------------------------------------------------------

local RCKeyMapWidget = Class(Widget, function(self, owner)
    Widget._ctor(self, "RCInputWidget")
    self.root = self:AddChild(Widget("root"))
	self.root:SetPosition(0, -70)
	self.root:MoveToFront()
	local backdrop = self.root:AddChild(Image("images/quagmire_recipebook.xml", "quagmire_recipe_menu_bg.tex"))
    backdrop:ScaleToSize(240, 200)
	self.key_temp = {}
	self.index = 1
	self.text = self.root:AddChild(Text(CHATFONT, 24))
	self.text:SetPosition(0, 20)
    self.text:SetColour(UICOLOURS.BLUE)
	self.text:SetString(L and "按下新的键进行调整\n当前按键:"..string.upper(string.char(106)) or "Press the new key to adjust \n the current key:"..string.upper(string.char(106)) )
	self.parm = self.root:AddChild(Text(CHATFONT, 24))
	self.parm:SetPosition(0, 60)
    self.parm:SetColour(UICOLOURS.RED)
	self.parm:SetString(L and keylist[self.index].text or keylist[self.index].text_en)
	self.ok = self.root:AddChild(TextButton("images/ui.xml", "blank.tex"))
	self.ok:SetPosition(40, -50)
	self.ok:SetTextSize(24)
	self.ok:SetText(L and "确定" or "ok")
	self.ok:SetTextColour(UICOLOURS.SILVER)
	self.ok:SetOnClick(function()
		for k, v in ipairs(self.key_temp) do
			Config[keylist[k].key] = v
		end
		--Config[self.key] = self.key_temp
		Config.block = false
		self:Hide()
	end)
	self.exit = self.root:AddChild(TextButton("images/ui.xml", "blank.tex"))
	self.exit:SetPosition(-40, -50)
	self.exit:SetTextSize(24)
	self.exit:SetText(L and "取消" or "exit")
	self.exit:SetTextColour(UICOLOURS.GOLD)
	self.exit:SetOnClick(function()
		Config.block = false
		self:Hide()
	end)
	self.left_btn = self.root:AddChild(ImageButton("images/ui.xml", "arrow2_left.tex"))
	self.left_btn:SetOnClick(function()
		if  self.index == 1 then
			self.index = 3
		else
			self.index = self.index - 1
		end
		self:OnUpdate()
	end)
	self.left_btn:SetNormalScale(0.3)
	self.left_btn:SetFocusScale(0.4)
	self.left_btn:SetImageNormalColour(UICOLOURS.GOLD)
	self.left_btn:SetImageFocusColour(UICOLOURS.WHITE)
	self.left_btn:SetPosition(-60, 60)
	self.left_btn:SetHoverText(L and "上一个" or "previous")

	self.right_btn = self.root:AddChild(ImageButton("images/ui.xml", "arrow2_right.tex"))
	self.right_btn:SetOnClick(function()
		if  self.index == 3 then
			self.index = 1
		else
			self.index = self.index + 1
		end
		self:OnUpdate()
	end)
	self.right_btn:SetNormalScale(0.3)
	self.right_btn:SetFocusScale(0.4)
	self.right_btn:SetImageNormalColour(UICOLOURS.GOLD)
	self.right_btn:SetImageFocusColour(UICOLOURS.WHITE)
	self.right_btn:SetPosition(60, 60)
	self.right_btn:SetHoverText(L and "下一个" or "next")
end)

function RCKeyMapWidget:MakeSelectBtn()
	
end



function RCKeyMapWidget:OnUpdate()
	self.text:SetString(L and "按下新的键进行调整\n当前按键:"..keyslist[self.key_temp[self.index]] or "Press the new key to adjust \n the current key:"..keyslist[self.key_temp[self.index]])
	self.parm:SetString(L and keylist[self.index].text or keylist[self.index].text_en)
end

function RCKeyMapWidget:OnRawKey(key,down,...)
		if  keyslist[key] then
			self.key_temp[self.index] = key
			self:OnUpdate()
		end
end

function RCKeyMapWidget:OnControl(control, down)
	if RCKeyMapWidget._base.OnControl(self, control, down) then return true end
    if not down and  control == CONTROL_CANCEL then
        --TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/click_move")
		Config.block = false
        self:Hide()
        return true
    end
end

function RCKeyMapWidget:GetHelpText()

end

return RCKeyMapWidget
