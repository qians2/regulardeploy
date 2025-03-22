local userid = TheNet:GetUserID()
local Config  = _G.RDConfig 
local itemplacer = Class(function(self) self.placer = {} end)
function itemplacer:GetPlacerName(item)
    if type(item) == "table" then
        local it = item[1]
        if type(AllRecipes[it]) == "table" then
            return AllRecipes[item].placer
        elseif PrefabExists(it .. "_placer") then
            return it .. "_placer"
        end
    elseif type(item) == "string" then
        if type(AllRecipes[item]) == "table" then
            return AllRecipes[item].placer
        end
    end
    local placerItem = ThePlayer.replica.inventory:GetActiveItem()
    if  placerItem and placerItem.replica.inventoryitem ~= nil then
        local seedInvitem = placerItem.replica.inventoryitem
        local placerName = seedInvitem:GetDeployPlacerName()
        if PrefabExists(placerName) then return placerName end
    end
    if ThePlayer.components.playercontroller.placer then
        local playercontroller = ThePlayer.components.playercontroller
        local recipe = playercontroller.placer_recipe
        local placerName = recipe.placer
        return placerName
    end
    if type(item) == "string" then
        if PrefabExists(item .. "_placer") then return item .. "_placer" end
    end
end
function itemplacer:SetAnimState(index, prefab)
    if index == 1 then
        prefab.AnimState:SetAddColour(.25, .25, .75, 0)
    else
        prefab.AnimState:SetAddColour(.25, .75, .25, 0)
    end
end
function itemplacer:ShowPlacer(pos)
    if #self.placer > 0 then self:HidePlacer() end
    for i, v in ipairs(pos) do
        local placerName = self:GetPlacerName(v.prefab)
        if placerName then
            local deployPlacer = SpawnPrefab(placerName, v.skin, nil, userid)
            if deployPlacer then
                local rot = (i - 1) * Config.step
                deployPlacer.Transform:SetPosition(v.x, 0, v.z)
                deployPlacer.Transform:SetRotation(90 - rot)
                self:SetAnimState(i, deployPlacer)
            end
            table.insert(self.placer, deployPlacer)
        end
    end
end
function itemplacer:HidePlacer()
    for _, iv in pairs(self.placer) do iv:Remove() end
    self.placer = {}
end
return itemplacer
