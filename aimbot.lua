local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- ✅ Settings
local aimbotEnabled = false
local visibilityCheck = false
local aimAtHead = false
local ignoreTeam = false

-- Helper: Get team color (or nil)
local function getPlayerTeamColor(player)
    return player.TeamColor
end

-- 🧠 Check visibility ignoring local & target
local function isTargetVisible(targetCharacter)
    local origin = Camera.CFrame.Position
    local targetPart = targetCharacter:FindFirstChild(aimAtHead and "Head" or "HumanoidRootPart")
    if not targetPart then return false end
    local direction = (targetPart.Position - origin).Unit * (targetPart.Position - origin).Magnitude

    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character, targetCharacter}
    local result = workspace:Raycast(origin, direction, raycastParams)

    if not result then
        return true
    elseif result.Instance and result.Instance:IsDescendantOf(targetCharacter) then
        return true
    end

    return false
end

-- 🔍 Find closest valid player
local function getClosestPlayer()
    local closest = nil
    local shortestDistance = math.huge

    local localChar = LocalPlayer.Character
    if not localChar or not localChar:FindFirstChild("HumanoidRootPart") then return nil end
    local localHRP = localChar.HumanoidRootPart
    local localTeam = getPlayerTeamColor(LocalPlayer)

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            -- Skip teammates if option is on
            if ignoreTeam and getPlayerTeamColor(player) == localTeam then
                continue
            end

            local targetPart = player.Character:FindFirstChild(aimAtHead and "Head" or "HumanoidRootPart")
            if not targetPart then
                continue
            end

            local distance = (targetPart.Position - localHRP.Position).Magnitude

            if distance < shortestDistance then
                if visibilityCheck then
                    if isTargetVisible(player.Character) then
                        closest = player
                        shortestDistance = distance
                    end
                else
                    closest = player
                    shortestDistance = distance
                end
            end
        end
    end

    return closest
end

-- 🎯 Aimbot logic
RunService.RenderStepped:Connect(function()
    if aimbotEnabled then
        local target = getClosestPlayer()
        if target and target.Character then
            local targetPart = target.Character:FindFirstChild(aimAtHead and "Head" or "HumanoidRootPart")
            if targetPart then
                Camera.CFrame = CFrame.new(Camera.CFrame.Position, targetPart.Position)
            end
        end
    end
end)

-- 📱 GUI Setup for Samsung S21 size (1080x2400 scaled)
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AimbotUI"
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- Container frame (for dragging)
local container = Instance.new("Frame")
container.Size = UDim2.new(0, 220, 0, 170)
container.Position = UDim2.new(0, 20, 0.75, 0)
container.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
container.BorderSizePixel = 0
container.Active = true
container.Draggable = true
container.Parent = ScreenGui

-- Title Label
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 30)
title.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
title.TextColor3 = Color3.new(1, 1, 1)
title.Font = Enum.Font.SourceSansBold
title.Text = "Mobile Aimbot"
title.Parent = container

-- 🟢 Toggle Button
local toggleButton = Instance.new("TextButton")
toggleButton.Size = UDim2.new(0.9, 0, 0, 35)
toggleButton.Position = UDim2.new(0.05, 0, 0.22, 0)
toggleButton.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
toggleButton.TextColor3 = Color3.new(1, 1, 1)
toggleButton.Font = Enum.Font.SourceSansBold
toggleButton.Text = "Aimbot: OFF"
toggleButton.Parent = container

toggleButton.MouseButton1Click:Connect(function()
    aimbotEnabled = not aimbotEnabled
    toggleButton.Text = "Aimbot: " .. (aimbotEnabled and "ON" or "OFF")
    toggleButton.BackgroundColor3 = aimbotEnabled and Color3.fromRGB(0, 200, 0) or Color3.fromRGB(150, 0, 0)
end)

-- ✅ Visibility Checkbox
local visibilityCheckbox = Instance.new("TextButton")
visibilityCheckbox.Size = UDim2.new(0.9, 0, 0, 30)
visibilityCheckbox.Position = UDim2.new(0.05, 0, 0.45, 0)
visibilityCheckbox.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
visibilityCheckbox.TextColor3 = Color3.new(1, 1, 1)
visibilityCheckbox.Font = Enum.Font.SourceSansBold
visibilityCheckbox.Text = "Visibility Check: OFF"
visibilityCheckbox.Parent = container

visibilityCheckbox.MouseButton1Click:Connect(function()
    visibilityCheck = not visibilityCheck
    visibilityCheckbox.Text = "Visibility Check: " .. (visibilityCheck and "ON" or "OFF")
    visibilityCheckbox.BackgroundColor3 = visibilityCheck and Color3.fromRGB(50, 120, 200) or Color3.fromRGB(30, 30, 30)
end)

-- 🟡 Aim at Head Checkbox
local aimAtHeadCheckbox = Instance.new("TextButton")
aimAtHeadCheckbox.Size = UDim2.new(0.9, 0, 0, 30)
aimAtHeadCheckbox.Position = UDim2.new(0.05, 0, 0.60, 0)
aimAtHeadCheckbox.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
aimAtHeadCheckbox.TextColor3 = Color3.new(1, 1, 1)
aimAtHeadCheckbox.Font = Enum.Font.SourceSansBold
aimAtHeadCheckbox.Text = "Aim at Head: OFF"
aimAtHeadCheckbox.Parent = container

aimAtHeadCheckbox.MouseButton1Click:Connect(function()
    aimAtHead = not aimAtHead
    aimAtHeadCheckbox.Text = "Aim at Head: " .. (aimAtHead and "ON" or "OFF")
    aimAtHeadCheckbox.BackgroundColor3 = aimAtHead and Color3.fromRGB(50, 120, 200) or Color3.fromRGB(30, 30, 30)
end)

-- 🔴 Ignore Team Checkbox
local ignoreTeamCheckbox = Instance.new("TextButton")
ignoreTeamCheckbox.Size = UDim2.new(0.9, 0, 0, 30)
ignoreTeamCheckbox.Position = UDim2.new(0.05, 0, 0.75, 0)
ignoreTeamCheckbox.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
ignoreTeamCheckbox.TextColor3 = Color3.new(1, 1, 1)
ignoreTeamCheckbox.Font = Enum.Font.SourceSansBold
ignoreTeamCheckbox.Text = "Ignore Team: OFF"
ignoreTeamCheckbox.Parent = container

ignoreTeamCheckbox.MouseButton1Click:Connect(function()
    ignoreTeam = not ignoreTeam
    ignoreTeamCheckbox.Text = "Ignore Team: " .. (ignoreTeam and "ON" or "OFF")
    ignoreTeamCheckbox.BackgroundColor3 = ignoreTeam and Color3.fromRGB(50, 120, 200) or Color3.fromRGB(30, 30, 30)
end)
