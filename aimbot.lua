-- 📌 Mobile Aimbot with Toggle, Visibility, Team Check, Head/Body Aim, Target Switching

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local UserInputService = game:GetService("UserInputService")

-- Prevent GUI duplication
if LocalPlayer.PlayerGui:FindFirstChild("AimbotUI") then
    LocalPlayer.PlayerGui:FindFirstChild("AimbotUI"):Destroy()
end

-- ✅ Settings
local aimbotEnabled = false
local visibilityCheck = false
local headshot = false
local ignoreTeammates = false
local currentTargetIndex = 1
local validTargets = {}

-- 👁️ Visibility Check
local function isTargetVisible(targetPosition)
    local origin = Camera.CFrame.Position
    local direction = (targetPosition - origin).Unit * 1000
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character}
    local result = workspace:Raycast(origin, direction, raycastParams)

    if result and result.Instance then
        if result.Instance:IsDescendantOf(workspace:FindFirstChildOfClass("Model")) and not result.Instance:IsDescendantOf(LocalPlayer.Character) then
            return false
        end
    end

    return true
end

-- 🎯 Get All Valid Targets
local function updateValidTargets()
    validTargets = {}

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character:FindFirstChild("Humanoid") then
            local humanoid = player.Character.Humanoid
            if humanoid.Health > 0 then
                if ignoreTeammates and player.Team == LocalPlayer.Team then
                    continue
                end

                if visibilityCheck then
                    if isTargetVisible(player.Character.HumanoidRootPart.Position) then
                        table.insert(validTargets, player)
                    end
                else
                    table.insert(validTargets, player)
                end
            end
        end
    end
end

-- 🔁 Switch Target
local function switchTarget(direction)
    if #validTargets == 0 then return end
    currentTargetIndex += direction
    if currentTargetIndex > #validTargets then
        currentTargetIndex = 1
    elseif currentTargetIndex < 1 then
        currentTargetIndex = #validTargets
    end
end

-- 🔥 Aimbot loop
RunService.RenderStepped:Connect(function()
    if aimbotEnabled then
        updateValidTargets()
        local target = validTargets[currentTargetIndex]
        if target and target.Character and target.Character:FindFirstChild("Humanoid") and target.Character.Humanoid.Health > 0 then
            local part = headshot and target.Character:FindFirstChild("Head") or target.Character:FindFirstChild("HumanoidRootPart")
            if part then
                Camera.CFrame = CFrame.new(Camera.CFrame.Position, part.Position)
            end
        end
    end
end)

-- 📱 GUI
local gui = Instance.new("ScreenGui", LocalPlayer:WaitForChild("PlayerGui"))
gui.Name = "AimbotUI"
gui.ResetOnSpawn = false

local function createButton(text, pos, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 150, 0, 40)
    btn.Position = pos
    btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 20
    btn.Text = text
    btn.Parent = gui
    btn.MouseButton1Click:Connect(callback)
    return btn
end

-- 🟢 Aimbot Toggle
local toggleBtn = createButton("Aimbot: OFF", UDim2.new(0, 20, 0, 20), function()
    aimbotEnabled = not aimbotEnabled
    toggleBtn.Text = "Aimbot: " .. (aimbotEnabled and "ON" or "OFF")
    toggleBtn.BackgroundColor3 = aimbotEnabled and Color3.fromRGB(0, 200, 0) or Color3.fromRGB(200, 0, 0)
end)

-- 🔵 Visibility Toggle
local visBtn = createButton("Visibility: OFF", UDim2.new(0, 20, 0, 70), function()
    visibilityCheck = not visibilityCheck
    visBtn.Text = "Visibility: " .. (visibilityCheck and "ON" or "OFF")
    visBtn.BackgroundColor3 = visibilityCheck and Color3.fromRGB(50, 120, 200) or Color3.fromRGB(50, 50, 50)
end)

-- 🟥 Ignore Teammates
local teamBtn = createButton("Ignore Teammates: OFF", UDim2.new(0, 20, 0, 120), function()
    ignoreTeammates = not ignoreTeammates
    teamBtn.Text = "Ignore Teammates: " .. (ignoreTeammates and "ON" or "OFF")
    teamBtn.BackgroundColor3 = ignoreTeammates and Color3.fromRGB(200, 100, 100) or Color3.fromRGB(50, 50, 50)
end)

-- 🎯 Head/Body Toggle
local headBtn = createButton("Aim at Head: OFF", UDim2.new(0, 20, 0, 170), function()
    headshot = not headshot
    headBtn.Text = "Aim at Head: " .. (headshot and "ON" or "OFF")
    headBtn.BackgroundColor3 = headshot and Color3.fromRGB(180, 150, 230) or Color3.fromRGB(50, 50, 50)
end)

-- ⬅️ Prev Target
createButton("← Prev Target", UDim2.new(0, 20, 0, 220), function()
    switchTarget(-1)
end)

-- ➡️ Next Target
createButton("Next Target →", UDim2.new(0, 180, 0, 220), function()
    switchTarget(1)
end)
