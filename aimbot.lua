local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local UserInputService = game:GetService("UserInputService")

-- ✅ Settings
local aimbotEnabled = false
local visibilityCheck = false
local aimAtHead = false
local teamCheck = false

-- 🧠 Utility: Check if target is visible (basic raycast)
local function isTargetVisible(targetPlayer)
    if not targetPlayer.Character then return false end
    local targetPart = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not targetPart then return false end

    local origin = Camera.CFrame.Position
    local direction = (targetPart.Position - origin).Unit * 1000
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character}
    local result = workspace:Raycast(origin, direction, raycastParams)

    if result and result.Instance then
        if result.Instance:IsDescendantOf(targetPlayer.Character) then
            return true -- Direct line of sight
        else
            return false -- Something else is blocking
        end
    end

    return true -- No obstruction
end

-- 🔍 Find closest player with all checks
local function getClosestPlayer()
    local closest = nil
    local shortestDistance = math.huge

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
            if not humanoid or humanoid.Health <= 0 then
                continue
            end

            if teamCheck and player.Team == LocalPlayer.Team then
                continue
            end

            local targetPart = player.Character.HumanoidRootPart
            local distance = (targetPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude

            if distance < shortestDistance then
                if visibilityCheck then
                    if isTargetVisible(player) then
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
            local humanoid = target.Character:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid.Health > 0 then
                local targetPart
                if aimAtHead then
                    targetPart = target.Character:FindFirstChild("Head") or target.Character:FindFirstChild("HumanoidRootPart")
                else
                    targetPart = target.Character:FindFirstChild("HumanoidRootPart")
                end

                if targetPart then
                    Camera.CFrame = CFrame.new(Camera.CFrame.Position, targetPart.Position)
                end
            end
        end
    end
end)

-- 📱 UI Setup
local ScreenGui = Instance.new("ScreenGui", LocalPlayer:WaitForChild("PlayerGui"))
ScreenGui.Name = "AimbotUI"

-- Container frame (for dragging and layout)
local container = Instance.new("Frame")
container.Size = UDim2.new(0, 260, 0, 160)
container.Position = UDim2.new(0, 20, 0, 20)
container.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
container.BorderSizePixel = 0
container.Parent = ScreenGui
container.Active = true
container.Draggable = true

-- Title label
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 25)
title.BackgroundTransparency = 1
title.Text = "Mobile Aimbot Settings"
title.Font = Enum.Font.SourceSansBold
title.TextSize = 20
title.TextColor3 = Color3.new(1,1,1)
title.Parent = container

-- 🟢 Aimbot Toggle Button
local toggleButton = Instance.new("TextButton")
toggleButton.Size = UDim2.new(0, 220, 0, 35)
toggleButton.Position = UDim2.new(0, 20, 0, 35)
toggleButton.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
toggleButton.TextColor3 = Color3.new(1, 1, 1)
toggleButton.Font = Enum.Font.SourceSansBold
toggleButton.TextSize = 20
toggleButton.Text = "Aimbot: OFF"
toggleButton.Parent = container

toggleButton.MouseButton1Click:Connect(function()
    aimbotEnabled = not aimbotEnabled
    toggleButton.Text = "Aimbot: " .. (aimbotEnabled and "ON" or "OFF")
    toggleButton.BackgroundColor3 = aimbotEnabled and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(150, 0, 0)
end)

-- ✅ Visibility Check Toggle
local visibilityCheckbox = Instance.new("TextButton")
visibilityCheckbox.Size = UDim2.new(0, 220, 0, 35)
visibilityCheckbox.Position = UDim2.new(0, 20, 0, 75)
visibilityCheckbox.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
visibilityCheckbox.TextColor3 = Color3.new(1, 1, 1)
visibilityCheckbox.Font = Enum.Font.SourceSansBold
visibilityCheckbox.TextSize = 20
visibilityCheckbox.Text = "Visibility Check: OFF"
visibilityCheckbox.Parent = container

visibilityCheckbox.MouseButton1Click:Connect(function()
    visibilityCheck = not visibilityCheck
    visibilityCheckbox.Text = "Visibility Check: " .. (visibilityCheck and "ON" or "OFF")
    visibilityCheckbox.BackgroundColor3 = visibilityCheck and Color3.fromRGB(50, 120, 200) or Color3.fromRGB(30, 30, 30)
end)

-- 🎯 Aim at Head Toggle
local aimHeadCheckbox = Instance.new("TextButton")
aimHeadCheckbox.Size = UDim2.new(0, 220, 0, 35)
aimHeadCheckbox.Position = UDim2.new(0, 20, 0, 115)
aimHeadCheckbox.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
aimHeadCheckbox.TextColor3 = Color3.new(1, 1, 1)
aimHeadCheckbox.Font = Enum.Font.SourceSansBold
aimHeadCheckbox.TextSize = 20
aimHeadCheckbox.Text = "Aim at Head: OFF"
aimHeadCheckbox.Parent = container

aimHeadCheckbox.MouseButton1Click:Connect(function()
    aimAtHead = not aimAtHead
    aimHeadCheckbox.Text = "Aim at Head: " .. (aimAtHead and "ON" or "OFF")
    aimHeadCheckbox.BackgroundColor3 = aimAtHead and Color3.fromRGB(50, 120, 200) or Color3.fromRGB(30, 30, 30)
end)

-- 🛡️ Team Check Toggle
local teamCheckbox = Instance.new("TextButton")
teamCheckbox.Size = UDim2.new(0, 220, 0, 35)
teamCheckbox.Position = UDim2.new(0, 20, 0, 155)
teamCheckbox.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
teamCheckbox.TextColor3 = Color3.new(1, 1, 1)
teamCheckbox.Font = Enum.Font.SourceSansBold
teamCheckbox.TextSize = 20
teamCheckbox.Text = "Ignore Team: OFF"
teamCheckbox.Parent = container

teamCheckbox.MouseButton1Click:Connect(function()
    teamCheck = not teamCheck
    teamCheckbox.Text = "Ignore Team: " .. (teamCheck and "ON" or "OFF")
    teamCheckbox.BackgroundColor3 = teamCheck and Color3.fromRGB(50, 120, 200) or Color3.fromRGB(30, 30, 30)
end)

-- Adjust container size to fit all buttons
container.Size = UDim2.new(0, 260, 0, 200)
