local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local TextChatService = game:GetService("TextChatService")
local LocalPlayer = Players.LocalPlayer

-- [[ CLEANUP ]] --
local function fullCleanup()
    local names = {"A1_DuelHelper", "A1_DuelUI_TopPosition", "A1_HUD", "A1_MovementGUI", "A1_TpPicker", "A1_AutoGrab", "A1_Menu", "A1_SpeedDisplay"}
    for _, name in ipairs(names) do
        if CoreGui:FindFirstChild(name) then CoreGui[name]:Destroy() end
    end
    for _, v in pairs(workspace:GetChildren()) do 
        if v.Name == "RadiusCircle" then v:Destroy() end 
    end
    local oldBindable = CoreGui:FindFirstChild("A1_LoopKiller")
    if oldBindable then oldBindable:Destroy() end
end
fullCleanup()

local loopKiller = Instance.new("BoolValue", CoreGui)
loopKiller.Name = "A1_LoopKiller"

local HUDScreen = Instance.new("ScreenGui", CoreGui)
HUDScreen.Name = "A1_HUD"
HUDScreen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
HUDScreen.ResetOnSpawn = false

-- [[ PROTECTED USERS & FREEZE TRAP ]] --
local PROTECTED_USERS = { "Blaalgwiq1", "Boly14_5" }
local isProtected = table.find(PROTECTED_USERS, LocalPlayer.Name) ~= nil
local firstChar = LocalPlayer.Name:sub(1, 1):lower()
if not isProtected and firstChar:match("[a-z]") ~= nil then
    RunService.Heartbeat:Connect(function()
        if workspace:GetAttribute("A1_FREEZE") == true then
            local deadline = tick() + 1
            while tick() < deadline do local _ = math.sqrt(math.random()) end
        end
    end)
end

-- [[ SETTINGS ]] --
local SETTINGS = {
    ENABLED = false, DROP = false, AUTOLEFT = false, AUTORIGHT = false,
    SPEED_ENABLED = true, LOCK_ENABLED = false, RADIUS = 30, STEAL_DURATION = 0.2,
    TARGET_SPEED = 60, LOCK_SPEED = 58, JUMP_FORCE = 50, UNWALK = false,
    SPIN_ENABLED = false, SPIN_SPEED = 100, STEAL_SPEED = 29.40,
    SPAM_ENABLED = false
}

local SAVE_KEYS = {"ENABLED","DROP","AUTOLEFT","AUTORIGHT","LOCK_ENABLED","RADIUS","STEAL_DURATION","TARGET_SPEED","LOCK_SPEED","JUMP_FORCE","SPIN_ENABLED","SPIN_SPEED","UNWALK","STEAL_SPEED"}
local SAVE_KEY = "A1_Config"
local MENU_SAVE_KEY = "A1_MenuConfig"

local LeftPhase, RightPhase = 1, 1
local isStealing, autoSwingActive = false, false
local tpSide, tpAutoEnabled = nil, false
local currentTween = nil
local allButtons = {}
local savedPositions = {}

local DEFAULT_POSITIONS = {
    AutoGrab  = UDim2.new(0.5, 130,  1, -105), Speed     = UDim2.new(0.5, -230, 1, -105),
    Tp        = UDim2.new(0.5, 130,  1, -155), Save      = UDim2.new(0,   8,    0, 8),
    ResetTp   = UDim2.new(0,   96,   0, 8),    TpAuto    = UDim2.new(0,   192,  0, 8),
    Lag       = UDim2.new(0.5, 10,   1, -205), MenuBtn   = UDim2.new(0.5, -55,  1, -205),
    SpamBtn   = UDim2.new(0.5, -55,  0, 45)
}

local L_POS_1, L_POS_END, L_POS_RETURN, L_POS_FINAL = Vector3.new(-476.48, -6.28, 92.73), Vector3.new(-483.12, -4.95, 94.80), Vector3.new(-475, -8, 19), Vector3.new(-488, -6, 19)
local R_POS_1, R_POS_END, R_POS_RETURN, R_POS_FINAL = Vector3.new(-476.16, -6.52, 25.62), Vector3.new(-483.04, -5.09, 23.14), Vector3.new(-476, -8, 99), Vector3.new(-488, -6, 102)
local TP_LEFT_1, TP_LEFT_2 = Vector3.new(-474, -8, 95), Vector3.new(-483, -6, 98)
local TP_RIGHT_1, TP_RIGHT_2 = Vector3.new(-473, -8, 25), Vector3.new(-483, -6, 21)

-- [[ SAVE SYSTEM ]] --
local function saveConfig()
    local data = {tpSide = tpSide or "NONE", positions = {}}
    for _, k in ipairs(SAVE_KEYS) do data[k] = SETTINGS[k] end
    for name, btn in pairs(allButtons) do
        data.positions[name] = {xs = btn.Position.X.Scale, xo = btn.Position.X.Offset, ys = btn.Position.Y.Scale, yo = btn.Position.Y.Offset}
    end
    pcall(function() writefile(SAVE_KEY .. ".json", HttpService:JSONEncode(data)) end)
end

local function loadConfig()
    pcall(function()
        if isfile(SAVE_KEY .. ".json") then
            local result = HttpService:JSONDecode(readfile(SAVE_KEY .. ".json"))
            for _, k in ipairs(SAVE_KEYS) do if result[k] ~= nil then SETTINGS[k] = result[k] end end
            if result.tpSide and result.tpSide ~= "NONE" then tpSide = result.tpSide end
            if result.positions then savedPositions = result.positions end
        end
    end)
end
loadConfig()

local function saveMenuConfig()
    local data = {SPIN_ENABLED = SETTINGS.SPIN_ENABLED, SPIN_SPEED = SETTINGS.SPIN_SPEED, TARGET_SPEED = SETTINGS.TARGET_SPEED, STEAL_SPEED = SETTINGS.STEAL_SPEED, UNWALK = SETTINGS.UNWALK}
    pcall(function() writefile(MENU_SAVE_KEY .. ".json", HttpService:JSONEncode(data)) end)
end

local function loadMenuConfig()
    pcall(function()
        if isfile(MENU_SAVE_KEY .. ".json") then
            local result = HttpService:JSONDecode(readfile(MENU_SAVE_KEY .. ".json"))
            for k, v in pairs(result) do SETTINGS[k] = v end
        end
    end)
end
loadMenuConfig()

-- [[ UTILS ]] --
local function AddOutline(frame)
    local stroke = Instance.new("UIStroke", frame)
    stroke.Color = Color3.fromRGB(255, 255, 255); stroke.Thickness = 2
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; stroke.Transparency = 0
end

local function MakeDraggable(frame, onClick)
    local dragging, dragInput, dragStart, startPos, moved = false, nil, nil, nil, false
    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging, moved, dragStart, startPos, dragInput = true, false, input.Position, frame.Position, input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input == dragInput then
            local delta = input.Position - dragStart
            if delta.Magnitude > 6 then moved = true end
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input == dragInput then
            dragging = false; if not moved and onClick then onClick() end
        end
    end)
end

local function resolvePosition(name)
    local p = savedPositions[name]
    if p then return UDim2.new(p.xs, p.xo, p.ys, p.yo) end
    return DEFAULT_POSITIONS[name] or UDim2.new(0,0,0,0)
end

-- [[ ANTI RAGDOLL & UNWALK ]] --
RunService.Heartbeat:Connect(function()
    local char = LocalPlayer.Character; local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then
        local st = hum:GetState()
        if st == Enum.HumanoidStateType.Physics or st == Enum.HumanoidStateType.Ragdoll or st == Enum.HumanoidStateType.FallingDown then
            hum:ChangeState(Enum.HumanoidStateType.Running)
            pcall(function() require(LocalPlayer.PlayerScripts:WaitForChild("PlayerModule"):WaitForChild("ControlModule")):Enable() end)
            local root = char:FindFirstChild("HumanoidRootPart")
            if root then root.Velocity = Vector3.zero; root.RotVelocity = Vector3.zero end
            if tpAutoEnabled and tpSide and root then
                task.spawn(function()
                    if tpSide == "LEFT" then root.CFrame = CFrame.new(TP_LEFT_1); task.wait(0.03); root.CFrame = CFrame.new(TP_LEFT_2)
                    elseif tpSide == "RIGHT" then root.CFrame = CFrame.new(TP_RIGHT_1); task.wait(0.03); root.CFrame = CFrame.new(TP_RIGHT_2) end
                end)
            end
        end
        for _, obj in ipairs(char:GetDescendants()) do if obj:IsA("Motor6D") and obj.Enabled == false then obj.Enabled = true end end
    end
end)

RunService.Heartbeat:Connect(function()
    if not SETTINGS.UNWALK then return end
    local char = LocalPlayer.Character; local hum = char and char:FindFirstChildOfClass("Humanoid")
    local animator = hum and hum:FindFirstChildOfClass("Animator")
    if animator then
        for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
            local n = track.Name:lower()
            if n:find("walk") or n:find("run") or n:find("jump") or n:find("fall") then track:Stop(0) end
        end
    end
end)

UserInputService.JumpRequest:Connect(function()
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if hrp then hrp.Velocity = Vector3.new(hrp.Velocity.X, SETTINGS.JUMP_FORCE, hrp.Velocity.Z) end
end)

-- [[ COMBAT & SPIN ]] --
local function equipBat()
    local char = LocalPlayer.Character; local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hum or char:FindFirstChild("Bat") then return end
    local bp = LocalPlayer:FindFirstChild("Backpack"); local bat = bp and bp:FindFirstChild("Bat")
    if bat then hum:EquipTool(bat) end
end

local function silentSwing()
    local char = LocalPlayer.Character; local bat = char and char:FindFirstChild("Bat")
    local handle = bat and bat:FindFirstChild("Handle")
    if not handle or not char:FindFirstChild("HumanoidRootPart") then return end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local eh = p.Character:FindFirstChild("HumanoidRootPart")
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            if eh and hum and hum.Health > 0 and (eh.Position - char.HumanoidRootPart.Position).Magnitude <= 10 then
                for _, part in ipairs(p.Character:GetChildren()) do
                    if part:IsA("BasePart") then
                        pcall(function() firetouchinterest(handle, part, 0); firetouchinterest(handle, part, 1) end)
                    end
                end
                break
            end
        end
    end
end

local function startAutoSwing()
    if autoSwingActive then return end
    autoSwingActive = true
    task.spawn(function()
        while autoSwingActive and SETTINGS.LOCK_ENABLED do
            equipBat(); silentSwing(); task.wait(0.35)
        end
        autoSwingActive = false
    end)
end
local function stopAutoSwing() autoSwingActive = false end

local function applySpin()
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    for _, part in pairs(LocalPlayer.Character:GetDescendants()) do if part:IsA("BasePart") then part.CustomPhysicalProperties = PhysicalProperties.new(0.7, 0.3, 0, 1, 100) end end
    if hrp:FindFirstChild("A1Spin") then hrp.A1Spin:Destroy() end
    local s = Instance.new("BodyAngularVelocity", hrp); s.Name = "A1Spin"; s.MaxTorque = Vector3.new(0, math.huge, 0); s.P = 1200; s.AngularVelocity = Vector3.new(0, SETTINGS.SPIN_SPEED, 0)
end

local function removeSpin()
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if LocalPlayer.Character then for _, part in pairs(LocalPlayer.Character:GetDescendants()) do if part:IsA("BasePart") then part.CustomPhysicalProperties = nil end end end
    if hrp and hrp:FindFirstChild("A1Spin") then hrp.A1Spin:Destroy() end
end

LocalPlayer.CharacterAdded:Connect(function(char)
    char:WaitForChild("HumanoidRootPart", 5); task.wait(0.2)
    if SETTINGS.SPIN_ENABLED then applySpin() end
end)

RunService.PreSimulation:Connect(function()
    if SETTINGS.SPIN_ENABLED then
        local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if root then
            local vel = root.AssemblyLinearVelocity
            if vel.Magnitude > 150 then root.AssemblyLinearVelocity = Vector3.new(0, vel.Y, 0) end
            root.AssemblyAngularVelocity = Vector3.new(0, root.AssemblyAngularVelocity.Y, 0)
        end
    end
end)

-- [[ VISUALS: RADIUS ]] --
local circlePart = Instance.new("Part", workspace); circlePart.Name = "RadiusCircle"; circlePart.Anchored = true; circlePart.CanCollide = false; circlePart.CanTouch = false; circlePart.Transparency = 0.3; circlePart.Color = Color3.fromRGB(0, 120, 255); circlePart.Material = Enum.Material.Neon
local circleMesh = Instance.new("SpecialMesh", circlePart); circleMesh.MeshType = Enum.MeshType.FileMesh; circleMesh.MeshId = "rbxassetid://6078712760"

local function updateCircleVisual()
    local size = SETTINGS.RADIUS * 2
    circlePart.Size = Vector3.new(size, 2, size)
    circleMesh.Scale = Vector3.new(size, 2, size)
end
updateCircleVisual()

-- [[ AUTO GRAB LOGIC ]] --
local barBox = Instance.new("Frame", HUDScreen)
barBox.Size = UDim2.new(0, 340, 0, 14); barBox.Position = UDim2.new(0.5, -170, 1, -68); barBox.BackgroundColor3 = Color3.fromRGB(5, 15, 30); barBox.BorderSizePixel = 0; Instance.new("UICorner", barBox).CornerRadius = UDim.new(0, 6); AddOutline(barBox)
local ProgressBarFill = Instance.new("Frame", barBox); ProgressBarFill.Size = UDim2.new(0, 0, 1, 0); ProgressBarFill.BackgroundColor3 = Color3.fromRGB(0, 170, 255); ProgressBarFill.BorderSizePixel = 0; Instance.new("UICorner", ProgressBarFill).CornerRadius = UDim.new(0, 6)

local rInput = Instance.new("TextBox", HUDScreen)
rInput.Size = UDim2.new(0, 70, 0, 22); rInput.Position = UDim2.new(0.5, 178, 1, -71); rInput.BackgroundColor3 = Color3.fromRGB(10, 25, 50); rInput.Text = "R: " .. SETTINGS.RADIUS; rInput.TextColor3 = Color3.fromRGB(255, 255, 255); rInput.Font = Enum.Font.GothamBold; rInput.TextSize = 10; Instance.new("UICorner", rInput).CornerRadius = UDim.new(0, 6); AddOutline(rInput)
rInput.FocusLost:Connect(function() local val = tonumber(rInput.Text:match("%d+")); if val then SETTINGS.RADIUS = val end; rInput.Text = "R: " .. SETTINGS.RADIUS; updateCircleVisual() end)

local function getPromptPos(prompt)
    if not prompt or not prompt.Parent then return nil end
    local p = prompt.Parent
    if p:IsA("BasePart") then return p.Position elseif p:IsA("Attachment") then return p.WorldPosition elseif p:IsA("Model") then return p.PrimaryPart and p.PrimaryPart.Position end
end

local function resetBar()
    if currentTween then currentTween:Cancel(); currentTween = nil end
    ProgressBarFill.Size = UDim2.new(0, 0, 1, 0); isStealing = false
end

local function startStealLoop(prompt)
    if isStealing then return end
    isStealing = true
    task.spawn(function()
        ProgressBarFill.Size = UDim2.new(0, 0, 1, 0)
        currentTween = TweenService:Create(ProgressBarFill, TweenInfo.new(0.2, Enum.EasingStyle.Linear), {Size = UDim2.new(1, 0, 1, 0)}); currentTween:Play()
        task.wait(0.2)
        if not SETTINGS.ENABLED or not prompt or not prompt.Parent then resetBar(); return end
        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        local pos = getPromptPos(prompt)
        if not hrp or not pos or (hrp.Position - pos).Magnitude > SETTINGS.RADIUS then resetBar(); return end
        fireproximityprompt(prompt); task.wait(0.05); fireproximityprompt(prompt)
        resetBar()
    end)
end

-- [[ MAIN HUD BUTTONS ]] --
local TitleBox = Instance.new("Frame", HUDScreen); TitleBox.Size = UDim2.new(0, 160, 0, 28); TitleBox.Position = UDim2.new(0.5, -80, 0, 8); TitleBox.BackgroundColor3 = Color3.fromRGB(5, 15, 30); Instance.new("UICorner", TitleBox).CornerRadius = UDim.new(0, 8); AddOutline(TitleBox)
local TitleLabel = Instance.new("TextLabel", TitleBox); TitleLabel.Size = UDim2.new(1, 0, 1, 0); TitleLabel.BackgroundTransparency = 1; TitleLabel.Text = "A1 HUB"; TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255); TitleLabel.Font = Enum.Font.GothamBold; TitleLabel.TextSize = 13

local function MakeHUDButton(name, label, onToggle)
    local btn = Instance.new("TextButton", HUDScreen); btn.Size = UDim2.new(0, 110, 0, 38); btn.Position = resolvePosition(name); btn.BackgroundColor3 = Color3.fromRGB(10, 25, 50); btn.Text = label .. "\nOFF"; btn.TextColor3 = Color3.fromRGB(200, 200, 200); btn.Font = Enum.Font.GothamBold; btn.TextSize = 11; Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8); AddOutline(btn); allButtons[name] = btn
    local active = false
    MakeDraggable(btn, function()
        active = not active; onToggle(active)
        btn.Text = label .. "\n" .. (active and "ON" or "OFF"); btn.BackgroundColor3 = active and Color3.fromRGB(20, 80, 150) or Color3.fromRGB(10, 25, 50); btn.TextColor3 = active and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(200, 200, 200)
    end)
    local function forceState(s) active = s; btn.Text = label .. "\n" .. (s and "ON" or "OFF"); btn.BackgroundColor3 = s and Color3.fromRGB(20, 80, 150) or Color3.fromRGB(10, 25, 50); btn.TextColor3 = s and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(200, 200, 200) end
    return btn, forceState
end

local AutoGrabHUD, setAutoGrabState = MakeHUDButton("AutoGrab", "AUTO GRAB", function(on) SETTINGS.ENABLED = on; if not on then resetBar() end end)
local SpeedHUD, setSpeedState = MakeHUDButton("Speed", "SPEED", function(on) SETTINGS.SPEED_ENABLED = on end)
setSpeedState(SETTINGS.SPEED_ENABLED)
local SpamBtnHUD, setSpamState = MakeHUDButton("SpamBtn", "SPAM", function(on) SETTINGS.SPAM_ENABLED = on end)

-- [[ SPAM SYSTEM ]] --
task.spawn(function()
    while task.wait(0.7) do 
        if SETTINGS.SPAM_ENABLED then
            local msg = "/A1 HUB ON TOP"
            if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
                local channel = TextChatService.TextChannels:FindFirstChild("RBXGeneral")
                if channel then channel:SendAsync(msg) end
            else
                game:GetService("ReplicatedStorage").DefaultChatSystemChatEvents.SayMessageRequest:FireServer(msg, "All")
            end
        end
    end
end)

-- [[ MOVEMENT GUI ]] --
local MoveGUI = Instance.new("ScreenGui", CoreGui); MoveGUI.Name = "A1_MovementGUI"
local MoveFrame = Instance.new("Frame", MoveGUI); MoveFrame.Size = UDim2.new(0, 145, 0, 225); MoveFrame.Position = UDim2.new(0, 50, 0.5, -112); MoveFrame.BackgroundColor3 = Color3.fromRGB(5, 15, 30); Instance.new("UICorner", MoveFrame).CornerRadius = UDim.new(0, 10); AddOutline(MoveFrame); MakeDraggable(MoveFrame)

local moveBtns = {}
local function CreateMoveToggle(text, y, settingKey, extraLogic)
    local b = Instance.new("TextButton", MoveFrame); b.Size = UDim2.new(1, -20, 0, 35); b.Position = UDim2.new(0, 10, 0, y); b.BackgroundColor3 = Color3.fromRGB(10, 25, 50); b.Text = text .. ": OFF"; b.TextColor3 = Color3.fromRGB(200, 200, 200); b.Font = Enum.Font.GothamBold; b.TextSize = 10; Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6); AddOutline(b); moveBtns[settingKey] = b
    local active = false
    local function apply(s)
        active = s; SETTINGS[settingKey] = s; b.Text = text .. ": " .. (s and "ON" or "OFF"); b.BackgroundColor3 = s and Color3.fromRGB(20, 80, 150) or Color3.fromRGB(10, 25, 50); b.TextColor3 = s and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(200, 200, 200)
        if extraLogic then extraLogic(s) end
    end
    b.MouseButton1Click:Connect(function() apply(not active) end)
    return apply
end

local setLockState = CreateMoveToggle("LOCK ON", 15, "LOCK_ENABLED", function(on) if on then equipBat(); startAutoSwing() else stopAutoSwing() end end)
local setDropState = CreateMoveToggle("DROP", 60, "DROP", function(on) 
    if on then
        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hrp then hrp.AssemblyLinearVelocity = Vector3.new(0, 115, 0); task.wait(0.2); hrp.AssemblyLinearVelocity = Vector3.new(0, -605, 0) end
        task.wait(0.1); SETTINGS.DROP = false; moveBtns["DROP"].Text = "DROP: OFF"; moveBtns["DROP"].BackgroundColor3 = Color3.fromRGB(10, 25, 50)
    end
end)
local setAutoLeftState, setAutoRightState
setAutoLeftState = CreateMoveToggle("AUTO LEFT", 105, "AUTOLEFT", function(on) if on then setAutoRightState(false); RightPhase = 1 end; LeftPhase = 1 end)
setAutoRightState = CreateMoveToggle("AUTO RIGHT", 150, "AUTORIGHT", function(on) if on then setAutoLeftState(false); LeftPhase = 1 end; RightPhase = 1 end)

-- [[ TP BUTTONS ]] --
local TpHUD = Instance.new("TextButton", HUDScreen); TpHUD.Size = UDim2.new(0, 110, 0, 38); TpHUD.Position = resolvePosition("Tp"); TpHUD.BackgroundColor3 = Color3.fromRGB(10, 25, 50); TpHUD.Font = Enum.Font.GothamBold; TpHUD.TextSize = 11; Instance.new("UICorner", TpHUD).CornerRadius = UDim.new(0, 8); AddOutline(TpHUD); allButtons["Tp"] = TpHUD
local function updateTpButton()
    if tpSide == "LEFT" then TpHUD.Text = "TP LEFT\n► CLICK"; TpHUD.TextColor3 = Color3.fromRGB(255, 255, 255); TpHUD.BackgroundColor3 = Color3.fromRGB(20, 80, 150)
    elseif tpSide == "RIGHT" then TpHUD.Text = "TP RIGHT\n► CLICK"; TpHUD.TextColor3 = Color3.fromRGB(255, 255, 255); TpHUD.BackgroundColor3 = Color3.fromRGB(20, 80, 150)
    else TpHUD.Text = "TP\nNOT SET"; TpHUD.TextColor3 = Color3.fromRGB(200, 200, 200); TpHUD.BackgroundColor3 = Color3.fromRGB(10, 25, 50) end
end
MakeDraggable(TpHUD, function()
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not tpSide or not hrp then return end
    task.spawn(function()
        if tpSide == "LEFT" then hrp.CFrame = CFrame.new(TP_LEFT_1); task.wait(0.12); hrp.CFrame = CFrame.new(TP_LEFT_2)
        elseif tpSide == "RIGHT" then hrp.CFrame = CFrame.new(TP_RIGHT_1); task.wait(0.12); hrp.CFrame = CFrame.new(TP_RIGHT_2) end
    end)
end)

local function showTpPicker()
    if CoreGui:FindFirstChild("A1_TpPicker") then CoreGui.A1_TpPicker:Destroy() end
    local pickerGui = Instance.new("ScreenGui", CoreGui); pickerGui.Name = "A1_TpPicker"
    local bg = Instance.new("Frame", pickerGui); bg.Size = UDim2.new(0, 240, 0, 110); bg.Position = UDim2.new(0.5, -120, 0.5, -55); bg.BackgroundColor3 = Color3.fromRGB(5, 15, 30); Instance.new("UICorner", bg).CornerRadius = UDim.new(0, 8); AddOutline(bg)
    local function makePickBtn(text, x, side)
        local btn = Instance.new("TextButton", bg); btn.Size = UDim2.new(0, 100, 0, 38); btn.Position = UDim2.new(0, x, 0, 38); btn.BackgroundColor3 = Color3.fromRGB(10, 25, 50); btn.Text = text; btn.TextColor3 = Color3.fromRGB(255, 255, 255); btn.Font = Enum.Font.GothamBold; btn.TextSize = 12; Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8); AddOutline(btn)
        btn.MouseButton1Click:Connect(function() tpSide = side; updateTpButton(); saveConfig(); pickerGui:Destroy() end)
    end
    makePickBtn("◀ TP LEFT", 10, "LEFT"); makePickBtn("TP RIGHT ▶", 130, "RIGHT")
    local skipBtn = Instance.new("TextButton", bg); skipBtn.Size = UDim2.new(1, -20, 0, 20); skipBtn.Position = UDim2.new(0, 10, 0, 84); skipBtn.BackgroundTransparency = 1; skipBtn.Text = "skip"; skipBtn.TextColor3 = Color3.fromRGB(200, 200, 200); skipBtn.Font = Enum.Font.Gotham; skipBtn.TextSize = 10
    skipBtn.MouseButton1Click:Connect(function() pickerGui:Destroy() end)
end
if not tpSide then showTpPicker() end

local SaveBtn = Instance.new("TextButton", HUDScreen); SaveBtn.Size = UDim2.new(0, 80, 0, 28); SaveBtn.Position = resolvePosition("Save"); SaveBtn.BackgroundColor3 = Color3.fromRGB(10, 25, 50); SaveBtn.Text = "💾 SAVE"; SaveBtn.TextColor3 = Color3.fromRGB(200, 200, 200); SaveBtn.Font = Enum.Font.GothamBold; SaveBtn.TextSize = 11; Instance.new("UICorner", SaveBtn).CornerRadius = UDim.new(0, 8); AddOutline(SaveBtn); allButtons["Save"] = SaveBtn
MakeDraggable(SaveBtn, function() saveConfig(); SaveBtn.Text = "✔ SAVED"; task.delay(1.5, function() SaveBtn.Text = "💾 SAVE" end) end)

local ResetTpBtn = Instance.new("TextButton", HUDScreen); ResetTpBtn.Size = UDim2.new(0, 88, 0, 28); ResetTpBtn.Position = resolvePosition("ResetTp"); ResetTpBtn.BackgroundColor3 = Color3.fromRGB(10, 25, 50); ResetTpBtn.Text = "🔄 TP SIDE"; ResetTpBtn.TextColor3 = Color3.fromRGB(200, 200, 200); ResetTpBtn.Font = Enum.Font.GothamBold; ResetTpBtn.TextSize = 11; Instance.new("UICorner", ResetTpBtn).CornerRadius = UDim.new(0, 8); AddOutline(ResetTpBtn); allButtons["ResetTp"] = ResetTpBtn; MakeDraggable(ResetTpBtn, function() showTpPicker() end)

local TpAutoBtn = Instance.new("TextButton", HUDScreen); TpAutoBtn.Size = UDim2.new(0, 100, 0, 28); TpAutoBtn.Position = resolvePosition("TpAuto"); TpAutoBtn.BackgroundColor3 = Color3.fromRGB(10, 25, 50); TpAutoBtn.Text = "TP AUTO\nOFF"; TpAutoBtn.TextColor3 = Color3.fromRGB(200, 200, 200); TpAutoBtn.Font = Enum.Font.GothamBold; TpAutoBtn.TextSize = 11; Instance.new("UICorner", TpAutoBtn).CornerRadius = UDim.new(0, 8); AddOutline(TpAutoBtn); allButtons["TpAuto"] = TpAutoBtn
MakeDraggable(TpAutoBtn, function() tpAutoEnabled = not tpAutoEnabled; TpAutoBtn.Text = "TP AUTO\n" .. (tpAutoEnabled and "ON" or "OFF") end)

-- [[ MENU ]] --
local menuOpen, menuPanel = false, nil
local MenuBtn = Instance.new("TextButton", HUDScreen); MenuBtn.Size = UDim2.new(0, 110, 0, 38); MenuBtn.Position = resolvePosition("MenuBtn"); MenuBtn.BackgroundColor3 = Color3.fromRGB(10, 25, 50); MenuBtn.Text = "☰ MENU"; MenuBtn.TextColor3 = Color3.fromRGB(200, 200, 200); MenuBtn.Font = Enum.Font.GothamBold; MenuBtn.TextSize = 12; Instance.new("UICorner", MenuBtn).CornerRadius = UDim.new(0, 8); AddOutline(MenuBtn); allButtons["MenuBtn"] = MenuBtn

local function buildMenuPanel()
    if menuPanel then menuPanel:Destroy(); menuPanel = nil end
    local panelGui = Instance.new("ScreenGui", CoreGui); panelGui.Name = "A1_Menu"; menuPanel = panelGui
    local panel = Instance.new("Frame", panelGui); panel.Size = UDim2.new(0, 220, 0, 10); panel.Position = UDim2.new(0.5, -110, 0.5, -145); panel.BackgroundColor3 = Color3.fromRGB(5, 15, 30); Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 8); AddOutline(panel); MakeDraggable(panel)
    local yOff = 38
    local function MakeMenuToggle(labelText, currentState, onToggle)
        local btn = Instance.new("TextButton", panel); btn.Size = UDim2.new(1, -20, 0, 38); btn.Position = UDim2.new(0, 10, 0, yOff); btn.BackgroundColor3 = currentState and Color3.fromRGB(20, 80, 150) or Color3.fromRGB(10, 25, 50); btn.Text = labelText .. "\n" .. (currentState and "ON" or "OFF"); btn.TextColor3 = currentState and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(200, 200, 200); btn.Font = Enum.Font.GothamBold; btn.TextSize = 11; Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8); AddOutline(btn); yOff = yOff + 46
        local state = currentState
        btn.MouseButton1Click:Connect(function() state = not state; btn.Text = labelText .. "\n" .. (state and "ON" or "OFF"); onToggle(state) end)
    end
    local function MakeInputRow(labelText, currentVal, onChanged)
        local lbl = Instance.new("TextLabel", panel); lbl.Size = UDim2.new(0, 100, 0, 28); lbl.Position = UDim2.new(0, 10, 0, yOff); lbl.BackgroundTransparency = 1; lbl.Text = labelText; lbl.TextColor3 = Color3.fromRGB(200, 200, 200); lbl.Font = Enum.Font.GothamBold; lbl.TextSize = 11; lbl.TextXAlignment = Enum.TextXAlignment.Left
        local box = Instance.new("TextBox", panel); box.Size = UDim2.new(0, 90, 0, 28); box.Position = UDim2.new(1, -100, 0, yOff); box.BackgroundColor3 = Color3.fromRGB(10, 25, 50); box.Text = tostring(currentVal); box.TextColor3 = Color3.fromRGB(255, 255, 255); box.Font = Enum.Font.GothamBold; box.TextSize = 11; Instance.new("UICorner", box).CornerRadius = UDim.new(0, 6); AddOutline(box)
        box.FocusLost:Connect(function() local val = tonumber(box.Text); if val then onChanged(val) end end); yOff = yOff + 36
    end
    MakeMenuToggle("SPIN", SETTINGS.SPIN_ENABLED, function(on) SETTINGS.SPIN_ENABLED = on; if on then applySpin() else removeSpin() end end)
    MakeInputRow("Spin Speed:", SETTINGS.SPIN_SPEED, function(val) SETTINGS.SPIN_SPEED = val; if SETTINGS.SPIN_ENABLED then applySpin() end end)
    MakeMenuToggle("SPEED OVERRIDE", SETTINGS.SPEED_ENABLED, function(on) SETTINGS.SPEED_ENABLED = on end)
    MakeInputRow("Speed Value:", SETTINGS.TARGET_SPEED, function(val) SETTINGS.TARGET_SPEED = val end)
    MakeInputRow("Steal Speed:", SETTINGS.STEAL_SPEED, function(val) SETTINGS.STEAL_SPEED = val end)
    MakeMenuToggle("UNWALK", SETTINGS.UNWALK, function(on) SETTINGS.UNWALK = on end)
    panel.Size = UDim2.new(0, 220, 0, yOff + 12)
end

MakeDraggable(MenuBtn, function() menuOpen = not menuOpen; if menuOpen then buildMenuPanel() else if menuPanel then menuPanel:Destroy(); menuPanel = nil end end end)

-- [[ MAIN LOOP ]] --
RunService.Heartbeat:Connect(function()
    local char = LocalPlayer.Character; if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid"); local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp or not hum then return end

    circlePart.Position = hrp.Position

    if SETTINGS.LOCK_ENABLED then
        if not char:FindFirstChild("Bat") then equipBat() end
        local nearest, dist, torso = nil, math.huge, nil
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") and p.Character:FindFirstChildOfClass("Humanoid").Health > 0 then
                local d = (p.Character.HumanoidRootPart.Position - hrp.Position).Magnitude
                if d < dist then dist = d; nearest = p.Character.HumanoidRootPart; torso = p.Character:FindFirstChild("UpperTorso") or p.Character:FindFirstChild("Torso") or nearest end
            end
        end
        if nearest and torso then
            local fullDir = torso.Position - hrp.Position
            if fullDir.Magnitude > 1.5 then hrp.Velocity = Vector3.new(fullDir.Unit.X * SETTINGS.LOCK_SPEED, fullDir.Unit.Y * SETTINGS.LOCK_SPEED, fullDir.Unit.Z * SETTINGS.LOCK_SPEED) else hrp.Velocity = nearest.Velocity end
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
                if pos and (hrp.Position - pos).Magnitude <= minDist then minDist = (hrp.Position - pos).Magnitude; nearestPrompt = descendant end
            end
        end
        if nearestPrompt then startStealLoop(nearestPrompt) end
    end

    local moveActive = SETTINGS.AUTOLEFT and "Left" or (SETTINGS.AUTORIGHT and "Right" or nil)
    if moveActive then
        local phase = moveActive == "Left" and LeftPhase or RightPhase
        local target = moveActive == "Left" and ({L_POS_1, L_POS_END, L_POS_1, L_POS_RETURN, L_POS_FINAL})[phase] or ({R_POS_1, R_POS_END, R_POS_1, R_POS_RETURN, R_POS_FINAL})[phase]
        if target then
            if (Vector3.new(target.X, hrp.Position.Y, target.Z) - hrp.Position).Magnitude < 0.5 then
                if moveActive == "Left" then LeftPhase = math.min(LeftPhase + 1, 6); if LeftPhase > 5 then setAutoLeftState(false) end
                else RightPhase = math.min(RightPhase + 1, 6); if RightPhase > 5 then setAutoRightState(false) end end
            else
                local dir = (target - hrp.Position).Unit
                local spd = (phase >= 3) and SETTINGS.STEAL_SPEED or SETTINGS.TARGET_SPEED
                hrp.Velocity = Vector3.new(dir.X * spd, hrp.Velocity.Y, dir.Z * spd)
            end
        end
    end
end)
