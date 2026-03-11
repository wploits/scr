local OrionLib = loadstring(game:HttpGet(('https://raw.githubusercontent.com/shlexware/Orion/main/source')))()
local Window = OrionLib:MakeWindow({Name = "Auto Bridge & Obby", HidePremium = false, SaveConfig = true, ConfigFolder = "AutoBridgeConfig"})
local Tab = Window:MakeTab({Name = "Main", Icon = "rbxassetid://4483345998", PremiumOnly = false})

local Players = game:GetService("Players")
local PathfindingService = game:GetService("PathfindingService")
local LocalPlayer = Players.LocalPlayer
local autoBridgeEnabled = false
local autoObbyEnabled = false

local function getRealRaceFolder()
    for _, folder in ipairs(workspace:GetChildren()) do
        if folder:IsA("Folder") then
            if folder:FindFirstChild("Red") or folder:FindFirstChild("Blue") then
                return folder
            end
        end
    end
    return nil
end

local function getClosestGiver(base, currentBridge)
    local closestGiver = nil
    local shortestDistance = math.huge
    local bridgePos = currentBridge and currentBridge:GetPivot().Position or Vector3.new(0, 0, 0)
    local blockMain = base:FindFirstChild("BlockMain")
    
    if blockMain then
        for _, child in ipairs(blockMain:GetChildren()) do
            if child.Name == "Giver" then
                local dist = (child:GetPivot().Position - bridgePos).Magnitude
                if dist < shortestDistance then
                    shortestDistance = dist
                    closestGiver = child
                end
            end
        end
    end
    return closestGiver
end

local function walkTo(targetPosition)
    local character = LocalPlayer.Character
    if not character then return end
    local humanoid = character:FindFirstChild("Humanoid")
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not humanoid or not hrp then return end

    local path = PathfindingService:CreatePath({
        AgentRadius = 2,
        AgentHeight = 5,
        AgentCanJump = true,
        AgentJumpHeight = 10,
        AgentMaxSlope = 45,
    })
    
    path:ComputeAsync(hrp.Position, targetPosition)
    
    if path.Status == Enum.PathStatus.Success then
        local waypoints = path:GetWaypoints()
        for _, waypoint in ipairs(waypoints) do
            if not autoBridgeEnabled and not autoObbyEnabled then break end
            if waypoint.Action == Enum.PathWaypointAction.Jump then
                humanoid.Jump = true
            end
            humanoid:MoveTo(waypoint.Position)
            humanoid.MoveToFinished:Wait()
        end
    else
        humanoid:MoveTo(targetPosition)
        humanoid.MoveToFinished:Wait()
    end
end

local function doAutoObby()
    while autoObbyEnabled do
        for i = 1, 20 do
            if not autoObbyEnabled then break end
            local obbyName = "obby"
            if i > 1 then
                obbyName = obbyName .. tostring(i)
            end
            
            local obbyFolder = workspace:FindFirstChild(obbyName)
            if obbyFolder then
                local obbyInner = obbyFolder:FindFirstChild("obby")
                if obbyInner then
                    local target = obbyInner:FindFirstChild("GetCash")
                    if target then
                        walkTo(target.Position)
                        task.wait(1)
                    end
                end
            end
        end
        task.wait(1)
    end
end

local function doAutoBridge()
    while autoBridgeEnabled do
        local teamName = LocalPlayer:GetAttribute("TeamName")
        
        if not teamName or teamName == "" then
            if not autoObbyEnabled then
                autoObbyEnabled = true
                task.spawn(doAutoObby)
            end
            task.wait(2)
            continue
        else
            autoObbyEnabled = false
        end

        local raceFolder = getRealRaceFolder()
        if not raceFolder then
            task.wait(1)
            continue
        end

        local base = raceFolder:FindFirstChild(teamName)
        if not base then
            task.wait(1)
            continue
        end

        local bridge1 = base:FindFirstChild("Bridge1")
        local bridge2 = base:FindFirstChild("Bridge2")
        local bridge3 = base:FindFirstChild("Bridge3")
        local bridges = {bridge1, bridge2, bridge3}
        local currentBridgeIndex = 1
        local currentBridge = bridges[currentBridgeIndex]

        if not currentBridge then
            task.wait(1)
            continue
        end

        local giver = getClosestGiver(base, currentBridge)
        local character = LocalPlayer.Character
        if not character then
            task.wait(1)
            continue
        end

        local hasTool = character:FindFirstChild("BrickTool")
        if not hasTool then
            if giver then
                walkTo(giver:GetPivot().Position)
                task.wait(0.5)
            end
        else
            local mixedSection = nil
            local emptySection = nil

            for i = 1, 10 do
                local section = currentBridge:FindFirstChild(tostring(i))
                if section then
                    local hasBrick = false
                    local hasPreview = false
                    local previewPart = nil
                    local brickPart = nil

                    for _, part in ipairs(section:GetChildren()) do
                        if part.Name == "Brick" then
                            hasBrick = true
                            brickPart = part
                        elseif part.Name == "BlockPreview" then
                            hasPreview = true
                            previewPart = part
                        end
                    end

                    if hasBrick and hasPreview then
                        if not mixedSection then
                            mixedSection = {index = i, preview = previewPart, brick = brickPart, instance = section}
                        end
                    elseif hasPreview and not hasBrick then
                        if not emptySection and not mixedSection then
                            emptySection = {index = i, instance = section}
                        end
                    end
                end
            end

            if mixedSection then
                walkTo(mixedSection.brick.Position)
            elseif emptySection then
                local prevIndex = emptySection.index - 1
                local prevSection = currentBridge:FindFirstChild(tostring(prevIndex))
                if prevSection then
                    local parts = prevSection:GetChildren()
                    if #parts > 0 then
                        walkTo(parts[#parts].Position)
                    end
                else
                    walkTo(emptySection.instance:GetPivot().Position)
                end
            else
                currentBridgeIndex = currentBridgeIndex + 1
                if currentBridgeIndex > 3 then
                    currentBridgeIndex = 1
                end
            end
        end
        task.wait(0.1)
    end
end

Tab:AddToggle({
    Name = "Auto Bridge & Obby (Main Switch)",
    Default = false,
    Callback = function(Value)
        autoBridgeEnabled = Value
        if Value then
            task.spawn(doAutoBridge)
        end
    end
})

OrionLib:Init()
