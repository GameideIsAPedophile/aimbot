-- 📌 Mobile Aimbot Script with Swipe Target Switching, GUI, and Toggles

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- ✅ Settings
local aimbotEnabled = false
local visibilityCheck = false
local aimAtHead = false
_G.ignoreTeammates = false
local currentTarget = nil
local swipeStart = nil

-- 🧠 Utility: Check if target is visible
local function isTargetVisible(targetPosition)
	local origin = Camera.CFrame.Position
	local direction = (targetPosition - origin).Unit * 1000
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
	raycastParams.FilterDescendantsInstances = {LocalPlayer.Character}
	local result = workspace:Raycast(origin, direction, raycastParams)

	if result and result.Instance then
		if not result.Instance:IsDescendantOf(workspace:FindFirstChildOfClass("Model")) then
			return true
		end
		return false
	end

	return true
end

-- 🔍 Find closest valid player
local function getClosestPlayer()
	local closest = nil
	local shortestDistance = math.huge

	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character:FindFirstChild("Humanoid") then
			if _G.ignoreTeammates and player.Team == LocalPlayer.Team then continue end
			if player.Character.Humanoid.Health <= 0 then continue end

			local targetPart = player.Character:FindFirstChild(aimAtHead and "Head" or "HumanoidRootPart")
			if targetPart then
				local distance = (targetPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
				if distance < shortestDistance then
					if not visibilityCheck or isTargetVisible(targetPart.Position) then
						closest = player
						shortestDistance = distance
					end
				end
			end
		end
	end

	return closest
end

-- 🎯 Aimbot Tracking
RunService.RenderStepped:Connect(function()
	if aimbotEnabled then
		local target = currentTarget or getClosestPlayer()
		if target and target.Character and target.Character:FindFirstChild("Humanoid") and target.Character.Humanoid.Health > 0 then
			local partName = aimAtHead and "Head" or "HumanoidRootPart"
			local targetPart = target.Character:FindFirstChild(partName)
			if targetPart then
				if not visibilityCheck or isTargetVisible(targetPart.Position) then
					Camera.CFrame = CFrame.new(Camera.CFrame.Position, targetPart.Position)
					currentTarget = target
				end
			end
		else
			currentTarget = nil
		end
	end
end)

-- 🌀 Swipe Detection
UserInputService.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch then
		swipeStart = input.Position
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch and swipeStart then
		local delta = input.Position - swipeStart
		if math.abs(delta.X) > 100 and math.abs(delta.Y) < 50 then
			if delta.X > 0 then
				switchTarget("right")
			else
				switchTarget("left")
			end
		end
		swipeStart = nil
	end
end)

function switchTarget(direction)
	local candidates = {}
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character:FindFirstChild("Humanoid") then
			if _G.ignoreTeammates and player.Team == LocalPlayer.Team then continue end
			if player.Character.Humanoid.Health <= 0 then continue end
			local screenPos, onScreen = Camera:WorldToViewportPoint(player.Character.HumanoidRootPart.Position)
			if onScreen then
				table.insert(candidates, {player = player, x = screenPos.X})
			end
		end
	end

	if currentTarget then
		local curX = Camera:WorldToViewportPoint(currentTarget.Character.HumanoidRootPart.Position).X
		table.sort(candidates, function(a, b) return a.x < b.x end)
		for i, data in ipairs(candidates) do
			if data.player == currentTarget then
				local nextIndex = direction == "right" and i + 1 or i - 1
				if candidates[nextIndex] then
					currentTarget = candidates[nextIndex].player
				end
				break
			end
		end
	else
		currentTarget = #candidates > 0 and candidates[1].player or nil
	end
end

-- 📱 GUI Setup (respawns after death)
local function createGUI()
	local gui = Instance.new("ScreenGui")
	gui.Name = "AimbotGUI"
	gui.ResetOnSpawn = false
	gui.Parent = LocalPlayer:WaitForChild("PlayerGui")

	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(0, 240, 0, 200)
	frame.Position = UDim2.new(0, 20, 0, 20)
	frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	frame.BorderSizePixel = 0
	frame.Parent = gui
	frame.Active = true
	frame.Draggable = true

	local function createButton(text, posY, callback)
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(1, -20, 0, 35)
		btn.Position = UDim2.new(0, 10, 0, posY)
		btn.Text = text
		btn.Font = Enum.Font.SourceSansBold
		btn.TextColor3 = Color3.new(1, 1, 1)
		btn.TextSize = 18
		btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
		btn.Parent = frame
		btn.MouseButton1Click:Connect(callback)
		return btn
	end

	local toggleBtn = createButton("Aimbot: OFF", 10, function()
		aimbotEnabled = not aimbotEnabled
		toggleBtn.Text = "Aimbot: " .. (aimbotEnabled and "ON" or "OFF")
	end)

	local visBtn = createButton("Visibility Check: OFF", 50, function()
		visibilityCheck = not visibilityCheck
		visBtn.Text = "Visibility Check: " .. (visibilityCheck and "ON" or "OFF")
	end)

	local headBtn = createButton("Aim At Head: OFF", 90, function()
		aimAtHead = not aimAtHead
		headBtn.Text = "Aim At Head: " .. (aimAtHead and "ON" or "OFF")
	end)

	local teamBtn = createButton("Ignore Teammates: OFF", 130, function()
		_G.ignoreTeammates = not _G.ignoreTeammates
		teamBtn.Text = "Ignore Teammates: " .. (_G.ignoreTeammates and "ON" or "OFF")
	end)
end

createGUI()

-- ♻️ Recreate GUI after death
LocalPlayer.CharacterAdded:Connect(function()
	task.wait(1)
	if LocalPlayer:FindFirstChild("PlayerGui") and not LocalPlayer.PlayerGui:FindFirstChild("AimbotGUI") then
		createGUI()
	end
end)
