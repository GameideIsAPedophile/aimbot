local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local UserInputService = game:GetService("UserInputService")

-- Settings
local aimbotEnabled = false
local visibilityCheck = false
local aimAtHead = false
local teamCheck = false

-- Utility functions here (keep your existing ones)...

-- GUI Setup
local ScreenGui = Instance.new("ScreenGui", LocalPlayer:WaitForChild("PlayerGui"))
ScreenGui.Name = "AimbotUI"

-- Main Frame (for draggable container)
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 250, 0, 140)
mainFrame.Position = UDim2.new(0, 20, 0, 20)
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = ScreenGui
mainFrame.Active = true
mainFrame.Draggable = true

-- Toggle Aimbot Button
local toggleButton = Instance.new("TextButton")
toggleButton.Size = UDim2.new(0, 120, 0, 30)
toggleButton.Position = UDim2.new(0, 10, 0, 10)
toggleButton.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
toggleButton.TextColor3 = Color3.new(1, 1, 1)
toggleButton.Font = Enum.Font.SourceSansBold
toggleButton.TextSize = 18
toggleButton.Text = "Aimbot: OFF"
toggleButton.Parent = mainFrame

toggleButton.MouseButton1Click:Connect(function()
    aimbotEnabled = not aimbotEnabled
    toggleButton.Text = "Aimbot: " .. (aimbotEnabled and "ON" or "OFF")
    toggleButton.BackgroundColor3 = aimbotEnabled and Color3.fromRGB(0, 200, 0) or Color3.fromRGB(150, 0, 0)
end)

-- Visibility Check Button
local visibilityCheckbox = Instance.new("TextButton")
visibilityCheckbox.Size = UDim2.new(0, 220, 0, 30)
visibilityCheckbox.Position = UDim2.new(0, 10, 0, 50)
visibilityCheckbox.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
visibilityCheckbox.TextColor3 = Color3.new(1, 1, 1)
visibilityCheckbox.Font = Enum.Font.SourceSansBold
visibilityCheckbox.TextSize = 18
visibilityCheckbox.Text = "Visibility Check: OFF"
visibilityCheckbox.Parent = mainFrame

visibilityCheckbox.MouseButton1Click:Connect(function()
    visibilityCheck = not visibilityCheck
    visibilityCheckbox.Text = "Visibility Check: " .. (visibilityCheck and "ON" or "OFF")
    visibilityCheckbox.BackgroundColor3 = visibilityCheck and Color3.fromRGB(50, 120, 200) or Color3.fromRGB(30, 30, 30)
end)

-- Aim at Head Button
local headAimCheckbox = Instance.new("TextButton")
headAimCheckbox.Size = UDim2.new(0, 150, 0, 30)
headAimCheckbox.Position = UDim2.new(0, 10, 0, 90)
headAimCheckbox.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
headAimCheckbox.TextColor3 = Color3.new(1, 1, 1)
headAimCheckbox.Font = Enum.Font.SourceSansBold
headAimCheckbox.TextSize = 18
headAimCheckbox.Text = "Aim at Head: OFF"
headAimCheckbox.Parent = mainFrame

headAimCheckbox.MouseButton1Click:Connect(function()
    aimAtHead = not aimAtHead
    headAimCheckbox.Text = "Aim at Head: " .. (aimAtHead and "ON" or "OFF")
    headAimCheckbox.BackgroundColor3 = aimAtHead and Color3.fromRGB(50, 120, 200) or Color3.fromRGB(30, 30, 30)
end)

-- Team Check Button
local teamCheckCheckbox = Instance.new("TextButton")
teamCheckCheckbox.Size = UDim2.new(0, 180, 0, 30)
teamCheckCheckbox.Position = UDim2.new(0, 10, 0, 130)
teamCheckCheckbox.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
teamCheckCheckbox.TextColor3 = Color3.new(1, 1, 1)
teamCheckCheckbox.Font = Enum.Font.SourceSansBold
teamCheckCheckbox.TextSize = 18
teamCheckCheckbox.Text = "Ignore Teammates: OFF"
teamCheckCheckbox.Parent = mainFrame

teamCheckCheckbox.MouseButton1Click:Connect(function()
    teamCheck = not teamCheck
    teamCheckCheckbox.Text = "Ignore Teammates: " .. (teamCheck and "ON" or "OFF")
    teamCheckCheckbox.BackgroundColor3 = teamCheck and Color3.fromRGB(50, 120, 200) or Color3.fromRGB(30, 30, 30)
end)

-- Update your targeting function to consider `aimAtHead` and `teamCheck`
local function getClosestPlayer()
    local closest = nil
    local shortestDistance = math.huge

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            if teamCheck and player.Team == LocalPlayer.Team then
                -- Skip teammates if teamCheck is ON
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

-- Your RunService RenderStepped aiming logic here, using the new targeting
