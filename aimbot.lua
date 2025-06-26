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

-- Utility: Check if target is alive and visible
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
        local hitPart = result.Instance
        -- Allow if hitPart is descendant of target character, else block
        local targetCharacter = nil
        for _, player in ipairs(Players:GetPlayers()) do
            if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                if hitPart:IsDescendantOf(player.Character) then
                    targetCharacter = player.Character
                    break
                end
            end
        end
        if targetCharacter then
            -- hit something in target character, visible
            return true
        else
            -- hit something else blocking view
            return false
        end
    end

    -- Nothing blocking, consider visible
    return true
end

-- Build target list according to filters
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
    -- Sort by distance ascending
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
    local targetPart = aimAtHead and target.Character:FindFirstChild("Head") or target.Character.HumanoidRootPart
    if not targetPart then return end
    Camera.CFrame = CFrame.new(Camera.CFrame.Position, targetPart.Position)
end

-- GUI Setup
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AimbotUI"
ScreenGui.Parent = PlayerGui

-- Main draggable frame
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 250, 0, 240)
MainFrame.Position = UDim2.new(0, 20, 0, 50)
MainFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui
MainFrame.Visible = false -- start hidden, show on retract button click

-- Make draggable
local dragging = false
local dragInput, dragStart, startPos

MainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

MainFrame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- Retract Button (small square)
local RetractButton = Instance.new("TextButton")
RetractButton.Size = UDim2.new(0, 40, 0, 40)
RetractButton.Position = UDim2.new(0, 20, 0, 10)
RetractButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
RetractButton.BorderSizePixel = 0
RetractButton.TextColor3 = Color3.new(1, 1, 1)
RetractButton.Font = Enum.Font.SourceSansBold
RetractButton.TextSize = 24
RetractButton.Text = "+"
RetractButton.Parent = ScreenGui

local function updateRetractButton()
    if MainFrame.Visible then
        RetractButton.Text = "−"
    else
        RetractButton.Text = "+"
    end
end

RetractButton.MouseButton1Click:Connect(function()
    MainFrame.Visible = not MainFrame.Visible
    updateRetractButton()
end)

updateRetractButton()

-- Buttons inside MainFrame

-- Helper to create toggle buttons with state and callback
local function createToggleButton(text, position, initialState, onToggle)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 210, 0, 40)
    btn.Position = position
    btn.BackgroundColor3 = initialState and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(150, 0, 0)
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 20
    btn.Text = text .. ": " .. (initialState and "ON" or "OFF")
    btn.Parent = MainFrame
    btn.AutoButtonColor = false

    btn.MouseButton1Click:Connect(function()
        local newState = not initialState
        initialState = newState
        btn.Text = text .. ": " .. (newState and "ON" or "OFF")
        btn.BackgroundColor3 = newState and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(150, 0, 0)
        onToggle(newState)
    end)
    return btn
end

-- Aimbot Toggle
local aimbotButton = createToggleButton("Aimbot", UDim2.new(0, 20, 0, 10), false, function(state)
    aimbotEnabled = state
    if aimbotEnabled then
        buildTargetList()
    end
end)

-- Visibility Check Toggle
local visibilityButton = createToggleButton("Visibility Check", UDim2.new(0, 20, 0, 60), false, function(state)
    visibilityCheck = state
    if aimbotEnabled then
        buildTargetList()
    end
end)

-- Ignore Teammates Toggle
local ignoreTeamButton = createToggleButton("Ignore Teammates", UDim2.new(0, 20, 0, 110), false, function(state)
    ignoreTeammates = state
    if aimbotEnabled then
        buildTargetList()
    end
end)

-- Aim at Head / Body Toggle (special toggle)
local aimAtHeadButton = Instance.new("TextButton")
aimAtHeadButton.Size = UDim2.new(0, 210, 0, 40)
aimAtHeadButton.Position = UDim2.new(0, 20, 0, 160)
aimAtHeadButton.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
aimAtHeadButton.TextColor3 = Color3.new(1,1,1)
aimAtHeadButton.Font = Enum.Font.SourceSansBold
aimAtHeadButton.TextSize = 20
aimAtHeadButton.Text = "Aim At: Body"
aimAtHeadButton.Parent = MainFrame
aimAtHeadButton.AutoButtonColor = false

aimAtHeadButton.MouseButton1Click:Connect(function()
    aimAtHead = not aimAtHead
    aimAtHeadButton.Text = "Aim At: " .. (aimAtHead and "Head" or "Body")
    aimAtHeadButton.BackgroundColor3 = aimAtHead and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(150, 0, 0)
end)

-- Manual Target Switching Buttons

local prevButton = Instance.new("TextButton")
prevButton.Size = UDim2.new(0, 90, 0, 40)
prevButton.Position = UDim2.new(0, 20, 0, 210)
prevButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
prevButton.TextColor3 = Color3.new(1,1,1)
prevButton.Font = Enum.Font.SourceSansBold
prevButton.TextSize = 18
prevButton.Text = "Prev Target"
prevButton.Parent = MainFrame

local nextButton = Instance.new("TextButton")
nextButton.Size = UDim2.new(0, 90, 0, 40)
nextButton.Position = UDim2.new(0, 140, 0, 210)
nextButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
nextButton.TextColor3 = Color3.new(1,1,1)
nextButton.Font = Enum.Font.SourceSansBold
nextButton.TextSize = 18
nextButton.Text = "Next Target"
nextButton.Parent = MainFrame

prevButton.MouseButton1Click:Connect(function()
    if #targetList > 0 then
        currentTargetIndex = currentTargetIndex - 1
        if currentTargetIndex < 1
