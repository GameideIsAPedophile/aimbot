local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- ✅ Settings
_G.aimbotEnabled = false
_G.visibilityCheck = false
_G.aimAtHead = false
_G.ignoreTeammates = false

-- 🧠 Utility: Visibility Check (Raycast)
local function isTargetVisible(targetPosition)
	local origin = Camera.CFrame.Position
	local direction = (targetPosition - origin).Unit * 1000
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
	raycastParams.FilterDescendantsInstances = {LocalPlayer.Character}
	local result = workspace:Raycast(origin, direction, raycastParams)

	return not (result and result.Instance and not result.Instance:IsDescendantOf(workspace:FindFirstChildOfClass("Model")))
end

-- 🎯 Get Closest Valid Player
local function getClosestPlayer()
	local closest = nil
	local shortestDistance = math.huge

	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Humanoid") and player.Character:FindFirstChild("HumanoidRootPart") then
			if player.Character.Humanoid.Health <= 0 then continue end
			if _G.ignoreTeammates and player.Team == LocalPlayer.Team then continue end

			local targetPart = _G.aimAtHead and player.Character:FindFirstChild("Head") or player.Character:FindFirstChild("HumanoidRootPart")
			if not targetPart then continue end

			local distance = (targetPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
			if distance < shortestDistance then
				if _G.visibilityCheck then
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
	end

	return closest
end

-- 📌 Aimbot Logic
RunService.RenderStepped:Connect(function()
	if _G.aimbotEnabled then
		local target = getClosestPlayer()
		if target and target.Character then
			local part = _G.aimAtHead and target.Character:FindFirstChild("Head") or target.Character:FindFirstChild("HumanoidRootPart")
			if part then
				Camera.CFrame = CFrame.new(Camera.CFrame.Position, part.Position)
			end
		end
	end
end)

-- 🖼️ Create GUI Function
local function createAimbotGui()
	local existing = LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild("AimbotUI")
	if existing then existing:Destroy() end

	local ScreenGui = Instance.new("ScreenGui")
	ScreenGui.Name = "AimbotUI"
	ScreenGui.ResetOnSpawn = false
	ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(0, 220, 0, 200)
	frame.Position = UDim2.new(0, 10, 0, 10)
	frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	frame.Active = true
	frame.Draggable = true
	frame.Parent = ScreenGui

	local function createButton(yPos, text, toggleFunc)
		local button = Instance.new("TextButton")
		button.Size = UDim2.new(0, 200, 0, 40)
		button.Position = UDim2.new(0, 10, 0, yPos)
		button.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
		button.TextColor3 = Color3.new(1, 1, 1)
		button.Font = Enum.Font.SourceSansBold
		button.TextSize = 20
		button.Text = text
		button.Parent = frame
		button.MouseButton1Click:Connect(toggleFunc)
		return button
	end

	local aimbotBtn = createButton(0, "Aimbot: OFF", function()
		_G.aimbotEnabled = not _G.aimbotEnabled
		aimbotBtn.Text = "Aimbot: " .. (_G.aimbotEnabled and "ON" or "OFF")
	end)

	local visBtn = createButton(0.25, "Visibility Check: OFF", function()
		_G.visibilityCheck = not _G.visibilityCheck
		visBtn.Text = "Visibility Check: " .. (_G.visibilityCheck and "ON" or "OFF")
	end)

	local headBtn = createButton(0.5, "Aim at Head: OFF", function()
		_G.aimAtHead = not _G.aimAtHead
		headBtn.Text = "Aim at Head: " .. (_G.aimAtHead and "ON" or "OFF")
	end)

	local teamBtn = createButton(0.75, "Ignore Teammates: OFF", function()
		_G.ignoreTeammates = not _G.ignoreTeammates
		teamBtn.Text = "Ignore Teammates: " .. (_G.ignoreTeammates and "ON" or "OFF")
	end)
end

-- 🔁 Create GUI Now + on Respawn
createAimbotGui()
LocalPlayer.CharacterAdded:Connect(function()
	task.wait(1)
	createAimbotGui()
end)
