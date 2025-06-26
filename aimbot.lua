local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Cleanup old GUI if exists
local oldGui = PlayerGui:FindFirstChild("AimbotUI")
if oldGui then oldGui:Destroy() end

-- State variables
local aimbotEnabled = false
local visibilityCheck = false
local aimAtHead = false
local ignoreTeammates = false
local expanded = false
local targetIndex = 1

-- Create main ScreenGui
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AimbotUI"
ScreenGui.Parent = PlayerGui
ScreenGui.ResetOnSpawn = false

-- Main draggable frame (starts small, expands on toggle)
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 50, 0, 50)
mainFrame.Position = UDim2.new(0, 20, 0, 20)
mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
mainFrame.BorderSizePixel = 2
mainFrame.BorderColor3 = Color3.fromRGB(80, 80, 80)
mainFrame.Parent = ScreenGui

-- Dragging logic
local dragging = false
local dragInput, dragStart, startPos

mainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = mainFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

mainFrame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and input == dragInput then
        local delta = input.Position - dragStart
        local newPos = UDim2.new(
            startPos.X.Scale,
            math.clamp(startPos.X.Offset + delta.X, 0, workspace.CurrentCamera.ViewportSize.X - mainFrame.AbsoluteSize.X),
            startPos.Y.Scale,
            math.clamp(startPos.Y.Offset + delta.Y, 0, workspace.CurrentCamera.ViewportSize.Y - mainFrame.AbsoluteSize.Y)
        )
        mainFrame.Position = newPos
    end
end)

-- Small toggle button to expand/collapse the GUI
local toggleButton = Instance.new("TextButton")
toggleButton.Size = UDim2.new(1, 0, 1, 0) -- fills mainFrame
toggleButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
toggleButton.Text = ">"
toggleButton.TextColor3 = Color3.new(1,1,1)
toggleButton.Font = Enum.Font.SourceSansBold
toggleButton.TextSize = 30
toggleButton.Parent = mainFrame

-- Container for expanded buttons (hidden by default)
local container = Instance.new("Frame")
container.Size = UDim2.new(0, 220, 0, 280)
container.Position = UDim2.new(1, 10, 0, 0)
container.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
container.BorderSizePixel = 1
container.BorderColor3 = Color3.fromRGB(70, 70, 70)
container.Visible = false
container.Parent = mainFrame

-- Helper to create toggle buttons
local function createToggleButton(text, posY)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 200, 0, 40)
    btn.Position = UDim2.new(0, 10, 0, posY)
    btn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 20
    btn.Text = text
    btn.Parent = container
    return btn
end

-- Toggle buttons
local aimbotBtn = createToggleButton("Aimbot: OFF", 10)
local visibilityBtn = createToggleButton("Visibility Check: OFF", 60)
local headAimBtn = createToggleButton("Aim at Head: OFF", 110)
local ignoreTeamBtn = createToggleButton("Ignore Teammates: OFF", 160)

-- Target switch buttons
local prevTargetBtn = Instance.new("TextButton")
prevTargetBtn.Size = UDim2.new(0, 90, 0, 40)
prevTargetBtn.Position = UDim2.new(0, 10, 0, 210)
prevTargetBtn.BackgroundColor3 = Color3.fromRGB(120, 120, 120)
prevTargetBtn.TextColor3 = Color3.new(1,1,1)
prevTargetBtn.Font = Enum.Font.SourceSansBold
prevTargetBtn.TextSize = 20
prevTargetBtn.Text = "< Prev"
prevTargetBtn.Parent = container

local nextTargetBtn = Instance.new("TextButton")
nextTargetBtn.Size = UDim2.new(0, 90, 0, 40)
nextTargetBtn.Position = UDim2.new(0, 120, 0, 210)
nextTargetBtn.BackgroundColor3 = Color3.fromRGB(120, 120, 120)
nextTargetBtn.TextColor3 = Color3.new(1,1,1)
nextTargetBtn.Font = Enum.Font.SourceSansBold
nextTargetBtn.TextSize = 20
nextTargetBtn.Text = "Next >"
nextTargetBtn.Parent = container

local targetLabel = Instance.new("TextLabel")
targetLabel.Size = UDim2.new(0, 200, 0, 30)
targetLabel.Position = UDim2.new(0, 10, 0, 260)
targetLabel.BackgroundTransparency = 1
targetLabel.TextColor3 = Color3.new(1, 1, 1)
targetLabel.Font = Enum.Font.SourceSansBold
targetLabel.TextSize = 20
targetLabel.Text = "Target: None"
targetLabel.Parent = container

-- Helper function to update button text and colors
local function updateButtonState()
    aimbotBtn.Text = "Aimbot: " .. (aimbotEnabled and "ON" or "OFF")
    aimbotBtn.BackgroundColor3 = aimbotEnabled and Color3.fromRGB(0, 200, 0) or Color3.fromRGB(150, 0, 0)

    visibilityBtn.Text = "Visibility Check: " .. (visibilityCheck and "ON" or "OFF")
    visibilityBtn.BackgroundColor3 = visibilityCheck and Color3.fromRGB(50, 120, 200) or Color3.fromRGB(30, 30, 30)

    headAimBtn.Text = "Aim at Head: " .. (aimAtHead and "ON" or "OFF")
    headAimBtn.BackgroundColor3 = aimAtHead and Color3.fromRGB(50, 120, 200) or Color3.fromRGB(30, 30, 30)

    ignoreTeamBtn.Text = "Ignore Teammates: " .. (ignoreTeammates and "ON" or "OFF")
    ignoreTeamBtn.BackgroundColor3 = ignoreTeammates and Color3.fromRGB(50, 120, 200) or Color3.fromRGB(30, 30, 30)
end

-- Get list of valid targets considering settings
local function getValidTargets()
    local valid = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 and player.Character:FindFirstChild("HumanoidRootPart") then
            if ignoreTeammates then
                local lpTeam = LocalPlayer.Team
                local pTeam = player.Team
                if lpTeam and pTeam and lpTeam == pTeam then
                    -- Same team, skip
                else
                    table.insert(valid, player)
                end
            else
                table.insert(valid, player)
            end
        end
    end
    return valid
end

-- Check visibility of target
local function isTargetVisible(targetPosition)
    local origin = Camera.CFrame.Position
    local direction = (targetPosition - origin).Unit * 1000
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character}
    local result = workspace:Raycast(origin, direction, raycastParams)

    if result and result.Instance then
        if result.Instance:IsDescendantOf(workspace:FindFirstChildOfClass("Model")) then
            -- Hit something blocking target
            return false
        end
    end
    return true
end

-- Get current target player or nil
local function getCurrentTarget()
    local targets = getValidTargets()
    if #targets == 0 then return nil end
    -- Clamp index
    if targetIndex > #targets then
        targetIndex = 1
    elseif targetIndex < 1 then
        targetIndex = #targets
    end
    return targets[targetIndex], targets
end

-- Update the target label text
local function updateTargetLabel()
    local target = getCurrentTarget()
    if target then
        targetLabel.Text = "Target: " .. target.Name
    else
        targetLabel.Text = "Target: None"
    end
end

-- Button Click Events

toggleButton.MouseButton1Click:Connect(function()
    expanded = not expanded
    container.Visible = expanded
    toggleButton.Text = expanded and "<" or ">"
    if expanded then
        mainFrame.Size = UDim2.new(0, 280, 0, 280)
    else
        mainFrame.Size = UDim2.new(0, 50, 0, 50)
    end
end)

aimbotBtn.MouseButton1Click:Connect(function()
    aimbotEnabled = not aimbotEnabled
    updateButtonState()
end)

visibilityBtn.MouseButton1Click:Connect(function()
    visibilityCheck = not visibilityCheck
    updateButtonState()
end)

headAimBtn.MouseButton1Click:Connect(function()
    aimAtHead = not aimAtHead
    updateButtonState()
end)

ignoreTeamBtn.MouseButton1Click:Connect(function()
    ignoreTeammates = not ignoreTeammates
    updateButtonState()
    targetIndex = 1 -- reset target index to avoid invalid target
    updateTargetLabel()
end)

prevTargetBtn.MouseButton1Click:Connect(function()
    targetIndex = targetIndex - 1
    updateTargetLabel()
end)

nextTargetBtn.MouseButton1Click:Connect(function()
    targetIndex = targetIndex + 1
    updateTargetLabel()
end)

-- RunService: Aimbot logic
RunService.RenderStepped:Connect(function()
    if aimbotEnabled then
        local target = getCurrentTarget()
        if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") and target.Character:FindFirstChild("Humanoid") and target.Character.Humanoid.Health > 0 then
            local targetPart = aimAtHead and target.Character:FindFirstChild("Head") or target.Character:FindFirstChild("HumanoidRootPart")
            if targetPart then
                if visibilityCheck then
                    if not isTargetVisible(targetPart.Position) then
                        return
                    end
                end
                -- Aim camera
                Camera.CFrame = CFrame.new(Camera.CFrame.Position, targetPart.Position)
            end
        end
    end
end)

-- Initial update
updateButtonState()
updateTargetLabel()
