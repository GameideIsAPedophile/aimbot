-- ✅ Roblox Aimbot Script with Draggable, Retractable GUI, Toggle Buttons, Visibility Fix, and Target Switch

local Players = game:GetService("Players") local RunService = game:GetService("RunService") local UserInputService = game:GetService("UserInputService") local LocalPlayer = Players.LocalPlayer local Camera = workspace.CurrentCamera

-- ✅ Settings local aimbotEnabled = false local visibilityCheck = false local ignoreTeammates = false local aimAtHead = false

local currentTarget = nil local targetList = {} local currentIndex = 1

-- 🧠 Visibility Check local function isTargetVisible(targetPart) local origin = Camera.CFrame.Position local direction = (targetPart.Position - origin).Unit * 1000

local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
raycastParams.FilterDescendantsInstances = {LocalPlayer.Character, Camera}

local result = workspace:Raycast(origin, direction, raycastParams)
return result and result.Instance and targetPart:IsDescendantOf(result.Instance.Parent)

end

-- 🎯 Target Selection local function updateTargetList() targetList = {} for _, player in ipairs(Players:GetPlayers()) do if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Humanoid") and player.Character:FindFirstChild("HumanoidRootPart") then if player.Character.Humanoid.Health > 0 then if ignoreTeammates and player.Team == LocalPlayer.Team then continue end if visibilityCheck then local part = aimAtHead and player.Character:FindFirstChild("Head") or player.Character:FindFirstChild("HumanoidRootPart") if part and isTargetVisible(part) then table.insert(targetList, player) end else table.insert(targetList, player) end end end end end

local function switchTarget(direction) if #targetList == 0 then return end currentIndex = currentIndex + direction if currentIndex < 1 then currentIndex = #targetList end if currentIndex > #targetList then currentIndex = 1 end currentTarget = targetList[currentIndex] end

-- 🔄 Aimbot Update RunService.RenderStepped:Connect(function() if aimbotEnabled then updateTargetList() if not currentTarget or not table.find(targetList, currentTarget) then switchTarget(0) end

if currentTarget and currentTarget.Character and currentTarget.Character:FindFirstChild("Humanoid") then
        if currentTarget.Character.Humanoid.Health > 0 then
            local part = aimAtHead and currentTarget.Character:FindFirstChild("Head") or currentTarget.Character:FindFirstChild("HumanoidRootPart")
            if part then
                Camera.CFrame = CFrame.new(Camera.CFrame.Position, part.Position)
            end
        end
    end
end

end)

-- 📱 GUI Setup if LocalPlayer:FindFirstChild("PlayerGui") then if LocalPlayer.PlayerGui:FindFirstChild("AimbotUI") then LocalPlayer.PlayerGui.AimbotUI:Destroy() end end

local gui = Instance.new("ScreenGui") local mainFrame = Instance.new("Frame") local toggleAimbot = Instance.new("TextButton") local toggleVisibility = Instance.new("TextButton") local toggleTeammates = Instance.new("TextButton") local toggleHead = Instance.new("TextButton") local nextBtn = Instance.new("TextButton") local prevBtn = Instance.new("TextButton") local toggleExpand = Instance.new("TextButton")

-- GUI Properties gui.Name = "AimbotUI" gui.ResetOnSpawn = false gui.Parent = LocalPlayer:WaitForChild("PlayerGui")

mainFrame.Size = UDim2.new(0, 220, 0, 240) mainFrame.Position = UDim2.new(0, 10, 0, 100) mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30) mainFrame.Active = true mainFrame.Draggable = true mainFrame.Parent = gui

-- Expand/Collapse local expanded = true

local function updateVisibility() for _, child in ipairs(mainFrame:GetChildren()) do if child:IsA("TextButton") and child ~= toggleExpand then child.Visible = expanded end end mainFrame.Size = expanded and UDim2.new(0, 220, 0, 240) or UDim2.new(0, 50, 0, 50) end

-- Button Creation Helper local function makeButton(name, posY, text, callback) local btn = Instance.new("TextButton") btn.Name = name btn.Size = UDim2.new(0, 200, 0, 30) btn.Position = UDim2.new(0, 10, 0, posY) btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50) btn.TextColor3 = Color3.new(1, 1, 1) btn.Font = Enum.Font.SourceSansBold btn.TextSize = 18 btn.Text = text btn.Parent = mainFrame btn.MouseButton1Click:Connect(callback) return btn end

-- Toggle Buttons local function updateButton(btn, state) btn.Text = btn.Name .. ": " .. (state and "ON" or "OFF") btn.BackgroundColor3 = state and Color3.fromRGB(0, 200, 0) or Color3.fromRGB(150, 0, 0) end

toggleAimbot = makeButton("Aimbot", 10, "Aimbot: OFF", function() aimbotEnabled = not aimbotEnabled updateButton(toggleAimbot, aimbotEnabled) end)

toggleVisibility = makeButton("Visibility", 50, "Visibility: OFF", function() visibilityCheck = not visibilityCheck updateButton(toggleVisibility, visibilityCheck) end)

toggleTeammates = makeButton("IgnoreTeam", 90, "IgnoreTeam: OFF", function() ignoreTeammates = not ignoreTeammates updateButton(toggleTeammates, ignoreTeammates) end)

toggleHead = makeButton("Headshot", 130, "Headshot: OFF", function() aimAtHead = not aimAtHead updateButton(toggleHead, aimAtHead) end)

prevBtn = makeButton("Prev", 170, "< Prev Target", function() switchTarget(-1) end)

nextBtn = makeButton("Next", 210, "Next Target >", function() switchTarget(1) end)

-- Expand/Collapse Button toggleExpand.Size = UDim2.new(0, 50, 0, 50) toggleExpand.Position = UDim2.new(0, 0, 0, -55) toggleExpand.Text = "+" toggleExpand.BackgroundColor3 = Color3.fromRGB(200, 200, 0) toggleExpand.Parent = mainFrame toggleExpand.MouseButton1Click:Connect(function() expanded = not expanded toggleExpand.Text = expanded and "-" or "+" updateVisibility() end)

updateButton(toggleAimbot, aimbotEnabled) updateButton(toggleVisibility, visibilityCheck) updateButton(toggleTeammates, ignoreTeammates) updateButton(toggleHead, aimAtHead)

updateVisibility()

