local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Settings
local aimbotEnabled = false
local visibilityCheck = false
local ignoreTeammates = false
local aimAtHead = false

local targetList = {}
local currentTargetIndex = 1

-- Utility functions
local function isAlive(character)
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    return humanoid and humanoid.Health > 0
end

local function isTargetVisible(targetPosition)
    local origin = Camera.CFrame.Position
    local direction = (targetPosition - origin).Unit * 1000
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character}
    local result = workspace:Raycast(origin, direction, raycastParams)

    if result and result.Instance then
        if result.Instance:IsDescendantOf(LocalPlayer.Character) then
            return true
        end
        for _, player in ipairs(Players:GetPlayers()) do
            if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                if result.Instance:IsDescendantOf(player.Character) then
                    return true
                end
            end
        end
        return false
    end
    return true
end

local function buildTargetList()
    targetList = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") and isAlive(player.Character) then
            if ignoreTeammates then
                if player.Team ~= LocalPlayer.Team then
                    if not visibilityCheck or isTargetVisible(player.Character.HumanoidRootPart.Position) then
                        table.insert(targetList, player)
                    end
                end
            else
                if not visibilityCheck or isTargetVisible(player.Character.HumanoidRootPart.Position) then
                    table.insert(targetList, player)
                end
            end
        end
    end
    table.sort(targetList, function(a,b)
        local aPos = a.Character.HumanoidRootPart.Position
        local bPos = b.Character.HumanoidRootPart.Position
        local lpPos = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character.HumanoidRootPart.Position or Vector3.new()
        return (aPos - lpPos).Magnitude < (bPos - lpPos).Magnitude
    end)
    if currentTargetIndex > #targetList then
        currentTargetIndex = 1
    end
end

local function getCurrentTarget()
    if #targetList == 0 then return nil end
    return targetList[currentTargetIndex]
end

local function aimAtTarget(target)
    if not (target and target.Character and target.Character:FindFirstChild("HumanoidRootPart")) then return end
    if not isAlive(target.Character) then return end
    local targetPart = aimAtHead and target.Character:FindFirstChild("Head") or target.Character.HumanoidRootPart
    if not targetPart then return end
    Camera.CFrame = CFrame.new(Camera.CFrame.Position, targetPart.Position)
end

-- GUI Setup
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Prevent duplicates on respawn
if PlayerGui:FindFirstChild("AimbotUI") then
    PlayerGui.AimbotUI:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AimbotUI"
ScreenGui.Parent = PlayerGui

-- Retractable main button
local retractButton = Instance.new("TextButton")
retractButton.Name = "RetractButton"
retractButton.Size = UDim2.new(0, 40, 0, 40)
retractButton.Position = UDim2.new(0, 20, 0, 20)
retractButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
retractButton.BorderSizePixel = 0
retractButton.TextColor3 = Color3.new(1,1,1)
retractButton.Font = Enum.Font.SourceSansBold
retractButton.TextSize = 30
retractButton.Text = "+"
retractButton.Parent = ScreenGui

-- Main panel (hidden by default)
local mainPanel = Instance.new("Frame")
mainPanel.Name = "MainPanel"
mainPanel.Size = UDim2.new(0, 250, 0, 260)
mainPanel.Position = UDim2.new(0, 70, 0, 20)
mainPanel.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
mainPanel.BorderSizePixel = 0
mainPanel.Visible = false
mainPanel.Parent = ScreenGui

-- Make mainPanel draggable
local dragging = false
local dragInput, dragStart, startPos

mainPanel.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = mainPanel.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

mainPanel.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        mainPanel.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- Toggle button creator
local function createToggle(text, pos, initialState, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 210, 0, 40)
    btn.Position = pos
    btn.BackgroundColor3 = initialState and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(170, 0, 0)
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 22
    btn.Text = text .. ": " .. (initialState and "ON" or "OFF")
    btn.Parent = mainPanel
    btn.AutoButtonColor = false

    btn.MouseButton1Click:Connect(function()
        initialState = not initialState
        btn.BackgroundColor3 = initialState and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(170, 0, 0)
        btn.Text = text .. ": " .. (initialState and "ON" or "OFF")
        callback(initialState)
    end)
    return btn
end

-- Create toggle buttons
local aimbotBtn = createToggle("Aimbot", UDim2.new(0, 20, 0, 10), false, function(state)
    aimbotEnabled = state
    if state then
        buildTargetList()
    end
end)

local visibilityBtn = createToggle("Visibility Check", UDim2.new(0, 20, 0, 60), false, function(state)
    visibilityCheck = state
    if aimbotEnabled then
        buildTargetList()
    end
end)

local ignoreTeamBtn = createToggle("Ignore Teammates", UDim2.new(0, 20, 0, 110), false, function(state)
    ignoreTeammates = state
    if aimbotEnabled then
        buildTargetList()
    end
end)

local aimHeadBtn = Instance.new("TextButton")
aimHeadBtn.Size = UDim2.new(0, 210, 0, 40)
aimHeadBtn.Position = UDim2.new(0, 20, 0, 160)
aimHeadBtn.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
aimHeadBtn.TextColor3 = Color3.new(1,1,1)
aimHeadBtn.Font = Enum.Font.SourceSansBold
aimHeadBtn.TextSize = 22
aimHeadBtn.Text = "Aim At: Body"
aimHeadBtn.Parent = mainPanel
aimHeadBtn.AutoButtonColor = false

aimHeadBtn.MouseButton1Click:Connect(function()
    aimAtHead = not aimAtHead
    aimHeadBtn.Text = "Aim At: " .. (aimAtHead and "Head" or "Body")
    aimHeadBtn.BackgroundColor3 = aimAtHead and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(170, 0, 0)
end)

-- Manual Target Switch Buttons
local prevBtn = Instance.new("TextButton")
prevBtn.Size = UDim
