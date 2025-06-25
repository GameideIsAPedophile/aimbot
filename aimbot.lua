local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Settings
local aimbotEnabled = false
local visibilityCheck = false
local aimAtHead = false
local teamCheck = false

-- Utility: Check if target is visible (basic raycast)
local function isTargetVisible(targetPosition)
    local origin = Camera.CFrame.Position
    local direction = (targetPosition - origin).Unit * 1000
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character}
    local result = workspace:Raycast(origin, direction, raycastParams)

    if result and result.Instance then
        local hitPart = result.Instance
        if hitPart:IsDescendantOf(workspace:FindFirstChildOfClass("Model")) then
            return false -- Something is blocking
        end
    end

    return true
end

-- Find closest player considering options
local function getClosestPlayer()
    local closest = nil
    local shortestDistance = math.huge

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            if teamCheck and player.Team == LocalPlayer.Team then
                -- Skip teammates if enabled
                goto continue
            end

            local targetPart = aimAtHead and player.Character:FindFirstChild("Head") or player.Character.HumanoidRootPart
            if not targetPart then goto continue end

            local distance = (targetPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude

            if distance < shortestDistance then
                if visibilityCheck then
                    if isTargetVisible(targetPart.Position) then
                        closest = player
                        shortestDistance = distance
                    end
                else
                    closest = player
                    shortestDistance = distance
                end
            end
        end
        ::continue::
    end

    return closest
end

-- Aimbot logic
RunService.RenderStepped:Connect(function()
    if aimbotEnabled then
        local target = getClosestPlayer()
        if target and target.Character then
            local targetPart = aimAtHead and target.Character:FindFirstChild("Head") or target.Character:FindFirstChild("HumanoidRootPart")
            if targetPart then
                Camera.CFrame = CFrame.new(Camera.CFrame.Position, targetPart.Position)
            end
        end
    end
end)

-- GUI Setup
local ScreenGui = Instance.new("ScreenGui", LocalPlayer:WaitForChild("PlayerGui"))
ScreenGui.Name = "AimbotUI"

-- Main draggable frame
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 250, 0, 170)
mainFrame.Position = UDim2.new(0, 20, 0, 20)
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = ScreenGui
mainFrame.Active = true
mainFrame.Draggable = true

-- Helper function to create buttons
local function createButton(text, position, parent)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 220, 0, 30)
    btn.Position = position
    btn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 18
    btn.Text = text
    btn.Parent = parent
    return btn
end

-- Aimbot Toggle Button
local toggleButton = createButton("Aimbot: OFF", UDim2.new(0, 10, 0, 10), mainFrame)
toggleButton.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
toggleButton.MouseButton1Click:Connect(function()
    aimbotEnabled = not aimbotEnabled
    toggleButton.Text = "Aimbot: " .. (aimbotEnabled and "ON" or "OFF")
    toggleButton.BackgroundColor3 = aimbotEnabled and Color3.fromRGB(0, 200, 0) or Color3.fromRGB(150, 0, 0)
end)

-- Visibility Check Button
local visibilityCheckbox = createButton("Visibility Check: OFF", UDim2.new(0, 10, 0, 50), mainFrame)
visibilityCheckbox.MouseButton1Click:Connect(function()
    visibilityCheck = not visibilityCheck
    visibilityCheckbox.Text = "Visibility Check: " .. (visibilityCheck and "ON" or "OFF")
    visibilityCheckbox.BackgroundColor3 = visibilityCheck and Color3.fromRGB(50, 120, 200) or Color3.fromRGB(30, 30, 30)
end)

-- Aim at Head Button
local headAimCheckbox = createButton("Aim at Head: OFF", UDim2.new(0, 10, 0, 90), mainFrame)
headAimCheckbox.MouseButton1Click:Connect(function()
    aimAtHead = not aimAtHead
    headAimCheckbox.Text = "Aim at Head: " .. (aimAtHead and "ON" or "OFF")
    headAimCheckbox.BackgroundColor3 = aimAtHead and Color3.fromRGB(50, 120, 200) or Color3.fromRGB(30, 30, 30)
end)

-- Ignore Teammates Button
local teamCheckCheckbox = createButton("Ignore Teammates: OFF", UDim2.new(0, 10, 0, 130), mainFrame)
teamCheckCheckbox.MouseButton1Click:Connect(function()
    teamCheck = not teamCheck
    teamCheckCheckbox.Text = "Ignore Teammates: " .. (teamCheck and "ON" or "OFF")
    teamCheckCheckbox.BackgroundColor3 = teamCheck and Color3.fromRGB(50, 120, 200) or Color3.fromRGB(30, 30, 30)
end)
