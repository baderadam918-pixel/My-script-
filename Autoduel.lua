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
                waitingForCountdownLeft = 
