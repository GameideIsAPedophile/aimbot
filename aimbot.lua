-- Roblox Mobile Aimbot with Toggle, Visibility Check, Head Aim, Ignore Teammates, Auto Shoot, Manual Target Switch,
-- Draggable & Retractable GUI fitting Samsung S21 screen

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
local autoShootEnabled = false

-- Targeting variables
local currentTargets = {}
local targetIndex = 1

-- Utility: Raycast visibility check
local function isTargetVisible(targetPosition)
    local origin = Camera.CFrame.Position
    local direction = (targetPosition - origin).Unit * 1000
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character}
    local result = workspace:Raycast(origin, direction, raycastParams)

    if result and result.Instance then
        -- Check if hit is part of targetPosition's character
        local hitPart = result.Instance
        local targetModel = nil
        for _, player in ipairs(Players:GetPlayers()) do
            if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                if (player.Character.HumanoidRootPart.Position - targetPosition).Magnitude < 0.1 then
                    targetModel = player.Character
                    break
                end
            end
        end
        if hitPart:IsDescendantOf(targetModel) then
            return true -- Ray hit the target or its part, so visible
        else
            return false -- Something else blocking
        end
    end

    return true -- No hit means clear line
end

-- Get valid targets considering settings
local function getValidTargets()
    local targets = {}

    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        return targets
    end

    local localTeam = nil
    pcall(function()
        localTeam = LocalPlayer.Team
    end)

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid.Health > 0 then
                if ignoreTeammates then
                    local pTeam = nil
                    pcall(function()
                        pTeam = player.Team
                    end)
                    if localTeam and pTeam and localTeam == pTeam then
                        continue
                    end
                end

                if visibilityCheck then
                    if not isTargetVisible(player.Character.HumanoidRootPart.Position) then
                        continue
                    end
                end

                table.insert(targets, player)
            end
        end
    end

    -- Sort by distance
    table.sort(targets, function(a,b)
        local aDist = (a.Character.HumanoidRootPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
        local bDist = (b.Character.HumanoidRootPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
        return aDist < bDist
    end)

    return targets
end

-- GUI Setup
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AimbotUI"
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
ScreenGui.ResetOnSpawn = false

-- Draggable frame utility
local function makeDraggable(frame)
    local dragging, dragInput, dragStart, startPos

    local function update(input)
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end

    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    frame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            update(input)
        end
    end)
end

-- Create small retractable button
local retractButton = Instance.new("TextButton")
retractButton.Size = UDim2.new(0, 40, 0, 40)
retractButton.Position = UDim2.new(0, 10, 0.8, 0)
retractButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
retractButton.TextColor3 = Color3.new(1,1,1)
retractButton.Font = Enum.Font.SourceSansBold
retractButton.Text = ">>"
retractButton.Parent = ScreenGui

-- Create main options frame (hidden by default)
local optionsFrame = Instance.new("Frame")
optionsFrame.Size = UDim2.new(0, 220, 0, 320)
optionsFrame.Position = UDim2.new(0, 10, 0.6, 0)
optionsFrame.BackgroundColor3 = Color3.fromRGB(35,35,35)
optionsFrame.Visible = false
optionsFrame.Parent = ScreenGui
makeDraggable(optionsFrame)

-- Helper to create buttons inside optionsFrame
local function createButton(text, pos)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 200, 0, 40)
    btn.Position = pos
    btn.BackgroundColor3 = Color3.fromRGB(60,60,60)
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 20
    btn.Text = text
    btn.Parent = optionsFrame
    return btn
end

-- Create all toggle buttons with update helper
local function updateButtonState(button, state)
    button.Text = button.Text:match("^[^:]+") .. ": " .. (state and "ON" or "OFF")
    button.BackgroundColor3 = state and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(150, 0, 0)
end

-- Buttons
local toggleAimbotBtn = createButton("Aimbot: OFF", UDim2.new(0,10,0,10))
toggleAimbotBtn.MouseButton1Click:Connect(function()
    aimbotEnabled = not aimbotEnabled
    updateButtonState(toggleAimbotBtn, aimbotEnabled)
end)

local toggleVisibilityBtn = createButton("Visibility Check: OFF", UDim2.new(0,10,0,60))
toggleVisibilityBtn.MouseButton1Click:Connect(function()
    visibilityCheck = not visibilityCheck
    updateButtonState(toggleVisibilityBtn, visibilityCheck)
end)

local toggleAimHeadBtn = createButton("Aim at Head: OFF", UDim2.new(0,10,0,110))
toggleAimHeadBtn.MouseButton1Click:Connect(function()
    aimAtHead = not aimAtHead
    updateButtonState(toggleAimHeadBtn, aimAtHead)
end)

local toggleIgnoreTeamBtn = createButton("Ignore Teammates: OFF", UDim2.new(0,10,0,160))
toggleIgnoreTeamBtn.MouseButton1Click:Connect(function()
    ignoreTeammates = not ignoreTeammates
    updateButtonState(toggleIgnoreTeamBtn, ignoreTeammates)
end)

local toggleAutoShootBtn = createButton("Auto Shoot: OFF", UDim2.new(0,10,0,210))
toggleAutoShootBtn.MouseButton1Click:Connect(function()
    autoShootEnabled = not autoShootEnabled
    updateButtonState(toggleAutoShootBtn, autoShootEnabled)
end)

-- Manual target switch buttons
local prevTargetBtn = createButton("Previous Target", UDim2.new(0,10,0,260))
local nextTargetBtn = createButton("Next Target", UDim2.new(0,10,0,310))

prevTargetBtn.MouseButton1Click:Connect(function()
    if #currentTargets > 0 then
        targetIndex = targetIndex - 1
        if targetIndex < 1 then
            targetIndex = #currentTargets
        end
    end
end)

nextTargetBtn.MouseButton1Click:Connect(function()
    if #currentTargets > 0 then
        targetIndex = targetIndex + 1
        if targetIndex > #currentTargets then
            targetIndex = 1
        end
    end
end)

-- Retract button toggle
retractButton.MouseButton1Click:Connect(function()
    optionsFrame.Visible = not optionsFrame.Visible
    retractButton.Text = optionsFrame.Visible and "<<" or ">>"
end)

-- Make retract button draggable too
makeDraggable(retractButton)

-- Aimbot loop
RunService.RenderStepped:Connect(function()
    if aimbotEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        currentTargets = getValidTargets()
        if #currentTargets == 0 then
            targetIndex = 1
            return
        end

        if targetIndex > #currentTargets then
            targetIndex = 1
        elseif targetIndex < 1 then
            targetIndex = #currentTargets
        end

        local target = currentTargets[targetIndex]
        if target and target.Character then
            local humanoid = target.Character:FindFirstChildOfClass("Humanoid")
            local hrp = target.Character:FindFirstChild("HumanoidRootPart")
            if humanoid and humanoid.Health > 0 and hrp then
                local aimPart = aimAtHead and target.Character:FindFirstChild("Head") or hrp
                if aimPart then
                    Camera.CFrame = CFrame.new(Camera.CFrame.Position, aimPart.Position)

                    -- Auto Shoot
                    if autoShootEnabled then
                        local character = LocalPlayer.Character
                        if character then
                            local tool = character:FindFirstChildOfClass("Tool")
                            if tool then
                                -- Try to fire using tool's RemoteEvent if exists
                                local fireEvent = tool:FindFirstChild("Fire") or tool:FindFirstChild("Shoot")
                                if fireEvent and fireEvent:IsA("RemoteEvent") then
                                    fireEvent:FireServer()
                                else
                                    -- Fallback: simulate mouse click (may not work in all games)
                                    UserInputService.MouseButton1Down:Wait()
                                end
                            end
                        end
                    end
                end
            else
                -- Target died, refresh targets
                currentTargets = getValidTargets()
                targetIndex = 1
            end
        end
    end
end)
