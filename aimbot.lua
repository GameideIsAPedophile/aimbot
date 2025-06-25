local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local UserInputService = game:GetService("UserInputService")

-- ✅ Settings
local aimbotEnabled = false
local visibilityCheck = false

-- 🧠 Utility: Check if target is visible (raycast ignores both local and target characters)
local function isTargetVisible(targetCharacter)
    local origin = Camera.CFrame.Position
    local targetPart = targetCharacter:FindFirstChild("HumanoidRootPart")
    if not targetPart then return false end
    local direction = (targetPart.Position - origin).Unit * (targetPart.Position - origin).Magnitude

    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character, targetCharacter}
    local result = workspace:Raycast(origin, direction, raycastParams)

    -- If ray hits nothing or hits part inside targetCharacter, target is visible
    if not result then
        return true
    elseif result.Instance and result.Instance:IsDescendantOf(targetCharacter) then
        return true
    end

    return false
end

-- 🔍 Find closest player
local function getClosestPlayer()
    local closest = nil
    local shortestDistance = math.huge

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local targetPart = player.Character.HumanoidRootPart
            local localPart = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if not localPart then return nil end

            local distance = (targetPart.Position - localPart.Position).Magnitude

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
        if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
            local targetPos = target.Character.HumanoidRootPart.Position
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, targetPos)
        end
    end
end)

-- 📱 UI Setup
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AimbotUI"
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- 🟢 Toggle Button
local toggleButton = Instance.new("TextButton")
toggleButton.Size = UDim2.new(0, 130, 0, 40)
toggleButton.Position = UDim2.new(0, 20, 0.85, 0)
toggleButton.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
toggleButton.TextColor3 = Color3.new(1, 1, 1)
toggleButton.Font = Enum.Font.SourceSansBold
toggleButton.Text = "Aimbot: OFF"
toggleButton.Parent = ScreenGui

toggleButton.MouseButton1Click:Connect(function()
    aimbotEnabled = not aimbotEnabled
    toggleButton.Text = "Aimbot: " .. (aimbotEnabled and "ON" or "OFF")
    toggleButton.BackgroundColor3 = aimbotEnabled and Color3.fromRGB(0, 200, 0) or Color3.fromRGB(150, 0, 0)
end)

-- ✅ Visibility Checkbox
local visibilityCheckbox = Instance.new("TextButton")
visibilityCheckbox.Size = UDim2.new(0, 200, 0, 40)
visibilityCheckbox.Position = UDim2.new(0, 20, 0.9, 0)
visibilityCheckbox.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
visibilityCheckbox.TextColor3 = Color3.new(1, 1, 1)
visibilityCheckbox.Font = Enum.Font.SourceSansBold
visibilityCheckbox.Text = "Visibility Check: OFF"
visibilityCheckbox.Parent = ScreenGui

visibilityCheckbox.MouseButton1Click:Connect(function()
    visibilityCheck = not visibilityCheck
    visibilityCheckbox.Text = "Visibility Check: " .. (visibilityCheck and "ON" or "OFF")
    visibilityCheckbox.BackgroundColor3 = visibilityCheck and Color3.fromRGB(50, 120, 200) or Color3.fromRGB(30, 30, 30)
end)
