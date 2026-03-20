-- =============================================
-- A1 Hub Auto Duel - With Custom Speed Settings
-- =============================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer

-- ================== CONFIG ==================
local CONFIG = {
    Title = "A1 Hub Auto Duel",
    Credit = "Made by Adam",

    RightWaypoints = {
        Vector3.new(-473.04, -6.99, 29.71),
        Vector3.new(-483.57, -5.10, 18.74),
        Vector3.new(-475.00, -6.99, 26.43),
        Vector3.new(-474.67, -6.94, 105.48),
    },
    LeftWaypoints = {
        Vector3.new(-472.49, -7.00, 90.62),
        Vector3.new(-484.62, -5.10, 100.37),
        Vector3.new(-475.08, -7.00, 93.29),
        Vector3.new(-474.22, -6.96, 16.18),
    },

    -- Default speeds (you can still change these)
    FastSpeed = 60,
    SlowSpeed = 29.4,

    FloatHeight = 8,
    FloatStrength = 15,
    AutoStartDelay = 0.7,
}

-- ================== VARIABLES ==================
local patrolMode = "none"
local floating = false
local currentWaypoint = 1
local heartbeatConn
local waitingForCountdownLeft = false
local waitingForCountdownRight = false

local rightBtn, leftBtn, floatBtn
local fastSpeedBox, slowSpeedBox

-- ================== HELPER FUNCTIONS ==================
local function isCountdownNumber(text)
    local num = tonumber(text)
    return num and num >= 1 and num <= 5, num
end

local function isTimerInCountdown(label)
    if not label then return false end
    local ok, num = isCountdownNumber(label.Text)
    return ok and num >= 1 and num <= 5
end

local function getCurrentSpeed()
    if currentWaypoint >= 3 then
        return CONFIG.SlowSpeed
    else
        return CONFIG.FastSpeed
    end
end

local function getCurrentWaypoints()
    if patrolMode == "right" then return CONFIG.RightWaypoints
    elseif patrolMode == "left" then return CONFIG.LeftWaypoints
    end
    return {}
end

local function startMovement(mode)
    patrolMode = mode
    currentWaypoint = 1

    if mode == "right" then
        rightBtn.Text = "STOP Right"
        TweenService:Create(rightBtn, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromRGB(80, 40, 40)}):Play()
        print("🚀 A1 Hub AutoRight started")
    else
        leftBtn.Text = "STOP Left"
        TweenService:Create(leftBtn, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromRGB(80, 40, 40)}):Play()
        print("🚀 A1 Hub AutoLeft started")
    end
end

-- ================== MOVEMENT LOGIC ==================
local function updateWalking()
    local char = player.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local currentVel = root.AssemblyLinearVelocity

    -- Floating
    if floating then
        local raycastParams = RaycastParams.new()
        raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
        raycastParams.FilterDescendantsInstances = {char}

        local rayResult = workspace:Raycast(root.Position, Vector3.new(0, -50, 0), raycastParams)
        if rayResult then
            local targetY = rayResult.Position.Y + CONFIG.FloatHeight
            local yDiff = targetY - root.Position.Y
            if math.abs(yDiff) > 0.3 then
                root.AssemblyLinearVelocity = Vector3.new(currentVel.X, yDiff * CONFIG.FloatStrength, currentVel.Z)
            else
                root.AssemblyLinearVelocity = Vector3.new(currentVel.X, 0, currentVel.Z)
            end
        end
    end

    -- Patrol
    if patrolMode ~= "none" then
        local waypoints = getCurrentWaypoints()
        if #waypoints == 0 then return end

        local targetPos = waypoints[currentWaypoint]
        local distanceXZ = (Vector3.new(targetPos.X, 0, targetPos.Z) - Vector3.new(root.Position.X, 0, root.Position.Z)).Magnitude

        if distanceXZ > 3 then
            local direction = (Vector3.new(targetPos.X, 0, targetPos.Z) - Vector3.new(root.Position.X, 0, root.Position.Z)).Unit
            local speed = getCurrentSpeed()

            root.AssemblyLinearVelocity = Vector3.new(
                direction.X * speed,
                root.AssemblyLinearVelocity.Y,
                direction.Z * speed
            )
        else
            if currentWaypoint == #waypoints then
                patrolMode = "none"
                currentWaypoint = 1
                waitingForCountdownLeft = false
                waitingForCountdownRight = false

                rightBtn.Text = "AutoRight"
                leftBtn.Text = "AutoLeft"
                TweenService:Create(rightBtn, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromRGB(45, 45, 45)}):Play()
                TweenService:Create(leftBtn, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromRGB(45, 45, 45)}):Play()

                root.AssemblyLinearVelocity = Vector3.new(0, root.AssemblyLinearVelocity.Y, 0)
                print("✅ Path completed")
            else
                currentWaypoint += 1
                print("➡️ Heading to " .. (patrolMode == "right" and "Right" or "Left") .. " spot " .. currentWaypoint)
            end
        end
    end
end

-- ================== GUI ==================
local sg = Instance.new("ScreenGui")
sg.Name = "A1HubAutoDuel"
sg.ResetOnSpawn = false
sg.Parent = player:WaitForChild("PlayerGui")

-- Shadow + MainFrame (same nice look)
local Shadow = Instance.new("ImageLabel")
Shadow.Size = UDim2.new(0, 260, 0, 260)
Shadow.Position = UDim2.new(0.5, -130, 0.5, -130)
Shadow.BackgroundTransparency = 1
Shadow.Image = "rbxassetid://6015897843"
Shadow.ImageColor3 = Color3.new(0,0,0)
Shadow.ImageTransparency = 0.65
Shadow.ScaleType = Enum.ScaleType.Slice
Shadow.SliceCenter = Rect.new(10,10,118,118)
Shadow.Parent = sg

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 250, 0, 250)
MainFrame.Position = UDim2.new(0.5, -125, 0.5, -125)
MainFrame.BackgroundColor3 = Color3.fromRGB(18,18,18)
MainFrame.BackgroundTransparency = 0.05
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = sg

Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 14)
local stroke = Instance.new("UIStroke", MainFrame)
stroke.Thickness = 2.5

local hue = 0
RunService.Heartbeat:Connect(function(dt)
    hue = (hue + dt * 0.8) % 1
    stroke.Color = Color3.fromHSV(hue, 1, 1)
end)

-- Title
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1,0,0,35)
Title.BackgroundTransparency = 1
Title.Text = CONFIG.Title
Title.TextColor3 = Color3.fromRGB(255,255,255)
Title.TextSize = 20
Title.Font = Enum.Font.GothamBlack
Title.Parent = MainFrame

local Credit = Instance.new("TextLabel")
Credit.Size = UDim2.new(1,0,0,16)
Credit.Position = UDim2.new(0,0,0,35)
Credit.BackgroundTransparency = 1
Credit.Text = CONFIG.Credit
Credit.TextColor3 = Color3.fromRGB(160,160,160)
Credit.TextSize = 11
Credit.Parent = MainFrame

-- Speed Settings
local speedLabel = Instance.new("TextLabel")
speedLabel.Size = UDim2.new(0.9,0,0,20)
speedLabel.Position = UDim2.new(0.05,0,0,58)
speedLabel.BackgroundTransparency = 1
speedLabel.Text = "Speed Settings"
speedLabel.TextColor3 = Color3.fromRGB(200,200,200)
speedLabel.TextSize = 14
speedLabel.Font = Enum.Font.GothamSemibold
speedLabel.Parent = MainFrame

-- Fast Speed
local fastLabel = Instance.new("TextLabel")
fastLabel.Size = UDim2.new(0.4,0,0,25)
fastLabel.Position = UDim2.new(0.05,0,0,82)
fastLabel.BackgroundTransparency = 1
fastLabel.Text = "Fast Speed:"
fastLabel.TextColor3 = Color3.fromRGB(255,255,255)
fastLabel.TextXAlignment = Enum.TextXAlignment.Left
fastLabel.Parent = MainFrame

fastSpeedBox = Instance.new("TextBox")
fastSpeedBox.Size = UDim2.new(0.5,0,0,25)
fastSpeedBox.Position = UDim2.new(0.48,0,0,82)
fastSpeedBox.BackgroundColor3 = Color3.fromRGB(35,35,35)
fastSpeedBox.Text = tostring(CONFIG.FastSpeed)
fastSpeedBox.TextColor3 = Color3.fromRGB(255,255,255)
fastSpeedBox.Font = Enum.Font.Gotham
fastSpeedBox.TextSize = 14
fastSpeedBox.Parent = MainFrame
Instance.new("UICorner", fastSpeedBox).CornerRadius = UDim.new(0,6)

fastSpeedBox.FocusLost:Connect(function(enterPressed)
    local num = tonumber(fastSpeedBox.Text)
    if num then
        CONFIG.FastSpeed = math.clamp(num, 10, 300)
        fastSpeedBox.Text = tostring(CONFIG.FastSpeed)
        print("Fast Speed set to: " .. CONFIG.FastSpeed)
    else
        fastSpeedBox.Text = tostring(CONFIG.FastSpeed)
    end
end)

-- Slow Speed
local slowLabel = Instance.new("TextLabel")
slowLabel.Size = UDim2.new(0.4,0,0,25)
slowLabel.Position = UDim2.new(0.05,0,0,115)
slowLabel.BackgroundTransparency = 1
slowLabel.Text = "Slow Speed:"
slowLabel.TextColor3 = Color3.fromRGB(255,255,255)
slowLabel.TextXAlignment = Enum.TextXAlignment.Left
slowLabel.Parent = MainFrame

slowSpeedBox = Instance.new("TextBox")
slowSpeedBox.Size = UDim2.new(0.5,0,0,25)
slowSpeedBox.Position = UDim2.new(0.48,0,0,115)
slowSpeedBox.BackgroundColor3 = Color3.fromRGB(35,35,35)
slowSpeedBox.Text = tostring(CONFIG.SlowSpeed)
slowSpeedBox.TextColor3 = Color3.fromRGB(255,255,255)
slowSpeedBox.Font = Enum.Font.Gotham
slowSpeedBox.TextSize = 14
slowSpeedBox.Parent = MainFrame
Instance.new("UICorner", slowSpeedBox).CornerRadius = UDim.new(0,6)

slowSpeedBox.FocusLost:Connect(function(enterPressed)
    local num = tonumber(slowSpeedBox.Text)
    if num then
        CONFIG.SlowSpeed = math.clamp(num, 10, 300)
        slowSpeedBox.Text = tostring(CONFIG.SlowSpeed)
        print("Slow Speed set to: " .. CONFIG.SlowSpeed)
    else
        slowSpeedBox.Text = tostring(CONFIG.SlowSpeed)
    end
end)

-- Buttons (AutoRight, AutoLeft, Float)
local yOffset = 150

rightBtn = Instance.new("TextButton")
rightBtn.Size = UDim2.new(0.88,0,0,34)
rightBtn.Position = UDim2.new(0.06,0,0,yOffset)
rightBtn.BackgroundColor3 = Color3.fromRGB(45,45,45)
rightBtn.Text = "AutoRight"
rightBtn.TextColor3 = Color3.fromRGB(255,255,255)
rightBtn.TextSize = 13
rightBtn.Font = Enum.Font.GothamBold
rightBtn.AutoButtonColor = false
rightBtn.Parent = MainFrame
Instance.new("UICorner", rightBtn).CornerRadius = UDim.new(0,9)

leftBtn = Instance.new("TextButton")
leftBtn.Size = UDim2.new(0.88,0,0,34)
leftBtn.Position = UDim2.new(0.06,0,0,yOffset + 42)
leftBtn.BackgroundColor3 = Color3.fromRGB(45,45,45)
leftBtn.Text = "AutoLeft"
leftBtn.TextColor3 = Color3.fromRGB(255,255,255)
leftBtn.TextSize = 13
leftBtn.Font = Enum.Font.GothamBold
leftBtn.AutoButtonColor = false
leftBtn.Parent = MainFrame
Instance.new("UICorner", leftBtn).CornerRadius = UDim.new(0,9)

floatBtn = Instance.new("TextButton")
floatBtn.Size = UDim2.new(0.88,0,0,34)
floatBtn.Position = UDim2.new(0.06,0,0,yOffset + 84)
floatBtn.BackgroundColor3 = Color3.fromRGB(45,45,45)
floatBtn.Text = "Float OFF"
floatBtn.TextColor3 = Color3.fromRGB(255,255,255)
floatBtn.TextSize = 13
floatBtn.Font = Enum.Font.GothamBold
floatBtn.AutoButtonColor = false
floatBtn.Parent = MainFrame
Instance.new("UICorner", floatBtn).CornerRadius = UDim.new(0,9)

-- Hover effects
local function addHover(btn, normal, hover)
    btn.MouseEnter:Connect(function() TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = hover}):Play() end)
    btn.MouseLeave:Connect(function() TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = normal}):Play() end)
end

addHover(rightBtn, Color3.fromRGB(45,45,45), Color3.fromRGB(70,70,70))
addHover(leftBtn, Color3.fromRGB(45,45,45), Color3.fromRGB(70,70,70))
addHover(floatBtn, Color3.fromRGB(45,45,45), Color3.fromRGB(70,70,70))

-- Button Functions (same as before)
rightBtn.MouseButton1Click:Connect(function()
    if patrolMode == "right" or waitingForCountdownRight then
        patrolMode = "none"
        waitingForCountdownRight = false
        rightBtn.Text = "AutoRight"
        TweenService:Create(rightBtn, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromRGB(45,45,45)}):Play()
    else
        local label = nil
        pcall(function() label = player.PlayerGui:FindFirstChild("DuelsMachineTopFrame", true):FindFirstChild("Label", true) end)
        if label and isTimerInCountdown(label) then
            waitingForCountdownRight = true
            rightBtn.Text = "Waiting..."
            TweenService:Create(rightBtn, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromRGB(255,200,50)}):Play()
        else
            startMovement("right")
        end
    end
end)

leftBtn.MouseButton1Click:Connect(function()
    if patrolMode == "left" or waitingForCountdownLeft then
        patrolMode = "none"
        waitingForCountdownLeft = false
        leftBtn.Text = "AutoLeft"
        TweenService:Create(leftBtn, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromRGB(45,45,45)}):Play()
    else
        local label = nil
        pcall(function() label = player.PlayerGui:FindFirstChild("DuelsMachineTopFrame", true):FindFirstChild("Label", true) end)
        if label and isTimerInCountdown(label) then
            waitingForCountdownLeft = true
            leftBtn.Text = "Waiting..."
            TweenService:Create(leftBtn, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromRGB(255,200,50)}):Play()
        else
            startMovement("left")
        end
    end
end)

floatBtn.MouseButton1Click:Connect(function()
    floating = not floating
    if floating then
        floatBtn.Text = "Float ON"
        floatBtn.BackgroundColor3 = Color3.fromRGB(40,80,40)
    else
        floatBtn.Text = "Float OFF"
        floatBtn.BackgroundColor3 = Color3.fromRGB(45,45,45)
        local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if root then root.AssemblyLinearVelocity = Vector3.new(root.AssemblyLinearVelocity.X, 0, root.AssemblyLinearVelocity.Z) end
    end
end)

-- Core Loop
heartbeatConn = RunService.Heartbeat:Connect(updateWalking)

-- Character Reset
player.CharacterAdded:Connect(function()
    task.wait(1)
    patrolMode = "none"
    currentWaypoint = 1
    waitingForCountdownLeft = false
    waitingForCountdownRight = false
    floating = false
    rightBtn.Text = "AutoRight"
    leftBtn.Text = "AutoLeft"
    floatBtn.Text = "Float OFF"
    rightBtn.BackgroundColor3 = Color3.fromRGB(45,45,45)
    leftBtn.BackgroundColor3 = Color3.fromRGB(45,45,45)
    floatBtn.BackgroundColor3 = Color3.fromRGB(45,45,45)
end)

-- Cleanup
sg.Destroying:Connect(function()
    if heartbeatConn then heartbeatConn:Disconnect() end
end)

-- Countdown Detection
spawn(function()
    local label = nil
    pcall(function() label = player.PlayerGui:FindFirstChild("DuelsMachineTopFrame", true):FindFirstChild("Label", true) end)
    if label then
        label:GetPropertyChangedSignal("Text"):Connect(function()
            local ok, num = isCountdownNumber(label.Text)
            if ok and num == 1 then
                task.wait(CONFIG.AutoStartDelay)
                if waitingForCountdownLeft then
                    waitingForCountdownLeft = false
                    startMovement("left")
                end
                if waitingForCountdownRight then
                    waitingForCountdownRight = false
                    startMovement("right")
                end
            end
        end)
    end
end)

print("✅ A1 Hub Auto Duel loaded! Change speeds in the GUI.")
