local Image = require "widgets/image"
local TextButton = require("widgets/textbutton")
local Widget = require "widgets/widget"
local Text = require("widgets/text")
local L = TUNING.RCLANG == "ch_s" and true or false
-------------------------------------------------------------------------------------------------------
local keylist = {
	"7","8","9","-","4","5","6",".","1","2","3","0"
}
local parm = {
	spin = {text = "旋转",text_en = "spin"},
	radius = {text = "半径",text_en = "radius"},
	interval = {text = "间隔",text_en = "interval"},
	number = {text = "数量",text_en = "number"},
	angle = { text = "角度",text_en = "angle"},
	layerspac = {text = "层距",text_en = "layerspac"}
}

local function changedigit(self,number)
	local str = self.text:GetString()
	if  str == nil then
		str = ""
	end
	if string.len(str) > 10 then
		return
	end
	if  number == "-" then
		local s = string.sub(str,1,1)
		if  s == "-" then
			str = string.sub(str,2,-1)
		else
			str = "-" .. str
		end
	elseif number == "." then
		if  str == "" then
			str = "0."
		elseif str == "-" then
			str = "-0."
		else
			local s = string.find(str,".",1,true)
			if  not s then
				str = str .. "."
			end
		end
	else
		if  str == "0" and number ~= "0" then
			str = number
		elseif str == "0" and number == "0" then
			str = "0"
		else
			str = str..number
		end
	end
	self.text:SetString(str)
end
local RCInputWidget = Class(Widget, function(self, parent)
    Widget._ctor(self, "RCInputWidget")
    self.root = self:AddChild(Widget("root"))
	self.root:SetPosition(0, -70)
	self.root:MoveToFront()
	local backdrop = self.root:AddChild(Image("images/quagmire_recipebook.xml", "quagmire_recipe_menu_bg.tex"))
    backdrop:ScaleToSize(200, 240)
	self.key = "radius"
	self.parm = self.root:AddChild(Text(CHATFONT, 32))
	self.parm:SetPosition(-50, 75)
    self.parm:SetColour(UICOLOURS.BLACK)
	self.parm:SetString(L and  parm[self.key].text or parm[self.key].text_en)
	self.text = self.root:AddChild(Text(CHATFONT, 32))
	self.text:SetPosition(50, 75)
    self.text:SetColour(UICOLOURS.GREY)
	self.text:SetString("")
	self.ok = self.root:AddChild(TextButton("images/ui.xml", "blank.tex"))
	self.ok:SetPosition(60, -75)
	self.ok:SetTextSize(32)
	self.ok:SetText(L and "确定" or "ok")
	self.ok:SetTextColour(UICOLOURS.SILVER)
	self.ok:SetOnClick(function()
		if  parm[self.key] then
			local str = self.text:GetString()
			if str == "" or str == nil then
				if self.key == "interval" then
					parent:RecordChange(self.key,str)
				end
				self.text:SetString("")
				self:Hide()
				return
			end
			local s = string.sub(str,-1,-1)
			if s == "." then
				str = string.sub(str,1,-2)
			end
			if  tonumber(str) < 0 and self.key ~= "spin" then
				return
			end
			parent:RecordChange(self.key,str)
			self:Hide()
		end
		self.text:SetString("")
	end)

	self.del = self.root:AddChild(TextButton("images/ui.xml", "blank.tex"))
	self.del:SetPosition(5, -75)
	self.del:SetTextSize(32)
	self.del:SetText(L and "删除" or "del")
	self.del:SetTextColour(UICOLOURS.SILVER)
	self.del:SetOnClick(function()
		local str = self.text:GetString()
		if  str ~= "" then
			str = string.sub(str,1,-2)
		end
		self.text:SetString(str)
	end)

	self.exit = self.root:AddChild(TextButton("images/ui.xml", "blank.tex"))
	self.exit:SetPosition(-50, -75)
	self.exit:SetTextSize(32)
	self.exit:SetText(L and "取消" or "exit")
	self.exit:SetTextColour(UICOLOURS.SILVER)
	self.exit:SetOnClick(function()
		self.text:SetString("")
		self:Hide()
	end)
	local x_offset,y_offset = -55,42
	for k,v in ipairs(keylist) do
		self[v] = self.root:AddChild(TextButton("images/ui.xml", "blank.tex"))
		self[v]:SetPosition(x_offset, y_offset)
        self[v]:SetTextSize(60)
		self[v]:SetText(v)
        self[v]:SetTextColour(UICOLOURS.SILVER)
        self[v]:SetOnClick(function()
			changedigit(self,v)
        end)
		x_offset = x_offset + 40
		if x_offset > 65 then
			x_offset = - 55
			y_offset = y_offset - 40
		end
	end
end)

function RCInputWidget:OnUpdate()
	self.parm:SetString(L and parm[self.key].text or parm[self.key].text_en)
	self.ok:SetText(L and "确定" or "ok")
	self.del:SetText(L and "删除" or "del")
	self.exit:SetText(L and "取消" or "exit")
end

function RCInputWidget:OnRawKey(key,down,...)
	if  not down then
		if key == 127 then
			local str = self.text:GetString()
			if  str ~= "" then
				str = string.sub(str,1,-2)
			end
			self.text:SetString(str)
		elseif key == 45 or key == 269 then
			changedigit(self,"-")
		elseif key == 46 or key == 266 then
			changedigit(self,".")
		elseif key >= 48 and key <= 57 then
			changedigit(self,string.char(key))
		elseif key >= 256 and key <= 265 then
			changedigit(self,string.char(key - 208))
		end
	end
end


function RCInputWidget:OnControl(control, down)
	if RCInputWidget._base.OnControl(self, control, down) then return true end
    if not down and (control == CONTROL_MAP or control == CONTROL_CANCEL) then
        --TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/click_move")
        self:Hide()
        return true
    end
end

function RCInputWidget:GetHelpText()

end

return RCInputWidget
