local assets=
{
    Asset("ANIM", "anim/firefighter_placement.zip")
}
local function fn()
    local inst = CreateEntity()
    local trans = inst.entity:AddTransform()
    local anim = inst.entity:AddAnimState()
    trans:SetScale(1.55, 1.55,1.55)
    --inst.AnimState:SetAddColour(0, .2, .5, 0)
    inst.AnimState:SetAddColour(.3,.2,.5,0)
    inst.AnimState:SetLightOverride(1)
    inst.entity:SetPristine()

    anim:SetBank("firefighter_placement")
    anim:SetBuild("firefighter_placement")
    anim:PlayAnimation("idle")
    anim:SetOrientation(ANIM_ORIENTATION.OnGround)
    anim:SetLayer(LAYER_BACKGROUND)
    anim:SetSortOrder(3)
    inst.persists = false
    inst:AddTag("FX")
    inst:AddTag("deployrange")
    return inst
end
return Prefab( "common/deployrange", fn, assets)