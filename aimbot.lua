local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Settings
local aimbotEnabled = false
local visibilityCheck = false
local aimAtHead = false
local ignoreTeammates = false

local targetList = {}
local currentTargetIndex = 0

-- UI creation
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AimbotUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local container = Instance.new("Frame")
container.Size = UDim2.new(0, 40, 0, 40)
container.Position = UDim2.new(0, 20, 0, 20)
container.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
container.BorderSizePixel = 0
container.Parent = ScreenGui
container.Active = true
container.Draggable = true

local retractBtn = Instance.new("TextButton")
retractBtn.Size = UDim2.new(1, 0, 1, 0)
retractBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
retractBtn.TextColor3 = Color3.new(1, 1, 1)
retractBtn.Font = Enum.Font.SourceSansBold
retractBtn.TextSize = 20
retractBtn.Text = "+"
retractBtn.Parent = container

local expanded = Instance.new("Frame")
expanded.Size = UDim2.new(0, 220, 0, 230)
expanded.Position = UDim2.new(1, 10, 0, 0)
expanded.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
expanded.BorderSizePixel = 0
expanded.Visible = false
expanded.Parent = container

-- Utility to create toggle buttons
local function createToggleButton(text, posY)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 200, 0, 35)
    btn.Position = UDim2.new(0, 10, 0, posY)
    btn.BackgroundColor3 = Color3.fromRGB(100, 0, 0)
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 18
    btn.Text = text
    btn.Parent = expanded
    return btn
end

local aimbotBtn = createToggleButton("Aimbot: OFF", 10)
local visibilityBtn = createToggleButton("Visibility Check: OFF", 55)
local headAimBtn = createToggleButton("Aim At Head: OFF", 100)
local ignoreTeamBtn = createToggleButton("Ignore Teammates: OFF", 145)

local targetLabel = Instance.new("TextLabel")
targetLabel.Size = UDim2.new(0, 200, 0, 25)
targetLabel.Position = UDim2.new(0, 10, 0, 190)
targetLabel.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
targetLabel.TextColor3 = Color3.new(1, 1, 1)
targetLabel.Font = Enum.Font.SourceSansBold
targetLabel.TextSize = 16
targetLabel.Text = "Target: None"
targetLabel.Parent = expanded

local prevTargetBtn = Instance.new("TextButton")
prevTargetBtn.Size = UDim2.new(0, 95, 0, 25)
prevTargetBtn.Position = UDim2.new(0, 10, 0, 220)
prevTargetBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
prevTargetBtn.TextColor3 = Color3.new(1, 1, 1)
prevTargetBtn.Font = Enum.Font.SourceSansBold
prevTargetBtn.TextSize = 16
prevTargetBtn.Text = "< Prev"
prevTargetBtn.Parent = expanded

local nextTargetBtn = Instance.new("TextButton")
nextTargetBtn.Size = UDim2.new(0, 95, 0, 25)
nextTargetBtn.Position = UDim2.new(0, 115, 0, 220)
nextTargetBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
nextTargetBtn.TextColor3 = Color3.new(1, 1, 1)
nextTargetBtn.Font = Enum.Font.SourceSansBold
nextTargetBtn.TextSize = 16
nextTargetBtn.Text = "Next >"
nextTargetBtn.Parent = expanded

-- Toggle GUI expand/retract
local function toggleGUI()
    if expanded.Visible then
        expanded.Visible = false
        container.Size = UDim2.new(0, 40, 0, 40)
        retractBtn.Text = "+"
    else
        refreshTargetList()
        updateTargetLabel()
        expanded.Visible = true
        container.Size = UDim2.new(0, 220, 0, 255)
        retractBtn.Text = "×"
    end
end

retractBtn.MouseButton1Click:Connect(toggleGUI)

-- Refresh target list filtered
function refreshTargetList()
    targetList = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 and player.Character:FindFirstChild("HumanoidRootPart") then
            if ignoreTeammates then
                if LocalPlayer.Team and player.Team and LocalPlayer.Team == player.Team then
                    -- skip teammates
                else
                    table.insert(targetList, player)
                end
            else
                table.insert(targetList, player)
            end
        end
    end
    if #targetList == 0 then
        currentTargetIndex = 0
    elseif currentTargetIndex == 0 or currentTargetIndex > #targetList then
        currentTargetIndex = 1
    end
end

-- Update target label
function updateTargetLabel()
    local target = getCurrentTarget()
    if target then
        targetLabel.Text = "Target: " .. target.Name
    else
        targetLabel.Text = "Target: None"
    end
end

-- Get current target
function getCurrentTarget()
    if #targetList == 0 or currentTargetIndex == 0 then return nil end
    return targetList[currentTargetIndex]
end

-- Switch target
function switchTarget(offset)
    if #targetList == 0 then
        currentTargetIndex = 0
        updateTargetLabel()
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

-- Check visibility function
local function isTargetVisible(targetPos, targetChar)
    local origin = Camera.CFrame.Position
    local direction = targetPos - origin
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character, targetChar}
    local raycastResult = workspace:Raycast(origin, direction, raycastParams)
    return (raycastResult == nil)
end

-- Button click handlers
aimbotBtn.MouseButton1Click:Connect(function()
    aimbotEnabled = not aimbotEnabled
    aimbotBtn.Text = "Aimbot: " .. (aimbotEnabled and "ON" or "OFF")
    aimbotBtn.BackgroundColor3 = aimbotEnabled and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(150, 0, 0)
end)

visibilityBtn.MouseButton1Click:Connect(function()
    visibilityCheck = not visibilityCheck
    visibilityBtn.Text = "Visibility Check: " .. (visibilityCheck and "ON" or "OFF")
    visibilityBtn.BackgroundColor3 = visibilityCheck and Color3.fromRGB(50, 120, 200) or Color3.fromRGB(100, 0, 0)
end)

headAimBtn.MouseButton1Click:Connect(function()
    aimAtHead = not aimAtHead
    headAimBtn.Text = "Aim At Head: " .. (aimAtHead and "ON" or "OFF")
    headAimBtn.BackgroundColor3 = aimAtHead and Color3.fromRGB(50, 120, 200) or Color3.fromRGB(100, 0, 0)
end)

ignoreTeamBtn.MouseButton1Click:Connect(function()
    ignoreTeammates = not ignoreTeammates
    ignoreTeamBtn.Text = "Ignore Teammates: " .. (ignoreTeammates and "ON" or "OFF")
    ignoreTeamBtn.BackgroundColor3 = ignoreTeammates and Color3.fromRGB(50, 120, 200) or Color3.fromRGB(100, 0, 0)
    refreshTargetList()
    updateTargetLabel()
end)

prevTargetBtn.MouseButton1Click:Connect(function()
    switchTarget(-1)
end)

nextTargetBtn.MouseButton1Click:Connect(function()
    switchTarget(1)
end)

-- Main aiming loop
RunService.RenderStepped:Connect(function()
    if not aimbotEnabled then return end
    refreshTargetList()
    local target = getCurrentTarget()
    if not target then return end
    local char = target.Character
    if not char then return end
    local humanoid = char:FindFirstChild("Humanoid")
    local rootPart = char:FindFirstChild("HumanoidRootPart")
    if not humanoid or humanoid.Health <= 0 or not rootPart then return end

    -- Choose aim position
    local aimPos
    if aimAtHead then
        local head = char:FindFirstChild("Head")
        if head then aimPos = head.Position else aimPos = rootPart.Position end
    else
        aimPos = rootPart.Position
    end

    if visibilityCheck and not isTargetVisible(aimPos, char) then
        -- Not visible, don't aim
        return
    end

    -- Aim smoothing (optional, here direct)
    local cameraCFrame = Camera.CFrame
    local direction = (aimPos - cameraCFrame.Position).Unit
    Camera.CFrame = CFrame.new(cameraCFrame.Position, cameraCFrame.Position + direction)
end)

-- Auto refresh targets every 1 second
spawn(function()
    while true do
        refreshTargetList()
        updateTargetLabel()
        wait(1)
    end
end)
