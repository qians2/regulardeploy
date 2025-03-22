local itemplacer = require("itemplacers")()
local Config  = _G.RDConfig 
local DeployUtil = Class(function(self, inst)
    self.station_thread = nil
    self.station_thread_id = 'round_deploy_thread'
end)

function DeployUtil:Wait(time)
    Sleep(FRAMES * time)
    repeat Sleep(FRAMES * time) until not (ThePlayer.sg and
        ThePlayer.sg:HasStateTag("moving")) and not ThePlayer:HasTag("moving") and
        ThePlayer:HasTag("idle") and
        not ThePlayer.components.playercontroller:IsDoingOrWorking()
end

function DeployUtil:SendActionRPC(act, rightclick)
    local playercontroller = ThePlayer.components.playercontroller
    local pos = act:GetActionPoint() or
                    Vector3(ThePlayer.Transform:GetPosition())
    local controlmods = 10
    if playercontroller.locomotor then
        act.preview_cb = function()
            if rightclick then
                SendRPCToServer(RPC.RightClick, act.action.code, pos.x, pos.z,
                                nil, act.rotation, true, nil, nil,
                                act.action.mod_name)
            else
                SendRPCToServer(RPC.LeftClick, act.action.code, pos.x, pos.z,
                                nil, true, controlmods, nil, act.action.mod_name)
            end
        end
        playercontroller:DoAction(act)
    else
        if rightclick then
            SendRPCToServer(RPC.RightClick, act.action.code, pos.x, pos.z, nil,
                            act.rotation, true, nil, act.action.canforce,
                            act.action.mod_name)
        else
            SendRPCToServer(RPC.LeftClick, act.action.code, pos.x, pos.z, nil,
                            true, controlmods, act.action.canforce,
                            act.action.mod_name)
        end
    end
end

function DeployUtil:GetPosition()
    if Config.scheme then
        return Config:GetSpecialPosition()
    elseif Config.shape == "circle" then
        return Config:GetCirclePosition()
    elseif Config.shape == "cardioid" then
        return Config:GetCardioidPosition()
    elseif Config.shape == "straight" then
        return Config:GetStraightPosition()
    elseif Config.shape == "square" then
        return Config:GetSquarePosition()
    elseif Config.shape == "five_pointed_star" then
        return Config:FivePointedStar()
    elseif Config.shape == "hexagram" then
        return Config:GetHexagramPosition()
    else
        return {}
    end
end

function DeployUtil:GetActiveItem()
    return ThePlayer.replica.inventory:GetActiveItem()
end
function DeployUtil:GetNewActiveItem(prefab)
    local inventory = ThePlayer.replica.inventory
    local body_item = inventory:GetEquippedItem(EQUIPSLOTS.BODY)
    local back_item = inventory:GetEquippedItem(EQUIPSLOTS.BACK)
    local backpack = (back_item and back_item.replica.container) or
                         (body_item and body_item.replica.container)
    if type(prefab) == "string" then
        for _, inv in pairs(backpack and {inventory, backpack} or {inventory}) do
            for slot, item in pairs(inv:GetItems()) do

                if item and item.prefab == prefab then
                    inv:TakeActiveItemFromAllOfSlot(slot)
                    return item
                end
            end
        end
    elseif type(prefab) == "table" then
        for _, inv in pairs(backpack and {inventory, backpack} or {inventory}) do
            for slot, item in pairs(inv:GetItems()) do
                for _, v in ipairs(prefab) do
                    if item and item.prefab == v then
                        inv:TakeActiveItemFromAllOfSlot(slot)
                        return item
                    end
                end
            end
        end
    end
end
function DeployUtil:GetItem(name)
    local active_item = self:GetActiveItem()
    if not active_item then
        active_item = self:GetNewActiveItem(name)
    else
        if type(name) == "table" then
            local is = false
            for _, v in ipairs(name) do
                if active_item.prefab == v then
                    is = true
                    break
                end
            end
            if not is then active_item = self:GetNewActiveItem(name) end
        else
            if active_item.prefab ~= name then
                active_item = self:GetNewActiveItem(name)
            end
        end
    end
    return active_item
end
function DeployUtil:DoDeployAction(name, pos)
    local active_item = self:GetItem(name)
    if not active_item then return false end
    local inventoryitem = active_item.replica.inventoryitem
    if not (inventoryitem and inventoryitem:CanDeploy(pos, nil, ThePlayer)) then
        return false
    end
    local act = BufferedAction(ThePlayer, nil, ACTIONS.DEPLOY, active_item, pos)
    local playercontroller = ThePlayer.components.playercontroller
    if  playercontroller.ismastersim then
        playercontroller:DoAction(act)
    else
        self:SendActionRPC(act, true)
    end
    self:Wait(4)
end

function DeployUtil:DoDropAction(name, pos)
    local active_item = self:GetItem(name)
    if not active_item then return false end
    local act = BufferedAction(ThePlayer, nil, ACTIONS.DROP, active_item, pos)
    local playercontroller = ThePlayer.components.playercontroller
    if playercontroller.ismastersim then
        playercontroller:DoAction(act)
    else
        self:SendActionRPC(act, false)
    end
    self:Wait(4)
end

function DeployUtil:DoConstructAction(recipe, pos, skin, rot)
    local builder = ThePlayer.replica.builder
    rot = rot or 0
    if not builder:IsBuildBuffered(recipe.name) then
        if not builder:CanBuild(recipe.name) then return false end
        builder:BufferBuild(recipe.name)
    end
    if builder:CanBuildAtPoint(pos, recipe, 90 - rot) then
        builder:MakeRecipeAtPoint(recipe, pos, 90 - rot, skin)
    end
    self:Wait(6)
end
function DeployUtil:DoActionCollect(data)
    self.station_thread = StartThread(function()
        ThePlayer:ClearBufferedAction()
        for _, v in ipairs(data) do
            if v.act == "builder" then
                local it
                if type(v.prefab) == "table" then
                    it = v.prefab[1]
                elseif type(v.prefab) == "string" then
                    it = v.prefab
                end
                local recipe = AllRecipes[it]
                if recipe then
                    self:DoConstructAction(recipe, Vector3(v.x, 0, v.z), v.skin,
                                           v.rot)
                end
            elseif v.act == "deploy" then
                self:DoDeployAction(v.prefab, Vector3(v.x, 0, v.z))
            else
                self:DoDropAction(v.prefab, Vector3(v.x, 0, v.z))
            end
        end
        self:ClearStationThread()
    end)
end

function DeployUtil:ClearStationThread()
    if self.station_thread then
        KillThreadsWithID(self.station_thread.id)
        self.station_thread:SetList(nil)
        self.station_thread = nil
    end
end

function DeployUtil:DoSpecialBuilding(position)
    local builder = ThePlayer.replica.builder
    local product
    ThePlayer:ClearBufferedAction()
    self.station_thread = StartThread(function()
        for i, v in ipairs(position) do
            if i > 1 then
                local success = false
                local ents = TheSim:FindEntities(position[i - 1].x, 0,
                                                 position[i - 1].z, 0.02, nil,
                                                 {"IsInLimbo"})
                for _, item in ipairs(ents) do
                    if item.prefab == product then
                        success = true
                        break
                    end
                end
                if not success then
                    self:ClearStationThread()
                    return
                end
            end
            local rot = v.rot or 0
            if not builder:IsBuildBuffered(AllRecipes[v.prefab].name) then
                if not builder:CanBuild(AllRecipes[v.prefab].name) then
                    return false
                end
                builder:BufferBuild(AllRecipes[v.prefab].name)
            end
            if builder:CanBuildAtPoint(Vector3(v.x, 0, v.z),
                                       AllRecipes[v.prefab], 90 - rot) then
                builder:MakeRecipeAtPoint(AllRecipes[v.prefab],
                                          Vector3(v.x, 0, v.z), 90 - rot, v.skin)
                self:Wait(6)
            end
            product = AllRecipes[v.prefab].product
        end
    end, self.station_thread_id)
end

function DeployUtil:StartAutoDeploy()
    local position = self:GetPosition()
    if #position == 0 then return end
    local playercontroller = ThePlayer.components.playercontroller
    if Config.scheme ~= nil then
        self:DoActionCollect(position)
    elseif playercontroller.placer ~= nil then
        local recipe = playercontroller.placer_recipe
        local skin = playercontroller.placer_recipe_skin
        self.station_thread = StartThread(function()
            for _, v in ipairs(position) do
                self:DoConstructAction(recipe, Vector3(v.x, 0, v.z),
                                       v.skin or skin, v.rot)
            end
            self:ClearStationThread()
        end, self.station_thread_id)
    elseif playercontroller.deployplacer ~= nil then
        local active_item = self:GetActiveItem()
        if active_item then
            self.station_thread = StartThread(function()
                for _, v in ipairs(position) do
                    self:DoDeployAction(active_item.prefab, Vector3(v.x, 0, v.z))
                end
                self:ClearStationThread()
            end, self.station_thread_id)
        end
    else
        local items = ThePlayer.replica.inventory:GetItems()
        if items and items[1] ~= nil then
            local item = items[1]
            self.station_thread = StartThread(function()
                for _, v in ipairs(position) do
                    self:DoDropAction(item.prefab, Vector3(v.x, 0, v.z))
                end
                self:ClearStationThread()
            end, self.station_thread_id)
        end
    end
end
function DeployUtil:ShowPlacer() itemplacer:ShowPlacer(self:GetPosition()) end
function DeployUtil:HidePlacer() itemplacer:HidePlacer() end

return DeployUtil
