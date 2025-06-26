local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local UserInputService = game:GetService("UserInputService")

-- Settings variables
local aimbotEnabled = false
local visibilityCheck = false
local aimAtHead = false
local ignoreTeammates = false

local currentTargetIndex = 1
local targetList = {}

-- Utility function: Check if target is visible
local function isTargetVisible(targetPosition, targetCharacter)
    local origin = Camera.CFrame.Position
    local direction = targetPosition - origin
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character, targetCharacter}
    local result = workspace:Raycast(origin, direction, raycastParams)

    if result then
        return false
    end
    return true
end

-- Refresh target list filtered by alive and team settings
local function refreshTargetList()
    targetList = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 then
            if ignoreTeammates then
                if LocalPlayer.Team and player.Team and player.Team == LocalPlayer.Team then
                    -- Same team, skip
                else
                    table.insert(targetList, player)
                end
            else
                table.insert(targetList, player)
            end
        end
    end
    -- Reset currentTargetIndex if out of range
    if #targetList == 0 then
        currentTargetIndex = 0
    elseif currentTargetIndex > #targetList or currentTargetIndex == 0 then
        currentTargetIndex = 1
    end
end

-- Get current target player
local function getCurrentTarget()
    if #targetList == 0 then return nil end
    return targetList[currentTargetIndex]
end

-- Switch target by offset (+1 for next, -1 for prev)
local function switchTarget(offset)
    if #targetList == 0 then
        currentTargetIndex = 0
        return
    end
    currentTargetIndex = currentTargetIndex + offset
    if currentTargetIndex < 1 then
        currentTargetIndex = #targetList
    elseif currentTargetIndex > #targetList then
        currentTargetIndex = 1
    end
    updateTargetLabel()
end

-- UI Creation
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AimbotUI"
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- Draggable frame container (start retracted)
local container = Instance.new("Frame")
container.Size = UDim2.new(0, 40, 0, 40)
container.Position = UDim2.new(0, 20, 0, 20)
container.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
container.BorderSizePixel = 0
container.Parent = ScreenGui
container.Active = true
container.Draggable = true

-- Retract / expand button (small square)
local retractBtn = Instance.new("TextButton")
retractBtn.Size = UDim2.new(1, 0, 1, 0)
retractBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
retractBtn.TextColor3 = Color3.new(1,1,1)
retractBtn.Font = Enum.Font.SourceSansBold
retractBtn.TextSize = 18
retractBtn.Text = "+"
retractBtn.Parent = container

-- Expanded UI container (hidden by default)
local expanded = Instance.new("Frame")
expanded.Size = UDim2.new(0, 200, 0, 200)
expanded.Position = UDim2.new(1, 10, 0, 0)
expanded.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
expanded.BorderSizePixel = 0
expanded.Visible = false
expanded.Parent = container

-- Aimbot toggle button
local aimbotBtn = Instance.new("TextButton")
aimbotBtn.Size = UDim2.new(0, 180, 0, 35)
aimbotBtn.Position = UDim2.new(0, 10, 0, 10)
aimbotBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
aimbotBtn.TextColor3 = Color3.new(1,1,1)
aimbotBtn.Font = Enum.Font.SourceSansBold
aimbotBtn.TextSize = 18
aimbotBtn.Text = "Aimbot: OFF"
aimbotBtn.Parent = expanded

-- Visibility check toggle
local visibilityBtn = Instance.new("TextButton")
visibilityBtn.Size = UDim2.new(0, 180, 0, 35)
visibilityBtn.Position = UDim2.new(0, 10, 0, 50)
visibilityBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
visibilityBtn.TextColor3 = Color3.new(1,1,1)
visibilityBtn.Font = Enum.Font.SourceSansBold
visibilityBtn.TextSize = 18
visibilityBtn.Text = "Visibility Check: OFF"
visibilityBtn.Parent = expanded

-- Aim at head toggle
local headAimBtn = Instance.new("TextButton")
headAimBtn.Size = UDim2.new(0, 180, 0, 35)
headAimBtn.Position = UDim2.new(0, 10, 0, 90)
headAimBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
headAimBtn.TextColor3 = Color3.new(1,1,1)
headAimBtn.Font = Enum.Font.SourceSansBold
headAimBtn.TextSize = 18
headAimBtn.Text = "Aim At Head: OFF"
headAimBtn.Parent = expanded

-- Ignore teammates toggle
local ignoreTeamBtn = Instance.new("TextButton")
ignoreTeamBtn.Size = UDim2.new(0, 180, 0, 35)
ignoreTeamBtn.Position = UDim2.new(0, 10, 0, 130)
ignoreTeamBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
ignoreTeamBtn.TextColor3 = Color3.new(1,1,1)
ignoreTeamBtn.Font = Enum.Font.SourceSansBold
ignoreTeamBtn.TextSize = 18
ignoreTeamBtn.Text = "Ignore Teammates: OFF"
ignoreTeamBtn.Parent = expanded

-- Target label
local targetLabel = Instance.new("TextLabel")
targetLabel.Size = UDim2.new(0, 180, 0, 25)
targetLabel.Position = UDim2.new(0, 10, 0, 170)
targetLabel.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
targetLabel.TextColor3 = Color3.new(1,1,1)
targetLabel.Font = Enum.Font.SourceSansBold
targetLabel.TextSize = 16
targetLabel.Text = "Target: None"
targetLabel.Parent = expanded

-- Prev target button
local prevTargetBtn = Instance.new("TextButton")
prevTargetBtn.Size = UDim2.new(0, 85, 0, 25)
prevTargetBtn.Position = UDim2.new(0, 10, 0, 195)
prevTargetBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
prevTargetBtn.TextColor3 = Color3.new(1,1,1)
prevTargetBtn.Font = Enum.Font.SourceSansBold
prevTargetBtn.TextSize = 16
prevTargetBtn.Text = "< Prev"
prevTargetBtn.Parent = expanded

-- Next target button
local nextTargetBtn = Instance.new("TextButton")
nextTargetBtn.Size = UDim2.new(0, 85, 0, 25)
nextTargetBtn.Position = UDim2.new(0, 105, 0, 195)
nextTargetBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
nextTargetBtn.TextColor3 = Color3.new(1,1,1)
nextTargetBtn.Font = Enum.Font.SourceSansBold
nextTargetBtn.TextSize = 16
nextTargetBtn.Text = "Next >"
nextTargetBtn.Parent = expanded

-- Function to update the target label text
function updateTargetLabel()
    local target = getCurrentTarget()
    if target then
        targetLabel.Text = "Target: "..target.Name
    else
        targetLabel.Text = "Target: None"
    end
end

-- Toggle expanded/retracted GUI
local function toggleGUI()
    if expanded.Visible then
        expanded.Visible = false
        container.Size = UDim2.new(0, 40, 0, 40)
        retractBtn.Text = "+"
    else
        refreshTargetList()
        updateTargetLabel()
        expanded.Visible = true
        container.Size = UDim2.new(0, 220, 0, 230)
        retractBtn.Text = "×"
    end
end

-- Connect retractBtn click to toggle GUI
retractBtn.MouseButton1Click:Connect(toggleGUI)

-- Button toggles
aimbotBtn.MouseButton1Click:Connect(function()
    aimbotEnabled = not aimbotEnabled
    aimbotBtn.Text = "Aimbot: " .. (aimbotEnabled and "ON" or "OFF")
    aimbotBtn.BackgroundColor3 = aimbotEnabled and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(150, 0, 0)
end)

visibilityBtn.MouseButton1Click:Connect(function()
    visibilityCheck = not visibilityCheck
    visibilityBtn.Text = "Visibility Check: " .. (visibilityCheck and "ON" or "OFF")
    visibilityBtn.BackgroundColor3 = visibilityCheck and Color3.fromRGB(50, 120, 200) or Color3.fromRGB(30, 30, 30)
end)

headAimBtn.MouseButton1Click:Connect(function()
    aimAtHead = not aimAtHead
    headAimBtn.Text = "Aim At Head: " .. (aimAtHead and "ON" or "OFF")
    headAimBtn.BackgroundColor3 = aimAtHead and Color3.fromRGB(50, 120, 200) or Color3.fromRGB(30, 30, 30)
end)

ignoreTeamBtn.MouseButton1Click:Connect(function()
    ignoreTeammates = not ignoreTeammates
    ignoreTeamBtn.Text = "Ignore Teammates: " .. (ignoreTeammates and "ON" or "OFF")
    ignoreTeamBtn.BackgroundColor3 = ignoreTeammates and Color3.fromRGB(50, 120, 200) or Color3.fromRGB(30, 30, 30)
    refreshTargetList()
    updateTargetLabel()
end)

prevTargetBtn.MouseButton1Click:Connect(function()
    switchTarget(-1)
end)

nextTargetBtn.MouseButton1Click:Connect(function()
    switchTarget(1)
end)

-- Auto-refresh target list every 1 second
spawn(function()
    while true do
        refreshTarget
