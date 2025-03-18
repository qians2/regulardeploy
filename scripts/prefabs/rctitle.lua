local function SetText(inst, str)
	if inst and str and type(str) == "string" then
		if inst._showTitle == nil then
			inst._showTitle = inst.entity:AddLabel()
		end
		inst._showTitle:SetFont(BODYTEXTFONT)
		inst._showTitle:SetFontSize(24)
		inst._showTitle:SetWorldOffset(0,2.4,0)
		inst._showTitle:SetColour(191/255,0,0,1)
		inst._showTitle:SetText(str or "")
		inst._showTitle:Enable(true)
	end
	if inst._showImgTitle == nil then
		inst._showImgTitle = inst.entity:AddImage()
	end
    inst._showImgTitle:SetTint(1, 1, 1, 0.9)
    inst._showImgTitle:SetWorldOffset(0,1.5,0)
    inst._showImgTitle:SetUIOffset(0, 2.4, 0)
    inst._showImgTitle:Enable(true)
end

local function fn()
	local inst = CreateEntity()
	inst.entity:AddTransform()
	inst.entity:AddNetwork()
	inst._showTitle = nil
	inst._showImgTitle = nil
	inst.level = 0
	inst:AddTag("NOCLICK")
	inst.entity:SetPristine()
	inst.SetText = SetText
	inst.persists = false
	return inst
end

return Prefab("rctitle", fn)
