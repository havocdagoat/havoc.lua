-- leaked by https://discord.gg/WfTDsBPR9n join for more sources

repeat task.wait() until game:IsLoaded()

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local TweenService      = game:GetService("TweenService")
local SoundService      = game:GetService("SoundService")
local Lighting          = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService       = game:GetService("HttpService")
local Player            = Players.LocalPlayer

local function waitForCharacter()
    local char = Player.Character
    if char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChildOfClass("Humanoid") then return char end
    return Player.CharacterAdded:Wait()
end
task.spawn(waitForCharacter)

if not getgenv then getgenv = function() return _G end end

-- ============================================================
-- STATE
-- ============================================================
local ConfigFileName = "HAVOCHUB_DUELS_Config.json"

local Enabled = {
    SpeedBoost         = false,
    AntiRagdoll        = false,
    SpinBot            = false,
    SpeedWhileStealing = false,
    AutoSteal          = false,
    Unwalk             = false,
    Optimizer          = false,
    Galaxy             = false,
    SpamBat            = false,
    AutoDisableSpeed   = true,
    AutoWalkEnabled    = false,
    AutoRightEnabled   = false,
    ScriptUserESP      = true,
    InfiniteJump       = false,
    NoDie              = false,
    Aimbot             = false,
    Float              = false,
    FullAutoDuel       = false,
}

local Values = {
    BoostSpeed           = 30,
    SpinSpeed            = 30,
    StealingSpeedValue   = 29,
    STEAL_RADIUS         = 20,
    STEAL_DURATION       = 1.3,
    DEFAULT_GRAVITY      = 196.2,
    GalaxyGravityPercent = 70,
    HOP_POWER            = 35,
    HOP_COOLDOWN         = 0.08,
    FOV                  = 70,
    FloatHeight          = 8,
}
-- AUTO LEFT / RIGHT POSITIONS
local POSITION_L1 = Vector3.new(-476.48, -6.28, 92.73)
local POSITION_L2 = Vector3.new(-483.12, -4.95, 94.80)

local POSITION_R1 = Vector3.new(-476.16, -6.52, 25.62)
local POSITION_R2 = Vector3.new(-483.04, -5.09, 23.14)

local autoLeftPhase = 1
local autoRightPhase = 1

local autoLeftConnection = nil
local autoRightConnection = nil
local KEYBINDS = {
    SPEED       = Enum.KeyCode.V,
    SPIN        = Enum.KeyCode.N,
    GALAXY      = Enum.KeyCode.M,
    AUTOLEFT    = Enum.KeyCode.Z,
    AUTORIGHT   = Enum.KeyCode.C,
    ANTIRAGDOLL    = Enum.KeyCode.Unknown,
    AIMBOT         = Enum.KeyCode.Unknown,
    FLOAT          = Enum.KeyCode.Unknown,
    FULLAUTODUEL   = Enum.KeyCode.Unknown,
}

-- ============================================================
-- CONFIG
-- ============================================================
local function SaveConfig()
    local data = {}
    for k,v in pairs(Enabled)  do data[k]         = v end
    for k,v in pairs(Values)   do data[k]         = v end
    for k,v in pairs(KEYBINDS) do data["KEY_"..k] = v.Name end
    local ok = false
    if writefile then
        pcall(function() writefile(ConfigFileName, HttpService:JSONEncode(data)); ok=true end)
    end
    return ok
end

local function LoadConfig()
    pcall(function()
        if readfile and isfile and isfile(ConfigFileName) then
            local data = HttpService:JSONDecode(readfile(ConfigFileName))
            if data then
                for k,v in pairs(data) do
                    if Enabled[k] ~= nil then Enabled[k] = v end
                    if Values[k]  ~= nil then Values[k]  = v end
                end
                for k in pairs(KEYBINDS) do
                    local key = "KEY_"..k
                    if data[key] then
                        local ok,kc = pcall(function() return Enum.KeyCode[data[key]] end)
                        if ok and kc then KEYBINDS[k] = kc end
                    end
                end
            end
        end
    end)
end
LoadConfig()

-- ============================================================
-- BACKEND
-- ============================================================
local Connections        = { infiniteJump = {heartbeat=nil,jumpRequest=nil} }
local lastBatSwing       = 0
local BAT_SWING_COOLDOWN = 0.12

local SlapList = {
    {1,"Bat"},{2,"Slap"},{3,"Iron Slap"},{4,"Gold Slap"},
    {5,"Diamond Slap"},{6,"Emerald Slap"},{7,"Ruby Slap"},
    {8,"Dark Matter Slap"},{9,"Flame Slap"},{10,"Nuclear Slap"},
    {11,"Galaxy Slap"},{12,"Glitched Slap"},
}

local function getNearestPlayer()
    local c = Player.Character if not c then return nil end
    local h = c:FindFirstChild("HumanoidRootPart") if not h then return nil end
    local nearest, dist = nil, math.huge
    for _,p in ipairs(Players:GetPlayers()) do
        if p ~= Player and p.Character then
            local oh = p.Character:FindFirstChild("HumanoidRootPart")
            if oh then local d=(h.Position-oh.Position).Magnitude if d<dist then dist=d; nearest=p end end
        end
    end
    return nearest
end

local function findBat()
    local c = Player.Character if not c then return nil end
    local bp = Player:FindFirstChildOfClass("Backpack")
    for _,ch in ipairs(c:GetChildren()) do
        if ch:IsA("Tool") and ch.Name:lower():find("bat") then return ch end
    end
    if bp then
        for _,ch in ipairs(bp:GetChildren()) do
            if ch:IsA("Tool") and ch.Name:lower():find("bat") then return ch end
        end
    end
    for _,i in ipairs(SlapList) do
        local t = c:FindFirstChild(i[2]) or (bp and bp:FindFirstChild(i[2]))
        if t then return t end
    end
    return nil
end

local function startSpamBat()
    if Connections.spamBat then return end
    Connections.spamBat = RunService.Heartbeat:Connect(function()
        if not Enabled.SpamBat then return end
        local c = Player.Character if not c then return end
        local bat = findBat() if not bat then return end
        if bat.Parent ~= c then bat.Parent = c end
        local now = tick()
        if now - lastBatSwing < BAT_SWING_COOLDOWN then return end
        lastBatSwing = now
        pcall(function() bat:Activate() end)
    end)
end
local function stopSpamBat()
    if Connections.spamBat then Connections.spamBat:Disconnect(); Connections.spamBat=nil end
end

local spamBatCircle, spamBatCircleConn
local function createSpamBatCircle()
    if spamBatCircle then spamBatCircle:Destroy(); spamBatCircle=nil end
    local c = Player.Character if not c then return end
    local hrp = c:FindFirstChild("HumanoidRootPart") if not hrp then return end
    local circle = Instance.new("Part")
    circle.Name="ZAY_SpamBatCircle"; circle.Anchored=true; circle.CanCollide=false
    circle.CastShadow=false; circle.Material=Enum.Material.Neon
    circle.Color=Color3.fromRGB(200,200,200); circle.Shape=Enum.PartType.Cylinder
    circle.Size=Vector3.new(0.08,20,20); circle.Transparency=0.18; circle.Parent=workspace
    spamBatCircle = circle
end
local function removeSpamBatCircle()
    if spamBatCircle then spamBatCircle:Destroy(); spamBatCircle=nil end
    if spamBatCircleConn then spamBatCircleConn:Disconnect(); spamBatCircleConn=nil end
end
local function startSpamBatCircle()
    removeSpamBatCircle(); createSpamBatCircle()
    spamBatCircleConn = RunService.Heartbeat:Connect(function()
        if not Enabled.SpamBat then removeSpamBatCircle(); return end
        local c = Player.Character if not c then return end
        local hrp = c:FindFirstChild("HumanoidRootPart") if not hrp then return end
        if not spamBatCircle or not spamBatCircle.Parent then createSpamBatCircle(); return end
        spamBatCircle.CFrame = CFrame.new(hrp.Position.X,hrp.Position.Y-3.2,hrp.Position.Z)*CFrame.Angles(0,0,math.rad(90))
    end)
end

local spinBAV
local function startSpinBot()
    local c = Player.Character if not c then return end
    local hrp = c:FindFirstChild("HumanoidRootPart") if not hrp then return end
    if spinBAV then spinBAV:Destroy(); spinBAV=nil end
    for _,v in pairs(hrp:GetChildren()) do if v.Name=="SpinBAV" then v:Destroy() end end
    spinBAV = Instance.new("BodyAngularVelocity")
    spinBAV.Name="SpinBAV"; spinBAV.MaxTorque=Vector3.new(0,math.huge,0)
    spinBAV.AngularVelocity=Vector3.new(0,Values.SpinSpeed,0); spinBAV.Parent=hrp
end
local function stopSpinBot()
    if spinBAV then spinBAV:Destroy(); spinBAV=nil end
    local c = Player.Character
    if c then local hrp=c:FindFirstChild("HumanoidRootPart") if hrp then for _,v in pairs(hrp:GetChildren()) do if v.Name=="SpinBAV" then v:Destroy() end end end end
end

local AutoWalkEnabled  = false
local AutoRightEnabled = false
local AutoLeftEnabled  = false
RunService.Heartbeat:Connect(function()
    if Enabled.SpinBot and spinBAV then
        spinBAV.AngularVelocity = Player:GetAttribute("Stealing") and Vector3.new(0,0,0) or Vector3.new(0,Values.SpinSpeed,0)
    end
end)

local galaxyVectorForce, galaxyAttachment
local galaxyEnabled  = false
local hopsEnabled    = false
local lastHopTime    = 0
local spaceHeld      = false
local originalJumpPower = 50

local function captureJumpPower()
    local c = Player.Character if not c then return end
    local hum = c:FindFirstChildOfClass("Humanoid")
    if hum and hum.JumpPower > 0 then originalJumpPower = hum.JumpPower end
end
task.spawn(function() task.wait(1); captureJumpPower() end)
Player.CharacterAdded:Connect(function() task.wait(1); captureJumpPower() end)

local function setupGalaxyForce()
    pcall(function()
        local c = Player.Character if not c then return end
        local h = c:FindFirstChild("HumanoidRootPart") if not h then return end
        if galaxyVectorForce then galaxyVectorForce:Destroy() end
        if galaxyAttachment  then galaxyAttachment:Destroy()  end
        galaxyAttachment = Instance.new("Attachment"); galaxyAttachment.Parent = h
        galaxyVectorForce = Instance.new("VectorForce")
        galaxyVectorForce.Attachment0 = galaxyAttachment
        galaxyVectorForce.ApplyAtCenterOfMass = true
        galaxyVectorForce.RelativeTo = Enum.ActuatorRelativeTo.World
        galaxyVectorForce.Force = Vector3.new(0,0,0); galaxyVectorForce.Parent = h
    end)
end
local function updateGalaxyForce()
    if not galaxyEnabled or not galaxyVectorForce then return end
    local c = Player.Character if not c then return end
    local mass = 0
    for _,p in ipairs(c:GetDescendants()) do if p:IsA("BasePart") then mass+=p:GetMass() end end
    local tg = Values.DEFAULT_GRAVITY*(Values.GalaxyGravityPercent/100)
    galaxyVectorForce.Force = Vector3.new(0,mass*(Values.DEFAULT_GRAVITY-tg)*0.95,0)
end
local function adjustGalaxyJump()
    pcall(function()
        local c = Player.Character if not c then return end
        local hum = c:FindFirstChildOfClass("Humanoid") if not hum then return end
        if not galaxyEnabled then hum.JumpPower=originalJumpPower; return end
        local ratio = math.sqrt((Values.DEFAULT_GRAVITY*(Values.GalaxyGravityPercent/100))/Values.DEFAULT_GRAVITY)
        hum.JumpPower = originalJumpPower*ratio
    end)
end
local function doMiniHop()
    if not hopsEnabled then return end
    pcall(function()
        local c = Player.Character if not c then return end
        local h = c:FindFirstChild("HumanoidRootPart")
        local hum = c:FindFirstChildOfClass("Humanoid")
        if not h or not hum then return end
        if tick()-lastHopTime < Values.HOP_COOLDOWN then return end
        lastHopTime = tick()
        if hum.FloorMaterial == Enum.Material.Air then
            h.AssemblyLinearVelocity = Vector3.new(h.AssemblyLinearVelocity.X,Values.HOP_POWER,h.AssemblyLinearVelocity.Z)
        end
    end)
end
local function startGalaxy() galaxyEnabled=true; hopsEnabled=true; setupGalaxyForce(); adjustGalaxyJump() end
local function stopGalaxy()
    galaxyEnabled=false; hopsEnabled=false
    if galaxyVectorForce then galaxyVectorForce:Destroy(); galaxyVectorForce=nil end
    if galaxyAttachment  then galaxyAttachment:Destroy();  galaxyAttachment=nil  end
    adjustGalaxyJump()
end

RunService.Heartbeat:Connect(function()
    if hopsEnabled and spaceHeld then doMiniHop() end
    if galaxyEnabled then updateGalaxyForce() end
end)

local function getMovementDirection()
    local c = Player.Character if not c then return Vector3.zero end
    local hum = c:FindFirstChildOfClass("Humanoid")
    return hum and hum.MoveDirection or Vector3.zero
end

local function startSpeedBoost()
    if Connections.speed then return end
    Connections.speed = RunService.Heartbeat:Connect(function()
        if not Enabled.SpeedBoost then return end
        if Player:GetAttribute("Stealing") then return end
        pcall(function()
            local c = Player.Character if not c then return end
            local h = c:FindFirstChild("HumanoidRootPart") if not h then return end
            local md = getMovementDirection()
            if md.Magnitude > 0.1 then
                h.AssemblyLinearVelocity = Vector3.new(md.X*Values.BoostSpeed,h.AssemblyLinearVelocity.Y,md.Z*Values.BoostSpeed)
            end
        end)
    end)
end
local function stopSpeedBoost()
    if Connections.speed then Connections.speed:Disconnect(); Connections.speed=nil end
end

-- ============================================================
-- FLOAT BACKEND
--
-- Simple invisible-ground float:
--   HOVERING  → hold player at FloatHeight above real ground.
--   JUMPING   → zero out float force completely, let physics
--               (including Galaxy gravity) do the whole arc naturally.
--   LANDING   → once descending and back near float level, resume hover.
--               Hard clamp stops player sinking below float height.
-- ============================================================
local floatAttachment   = nil
local floatVectorForce  = nil
local floatInfJumpConn  = nil
local floatMassCache    = 0
local floatLastMassTime = 0
local FLOAT_MASS_INTERVAL = 2

local FLOAT_KP       = 380   -- spring toward float height (tune if too bouncy/slow)
local FLOAT_KD       = 70    -- velocity damping
local FLOAT_DEADZONE = 0.08

local floatJumping = false

local function getCharacterMassFloat(char)
    local mass = 0
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then mass = mass + part:GetMass() end
    end
    return mass
end

local function setupFloatObjects(char)
    if floatVectorForce then floatVectorForce:Destroy(); floatVectorForce = nil end
    if floatAttachment  then floatAttachment:Destroy();  floatAttachment  = nil end
    local hrp = char and char:FindFirstChild("HumanoidRootPart") if not hrp then return end
    floatAttachment        = Instance.new("Attachment")
    floatAttachment.Name   = "ZAY_FloatAttachment"
    floatAttachment.Parent = hrp
    floatVectorForce                    = Instance.new("VectorForce")
    floatVectorForce.Name               = "ZAY_FloatForce"
    floatVectorForce.Attachment0        = floatAttachment
    floatVectorForce.ApplyAtCenterOfMass = true
    floatVectorForce.RelativeTo         = Enum.ActuatorRelativeTo.World
    floatVectorForce.Force              = Vector3.new(0, 0, 0)
    floatVectorForce.Parent             = hrp
end

local function startFloat()
    if Connections.float then return end
    local char = Player.Character if not char then return end
    setupFloatObjects(char)
    floatMassCache    = getCharacterMassFloat(char)
    floatLastMassTime = tick()
    floatJumping      = false

    -- Mark jump start so we release float force for the whole arc
    if floatInfJumpConn then floatInfJumpConn:Disconnect() end
    floatInfJumpConn = UserInputService.JumpRequest:Connect(function()
        if not Enabled.Float then return end
        floatJumping = true
    end)

    Connections.float = RunService.Heartbeat:Connect(function()
        if not Enabled.Float then return end
        pcall(function()
            local c   = Player.Character if not c then return end
            local hrp = c:FindFirstChild("HumanoidRootPart") if not hrp then return end
            if not floatVectorForce or not floatVectorForce.Parent then setupFloatObjects(c) end

            local now = tick()
            if now - floatLastMassTime > FLOAT_MASS_INTERVAL then
                floatMassCache    = getCharacterMassFloat(c)
                floatLastMassTime = now
            end

            local velY = hrp.AssemblyLinearVelocity.Y

            -- Raycast to real ground below
            local rp = RaycastParams.new()
            rp.FilterDescendantsInstances = {c}
            rp.FilterType = Enum.RaycastFilterType.Exclude
            local ray     = workspace:Raycast(hrp.Position, Vector3.new(0, -500, 0), rp)
            local groundY = ray and ray.Position.Y or (hrp.Position.Y - Values.FloatHeight)
            local targetY = groundY + Values.FloatHeight
            local diff    = targetY - hrp.Position.Y  -- positive = below target

            -- ── JUMPING: force = 0, let all physics run freely ──────────────
            -- floatJumping stays true while still going up OR
            -- while still above float level on the way down.
            if floatJumping then
                if velY > 0 then
                    -- Still ascending — hands off completely
                    floatVectorForce.Force = Vector3.new(0, 0, 0)
                    return
                else
                    -- Descending — stay hands-off until we reach float height
                    if hrp.Position.Y > targetY + 0.3 then
                        floatVectorForce.Force = Vector3.new(0, 0, 0)
                        return
                    else
                        -- Back at float level — stop jump mode, clamp, resume hover
                        floatJumping = false
                        hrp.AssemblyLinearVelocity = Vector3.new(
                            hrp.AssemblyLinearVelocity.X, 0,
                            hrp.AssemblyLinearVelocity.Z
                        )
                    end
                end
            end

            -- ── HOVERING: PD controller holds float height ──────────────────
            local gravComp = floatMassCache * workspace.Gravity

            -- Deadzone: perfectly still, just cancel gravity
            if math.abs(diff) < FLOAT_DEADZONE and math.abs(velY) < 0.3 then
                floatVectorForce.Force = Vector3.new(0, gravComp, 0)
                return
            end

            local pdForce = floatMassCache * (FLOAT_KP * diff - FLOAT_KD * velY)
            floatVectorForce.Force = Vector3.new(0, gravComp + pdForce, 0)

            -- Hard floor: never go below float height
            if hrp.Position.Y < targetY and velY < 0 then
                hrp.AssemblyLinearVelocity = Vector3.new(
                    hrp.AssemblyLinearVelocity.X, 0, hrp.AssemblyLinearVelocity.Z
                )
            end
        end)
    end)
end

local function stopFloat()
    if Connections.float then Connections.float:Disconnect(); Connections.float = nil end
    if floatInfJumpConn  then floatInfJumpConn:Disconnect();  floatInfJumpConn  = nil end
    if floatVectorForce  then floatVectorForce:Destroy();     floatVectorForce  = nil end
    if floatAttachment   then floatAttachment:Destroy();      floatAttachment   = nil end
    pcall(function()
        local c   = Player.Character if not c then return end
        local hum = c:FindFirstChildOfClass("Humanoid")
        if hum then
            if galaxyEnabled then adjustGalaxyJump() else hum.JumpPower = originalJumpPower end
        end
    end)
end

-- ============================================================

local POSITION_1  = Vector3.new(-476.48,-6.28, 92.73)
local POSITION_2  = Vector3.new(-483.12,-4.95, 94.80)
local POSITION_R1 = Vector3.new(-476.16,-6.52, 25.62)
local POSITION_R2 = Vector3.new(-483.04,-5.09, 23.14)
local autoWalkPhase  = 1
local autoRightPhase = 1
local autoWalkConnection, autoRightConnection

local coordESPFolder = Instance.new("Folder",workspace); coordESPFolder.Name="ANTILOSER_CoordESP"
local function createCoordMarker(pos,lbl,col)
    local dot = Instance.new("Part",coordESPFolder)
    dot.Anchored=true; dot.CanCollide=false; dot.CastShadow=false
    dot.Material=Enum.Material.Neon; dot.Color=col; dot.Shape=Enum.PartType.Ball
    dot.Size=Vector3.new(1,1,1); dot.Position=pos; dot.Transparency=0.2
    local bb=Instance.new("BillboardGui",dot); bb.AlwaysOnTop=true; bb.Size=UDim2.new(0,100,0,20)
    bb.StudsOffset=Vector3.new(0,2,0); bb.MaxDistance=300
    local tx=Instance.new("TextLabel",bb); tx.Size=UDim2.new(1,0,1,0)
    tx.BackgroundTransparency=1; tx.Text=lbl; tx.TextColor3=col
    tx.TextStrokeColor3=Color3.fromRGB(0,0,0); tx.TextStrokeTransparency=0
    tx.Font=Enum.Font.GothamBold; tx.TextSize=12
end
createCoordMarker(POSITION_1,  "L1",    Color3.fromRGB(200,200,200))
createCoordMarker(POSITION_2,  "L END", Color3.fromRGB(160,160,160))
createCoordMarker(POSITION_R1, "R1",    Color3.fromRGB(220,220,220))
createCoordMarker(POSITION_R2, "R END", Color3.fromRGB(180,180,180))

local function faceSouth()
    local c=Player.Character if not c then return end
    local h=c:FindFirstChild("HumanoidRootPart") if not h then return end
    h.CFrame=CFrame.new(h.Position)*CFrame.Angles(0,0,0)
    local cam=workspace.CurrentCamera
    if cam then cam.CFrame=CFrame.new(h.Position.X,h.Position.Y+5,h.Position.Z-12)*CFrame.Angles(math.rad(-15),0,0) end
end
local function faceNorth()
    local c=Player.Character if not c then return end
    local h=c:FindFirstChild("HumanoidRootPart") if not h then return end
    h.CFrame=CFrame.new(h.Position)*CFrame.Angles(0,math.rad(180),0)
    local cam=workspace.CurrentCamera
    if cam then cam.CFrame=CFrame.new(h.Position.X,h.Position.Y+2,h.Position.Z+12)*CFrame.Angles(0,math.rad(180),0) end
end

local function startAutoWalk()
    if autoWalkConnection then autoWalkConnection:Disconnect() end
    autoWalkPhase=1
    autoWalkConnection = RunService.Heartbeat:Connect(function()
        if not AutoWalkEnabled then return end
        local c=Player.Character if not c then return end
        local h=c:FindFirstChild("HumanoidRootPart"); local hum=c:FindFirstChildOfClass("Humanoid")
        if not h or not hum then return end
        local target = autoWalkPhase==1 and POSITION_1 or POSITION_2
        local dist = (Vector3.new(target.X,h.Position.Y,target.Z)-h.Position).Magnitude
        if dist < 1 then
            if autoWalkPhase==1 then autoWalkPhase=2; return end
            hum:Move(Vector3.zero,false); h.AssemblyLinearVelocity=Vector3.new(0,0,0)
            AutoWalkEnabled=false; Enabled.AutoWalkEnabled=false
            if VisualSetters and VisualSetters.AutoWalkEnabled then VisualSetters.AutoWalkEnabled(false,true) end
            if autoWalkConnection then autoWalkConnection:Disconnect(); autoWalkConnection=nil end
            if onAutoLeftDone then onAutoLeftDone() end
            faceSouth(); return
        end
        local dir=(target-h.Position); local md=Vector3.new(dir.X,0,dir.Z).Unit
        hum:Move(md,false); h.AssemblyLinearVelocity=Vector3.new(md.X*Values.BoostSpeed,h.AssemblyLinearVelocity.Y,md.Z*Values.BoostSpeed)
    end)
end
local function stopAutoWalk()
    if autoWalkConnection then autoWalkConnection:Disconnect(); autoWalkConnection=nil end
    autoWalkPhase=1
    local c=Player.Character if c then local hum=c:FindFirstChildOfClass("Humanoid") if hum then hum:Move(Vector3.zero,false) end end
end
local function startAutoLeft()
local function stopAutoLeft()
    if autoLeftConnection then
        autoLeftConnection:Disconnect()
        autoLeftConnection = nil
    end
end
    if autoLeftConnection then autoLeftConnection:Disconnect() end
    autoLeftPhase = 1

    autoLeftConnection = RunService.Heartbeat:Connect(function()

        if not AutoLeftEnabled then return end

        local c = Player.Character
        if not c then return end

        local h = c:FindFirstChild("HumanoidRootPart")
        local hum = c:FindFirstChildOfClass("Humanoid")

        if not h or not hum then return end

        local target = autoLeftPhase == 1 and POSITION_L1 or POSITION_L2

        local dist = (Vector3.new(target.X, h.Position.Y, target.Z) - h.Position).Magnitude

        if dist < 1.5 then
            if autoLeftPhase == 1 then
                autoLeftPhase = 2
            else
                hum:Move(Vector3.zero,false)
                h.AssemblyLinearVelocity = Vector3.new(0,0,0)

                AutoLeftEnabled = false

                if autoLeftConnection then
                    autoLeftConnection:Disconnect()
                    autoLeftConnection = nil
                end

                return
            end
        end

        local dir = (target - h.Position)
        local md = Vector3.new(dir.X,0,dir.Z).Unit

        hum:Move(md,false)

        h.AssemblyLinearVelocity = Vector3.new(
            md.X * Values.BoostSpeed,
            h.AssemblyLinearVelocity.Y,
            md.Z * Values.BoostSpeed
        )

    end)

end
local function startAutoRight()
    if autoRightConnection then autoRightConnection:Disconnect() end
    autoRightPhase=1
    autoRightConnection = RunService.Heartbeat:Connect(function()
        if not AutoRightEnabled then return end
        local c=Player.Character if not c then return end
        local h=c:FindFirstChild("HumanoidRootPart"); local hum=c:FindFirstChildOfClass("Humanoid")
        if not h or not hum then return end
        local target = autoRightPhase==1 and POSITION_R1 or POSITION_R2
        local dist = (Vector3.new(target.X,h.Position.Y,target.Z)-h.Position).Magnitude
        if dist < 1 then
            if autoRightPhase==1 then autoRightPhase=2; return end
            hum:Move(Vector3.zero,false); h.AssemblyLinearVelocity=Vector3.new(0,0,0)
            AutoRightEnabled=false; Enabled.AutoRightEnabled=false
            if VisualSetters and VisualSetters.AutoRightEnabled then VisualSetters.AutoRightEnabled(false,true) end
            if autoRightConnection then autoRightConnection:Disconnect(); autoRightConnection=nil end
            if onAutoRightDone then onAutoRightDone() end
            faceNorth(); return
        end
        local dir=(target-h.Position); local md=Vector3.new(dir.X,0,dir.Z).Unit
        hum:Move(md,false); h.AssemblyLinearVelocity=Vector3.new(md.X*Values.BoostSpeed,h.AssemblyLinearVelocity.Y,md.Z*Values.BoostSpeed)
    end)
end
local function stopAutoRight()
    if autoRightConnection then autoRightConnection:Disconnect(); autoRightConnection=nil end
    autoRightPhase=1
    local c=Player.Character if c then local hum=c:FindFirstChildOfClass("Humanoid") if hum then hum:Move(Vector3.zero,false) end end
end

-- ============================================================
-- FULL AUTO DUEL BACKEND  (logic ported from Silent Hub)
-- Waypoints auto-selected based on which side the player is on.
-- Pauses at grab waypoints (4 & 6) and waits for WalkSpeed to
-- drop below 23 (game signals a grab) before continuing.
-- ============================================================
local fadWaypoints     = {}
local fadCurrent       = 1
local fadMoving        = false
local fadWaiting       = false    -- waiting for a grab detection
local fadGrabDone      = false    -- grab already detected this leg
local fadMoveConn      = nil
local fadSpeedConn     = nil

local function fadStop()
    if fadMoveConn  then fadMoveConn:Disconnect();  fadMoveConn=nil  end
    if fadSpeedConn then fadSpeedConn:Disconnect();  fadSpeedConn=nil end
    fadMoving  = false
    fadWaiting = false
    fadGrabDone= false
    Enabled.FullAutoDuel = false
    if VisualSetters and VisualSetters.FullAutoDuel then VisualSetters.FullAutoDuel(false, true) end
end

local function fadMoveLoop()
    if fadMoveConn then fadMoveConn:Disconnect() end
    fadMoveConn = RunService.Stepped:Connect(function()
        if not fadMoving or fadWaiting then return end
        local c    = Player.Character if not c then return end
        local root = c:FindFirstChild("HumanoidRootPart") if not root then return end
        local wp   = fadWaypoints[fadCurrent]
        local dist = (root.Position - wp.position).Magnitude
        if dist < 5 then
            -- Grab-wait waypoints
            if (fadCurrent == 4 or fadCurrent == 6) and not fadGrabDone then
                fadWaiting = true
                root.AssemblyLinearVelocity = Vector3.new(0, root.AssemblyLinearVelocity.Y, 0)
                local c2 = Player.Character if c2 then local h=c2:FindFirstChildOfClass("Humanoid") if h then h:Move(Vector3.zero,false) end end
                return
            end
            if fadCurrent == #fadWaypoints then
                fadStop(); return
            end
            fadCurrent += 1
        else
            local dir = (wp.position - root.Position)
            local md  = Vector3.new(dir.X, 0, dir.Z).Unit
            local hum = c:FindFirstChildOfClass("Humanoid")
            if hum then hum:Move(md, false) end
            root.AssemblyLinearVelocity = Vector3.new(md.X*wp.speed, root.AssemblyLinearVelocity.Y, md.Z*wp.speed)
        end
    end)
end

local function startFullAutoDuel()
    local root = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    fadMoving   = true
    fadGrabDone = false
    fadCurrent  = 1

    -- Pick side based on which spawn is closer (mirrors Silent Hub logic)
    if (root.Position - Vector3.new(-475,-7,96)).Magnitude > (root.Position - Vector3.new(-474,-7,23)).Magnitude then
        fadWaypoints = {
            {position=Vector3.new(-475,-7,96),  speed=59},
            {position=Vector3.new(-483,-5,95),  speed=59},
            {position=Vector3.new(-487,-5,95),  speed=55},
            {position=Vector3.new(-492,-5,95),  speed=55},
            {position=Vector3.new(-473,-7,95),  speed=29},
            {position=Vector3.new(-473,-7,11),  speed=29},
        }
    else
        fadWaypoints = {
            {position=Vector3.new(-474,-7,23),  speed=55},
            {position=Vector3.new(-484,-5,24),  speed=55},
            {position=Vector3.new(-488,-5,24),  speed=55},
            {position=Vector3.new(-493,-5,25),  speed=55},
            {position=Vector3.new(-473,-7,25),  speed=29},
            {position=Vector3.new(-474,-7,112), speed=29},
        }
    end

    -- Speed watcher: WalkSpeed < 23 means a grab happened
    if fadSpeedConn then fadSpeedConn:Disconnect() end
    fadSpeedConn = RunService.Heartbeat:Connect(function()
        if not fadWaiting or fadGrabDone then return end
        local c   = Player.Character if not c then return end
        local hum = c:FindFirstChildOfClass("Humanoid") if not hum then return end
        if hum.WalkSpeed < 23 then
            task.wait(0.3)
            fadWaiting  = false
            fadGrabDone = true
            -- Advance past the grab waypoint
            if fadCurrent < #fadWaypoints then fadCurrent += 1 end
        end
    end)

    fadMoveLoop()
end

local function stopFullAutoDuel()
    fadStop()
end

local function startAntiRagdoll()
    if Connections.antiRagdoll then return end
    Connections.antiRagdoll = RunService.Heartbeat:Connect(function()
        if not Enabled.AntiRagdoll then return end
        local char=Player.Character if not char then return end
        local root=char:FindFirstChild("HumanoidRootPart")
        local hum=char:FindFirstChildOfClass("Humanoid")
        if hum then
            local s=hum:GetState()
            if s==Enum.HumanoidStateType.Physics or s==Enum.HumanoidStateType.Ragdoll or s==Enum.HumanoidStateType.FallingDown then
                hum:ChangeState(Enum.HumanoidStateType.Running)
                workspace.CurrentCamera.CameraSubject=hum
                pcall(function()
                    local pm=Player.PlayerScripts:FindFirstChild("PlayerModule")
                    if pm then require(pm:FindFirstChild("ControlModule")):Enable() end
                end)
                if root then root.Velocity=Vector3.zero; root.RotVelocity=Vector3.zero end
            end
        end
        for _,obj in ipairs(char:GetDescendants()) do
            if obj:IsA("Motor6D") and not obj.Enabled then obj.Enabled=true end
        end
    end)
end
local function stopAntiRagdoll()
    if Connections.antiRagdoll then Connections.antiRagdoll:Disconnect(); Connections.antiRagdoll=nil end
end

local function startSpeedWhileStealing()
    if Connections.speedWhileStealing then return end
    Connections.speedWhileStealing = RunService.Heartbeat:Connect(function()
        if not Enabled.SpeedWhileStealing or not Player:GetAttribute("Stealing") then return end
        local c=Player.Character if not c then return end
        local h=c:FindFirstChild("HumanoidRootPart") if not h then return end
        local md=getMovementDirection()
        if md.Magnitude > 0.1 then
            h.AssemblyLinearVelocity=Vector3.new(md.X*Values.StealingSpeedValue,h.AssemblyLinearVelocity.Y,md.Z*Values.StealingSpeedValue)
        end
    end)
end
local function stopSpeedWhileStealing()
    if Connections.speedWhileStealing then Connections.speedWhileStealing:Disconnect(); Connections.speedWhileStealing=nil end
end

-- AUTO GRAB
local ProgressBarFill, ProgressPercentLabel
local isStealing         = false
local stealStartTime     = nil
local progressConnection = nil
local StealData          = {}

local function isMyPlotByName(pn)
    local plots=workspace:FindFirstChild("Plots") if not plots then return false end
    local plot=plots:FindFirstChild(pn)           if not plot  then return false end
    local sign=plot:FindFirstChild("PlotSign")
    if sign then
        local yb=sign:FindFirstChild("YourBase")
        if yb and yb:IsA("BillboardGui") then return yb.Enabled==true end
    end
    return false
end

local function findNearestPrompt()
    local h=Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
    if not h then return nil end
    local plots=workspace:FindFirstChild("Plots") if not plots then return nil end
    local np,nd,nn=nil,math.huge,nil
    for _,plot in ipairs(plots:GetChildren()) do
        if isMyPlotByName(plot.Name) then continue end
        local podiums=plot:FindFirstChild("AnimalPodiums") if not podiums then continue end
        for _,pod in ipairs(podiums:GetChildren()) do
            pcall(function()
                local base=pod:FindFirstChild("Base")
                local spawn=base and base:FindFirstChild("Spawn")
                if spawn then
                    local dist=(spawn.Position-h.Position).Magnitude
                    if dist<nd and dist<=Values.STEAL_RADIUS then
                        local att=spawn:FindFirstChild("PromptAttachment")
                        if att then
                            for _,ch in ipairs(att:GetChildren()) do
                                if ch:IsA("ProximityPrompt") then np,nd,nn=ch,dist,pod.Name; break end
                            end
                        end
                    end
                end
            end)
        end
    end
    return np,nd,nn
end

local function ResetProgressBar()
    if ProgressPercentLabel then ProgressPercentLabel.Text="0%" end
    if ProgressBarFill      then ProgressBarFill.Size=UDim2.new(0,0,1,0) end
end

local function executeSteal(prompt,name)
    if isStealing then return end
    if not StealData[prompt] then
        StealData[prompt]={hold={},trigger={},ready=true}
        pcall(function()
            if getconnections then
                for _,c in ipairs(getconnections(prompt.PromptButtonHoldBegan)) do
                    if c.Function then table.insert(StealData[prompt].hold,c.Function) end
                end
                for _,c in ipairs(getconnections(prompt.Triggered)) do
                    if c.Function then table.insert(StealData[prompt].trigger,c.Function) end
                end
            end
        end)
    end
    local data=StealData[prompt]
    if not data.ready then return end
    data.ready=false; isStealing=true; stealStartTime=tick()
    if progressConnection then progressConnection:Disconnect() end
    progressConnection=RunService.Heartbeat:Connect(function()
        if not isStealing then progressConnection:Disconnect(); return end
        local prog=math.clamp((tick()-stealStartTime)/Values.STEAL_DURATION,0,1)
        if ProgressBarFill then ProgressBarFill.Size=UDim2.new(prog,0,1,0) end
        if ProgressPercentLabel then ProgressPercentLabel.Text=math.floor(prog*100).."%" end
    end)
    task.spawn(function()
        for _,f in ipairs(data.hold) do task.spawn(f) end
        task.wait(Values.STEAL_DURATION)
        for _,f in ipairs(data.trigger) do task.spawn(f) end
        if progressConnection then progressConnection:Disconnect() end
        ResetProgressBar(); data.ready=true; task.wait(0.3); isStealing=false
    end)
end

local function startAutoSteal()
    if Connections.autoSteal then return end
    Connections.autoSteal=RunService.Heartbeat:Connect(function()
        if not Enabled.AutoSteal or isStealing then return end
        local p,_,n=findNearestPrompt()
        if p then executeSteal(p,n) end
    end)
end
local function stopAutoSteal()
    if Connections.autoSteal then Connections.autoSteal:Disconnect(); Connections.autoSteal=nil end
    isStealing=false; ResetProgressBar()
end

local savedAnimations={}
local function startUnwalk()
    local c=Player.Character if not c then return end
    local hum=c:FindFirstChildOfClass("Humanoid")
    if hum then for _,t in ipairs(hum:GetPlayingAnimationTracks()) do t:Stop() end end
    local anim=c:FindFirstChild("Animate")
    if anim then savedAnimations.Animate=anim:Clone(); anim:Destroy() end
end
local function stopUnwalk()
    local c=Player.Character
    if c and savedAnimations.Animate then savedAnimations.Animate:Clone().Parent=c; savedAnimations.Animate=nil end
end

local originalTransparency={}; local xrayEnabled=false
local function enableOptimizer()
    if getgenv and getgenv().OPTIMIZER_ACTIVE then return end
    if getgenv then getgenv().OPTIMIZER_ACTIVE=true end
    pcall(function() settings().Rendering.QualityLevel=Enum.QualityLevel.Level01; Lighting.GlobalShadows=false; Lighting.Brightness=3; Lighting.FogEnd=9e9 end)
    pcall(function()
        for _,obj in ipairs(workspace:GetDescendants()) do
            pcall(function()
                if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") then obj:Destroy()
                elseif obj:IsA("BasePart") then obj.CastShadow=false; obj.Material=Enum.Material.Plastic end
            end)
        end
    end)
    xrayEnabled=true
    pcall(function()
        for _,obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") and obj.Anchored and (obj.Name:lower():find("base") or (obj.Parent and obj.Parent.Name:lower():find("base"))) then
                originalTransparency[obj]=obj.LocalTransparencyModifier; obj.LocalTransparencyModifier=0.85
            end
        end
    end)
end
local function disableOptimizer()
    if getgenv then getgenv().OPTIMIZER_ACTIVE=false end
    if xrayEnabled then
        for part,v in pairs(originalTransparency) do if part then part.LocalTransparencyModifier=v end end
        originalTransparency={}; xrayEnabled=false
    end
end

local abActive=false; local _abMoveConn,_abNdConn,_abNdHumConn,_abTarget
local abVisualSetter=nil

local function _abApplyNoDie(char)
    if _abNdConn then _abNdConn:Disconnect(); _abNdConn=nil end
    if _abNdHumConn then _abNdHumConn:Disconnect(); _abNdHumConn=nil end
    local hum=char and char:FindFirstChildOfClass("Humanoid") if not hum then return end
    pcall(function() hum.MaxHealth=math.huge end); pcall(function() hum.Health=math.huge end)
    _abNdHumConn=hum:GetPropertyChangedSignal("Health"):Connect(function()
        if not abActive then return end
        pcall(function() if hum.Health<1 then hum.Health=hum.MaxHealth end end)
    end)
    _abNdConn=RunService.Heartbeat:Connect(function()
        if not abActive then return end
        pcall(function()
            if not hum or not hum.Parent then return end
            if hum.Health<hum.MaxHealth then hum.Health=hum.MaxHealth end
            local s=hum:GetState()
            if s==Enum.HumanoidStateType.Dead or s==Enum.HumanoidStateType.Ragdoll or s==Enum.HumanoidStateType.FallingDown then
                hum:ChangeState(Enum.HumanoidStateType.Running)
            end
        end)
    end)
end
local function _abStop()
    if _abMoveConn then _abMoveConn:Disconnect(); _abMoveConn=nil end
    if _abNdConn   then _abNdConn:Disconnect();   _abNdConn=nil   end
    if _abNdHumConn then _abNdHumConn:Disconnect(); _abNdHumConn=nil end
    _abTarget=nil
    pcall(function()
        local hum=Player.Character and Player.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.MaxHealth=100; hum:Move(Vector3.zero,false) end
    end)
end
local function _abStart()
    _abStop()
    local char=Player.Character if char then _abApplyNoDie(char) end
    _abMoveConn=RunService.Heartbeat:Connect(function()
        if not abActive then return end
        pcall(function()
            local myChar=Player.Character if not myChar then return end
            local myHRP=myChar:FindFirstChild("HumanoidRootPart")
            local myHum=myChar:FindFirstChildOfClass("Humanoid")
            if not myHRP or not myHum then return end
            local nearest,bestDist=nil,math.huge
            for _,p in ipairs(Players:GetPlayers()) do
                if p~=Player and p.Character then
                    local oh=p.Character:FindFirstChild("HumanoidRootPart")
                    if oh then local d=(myHRP.Position-oh.Position).Magnitude if d<bestDist then bestDist=d; nearest=p end end
                end
            end
            _abTarget=nearest
            if not _abTarget or not _abTarget.Character then return end
            local tHRP=_abTarget.Character:FindFirstChild("HumanoidRootPart") if not tHRP then return end
            local flat=Vector3.new((tHRP.Position-myHRP.Position).X,0,(tHRP.Position-myHRP.Position).Z)
            if flat.Magnitude<3 then myHum:Move(Vector3.zero,false); return end
            local unit=flat.Unit; myHum:Move(unit,false)
            myHRP.AssemblyLinearVelocity=Vector3.new(unit.X*Values.BoostSpeed,myHRP.AssemblyLinearVelocity.Y,unit.Z*Values.BoostSpeed)
            pcall(function() myHRP.CFrame=CFrame.new(myHRP.Position,myHRP.Position+flat) end)
        end)
    end)
end
local function abToggle()
    abActive=not abActive
    if abActive then _abStart() else _abStop() end
    if abVisualSetter then abVisualSetter(abActive) end
end
Player.CharacterAdded:Connect(function(nc)
    if not abActive then return end
    task.wait(0.5); _abApplyNoDie(nc); _abStart()
end)

-- ============================================================
-- SPEED LABEL ABOVE CHARACTER
-- ============================================================
local speedBillboard = nil
local speedTextLabel = nil

local function createSpeedLabel(char)
    if speedBillboard then speedBillboard:Destroy(); speedBillboard=nil; speedTextLabel=nil end
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local bb = Instance.new("BillboardGui")
    bb.Name = "ZAY_SpeedLabel"; bb.AlwaysOnTop = false
    bb.Size = UDim2.new(0, 120, 0, 30); bb.StudsOffset = Vector3.new(0, 3.2, 0)
    bb.MaxDistance = 60; bb.Parent = hrp
    local lbl = Instance.new("TextLabel", bb)
    lbl.Size = UDim2.new(1, 0, 1, 0); lbl.BackgroundTransparency = 1
    lbl.Text = "Speed: 0.0"; lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
    lbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0); lbl.TextStrokeTransparency = 0
    lbl.Font = Enum.Font.GothamBlack; lbl.TextSize = 16
    lbl.TextXAlignment = Enum.TextXAlignment.Center
    speedBillboard = bb; speedTextLabel = lbl
end

task.spawn(function() task.wait(1); createSpeedLabel(Player.Character) end)
Player.CharacterAdded:Connect(function(char) task.wait(0.5); createSpeedLabel(char) end)

RunService.Heartbeat:Connect(function()
    if not speedTextLabel then return end
    pcall(function()
        local char = Player.Character if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart") if not hrp then return end
        local vel = hrp.AssemblyLinearVelocity
        local horizontalSpeed = Vector3.new(vel.X, 0, vel.Z).Magnitude
        speedTextLabel.Text = "Speed: " .. string.format("%.1f", horizontalSpeed)
    end)
end)

-- ============================================================
-- GUI
-- ============================================================
local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local GS = isMobile and 0.85 or 1

local function onTap(btn, cb)
    if isMobile then
        btn.Activated:Connect(cb)
    else
        btn.MouseButton1Click:Connect(cb)
    end
end

local C = {
    bg         = Color3.fromRGB(18,12,40),   -- dark purple background
    bgRow      = Color3.fromRGB(28,18,60),   -- row color
    white      = Color3.fromRGB(140,170,255), -- blue text
    dim        = Color3.fromRGB(120,120,200),
    muted      = Color3.fromRGB(90,70,160),
    off        = Color3.fromRGB(40,30,90),
    border     = Color3.fromRGB(120,90,255), -- purple border
    danger     = Color3.fromRGB(255,80,120),
    dangerDark = Color3.fromRGB(120,30,80),
    badge      = Color3.fromRGB(50,40,120),
    badgeActive= Color3.fromRGB(120,90,255),
}

local WIN_W = math.floor(360*GS)
local WIN_H = math.floor(420*GS)
local CR    = math.floor(12*GS)

local sg = Instance.new("ScreenGui")
sg.Name="H_CLEAN"; sg.ResetOnSpawn=false
sg.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
sg.Parent=Player.PlayerGui

local function playSound(id,vol,spd)
    pcall(function()
        local s=Instance.new("Sound",SoundService)
        s.SoundId=id; s.Volume=vol or 0.3; s.PlaybackSpeed=spd or 1
        s:Play(); game:GetService("Debris"):AddItem(s,1)
    end)
end

local function rc(inst, r)
    local c = Instance.new("UICorner", inst); c.CornerRadius = UDim.new(0, r or CR)
end
local function st(inst, thick, col, trans)
    local s = Instance.new("UIStroke", inst)
    s.Thickness=thick or 2; s.Color=col or C.white; s.Transparency=trans or 0
    s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border
end

local main = Instance.new("Frame", sg)
main.Name="ZAY_Main"
main.Size=UDim2.new(0, WIN_W, 0, WIN_H)
main.Position=isMobile and UDim2.new(0.5,-WIN_W/2,0.5,-WIN_H/2) or UDim2.new(1,-(WIN_W+16),0,16)
main.BackgroundColor3=C.bg; main.BorderSizePixel=0; main.Active=true; main.Draggable=not isMobile
rc(main, CR); st(main, 3, C.white, 0)

if isMobile then
    local mobDragging = false
    local mobDragStart, mobFrameStart
    local _dragCBW = math.floor(22*GS)
    local titleHitbox = Instance.new("TextButton", main)
    titleHitbox.Size = UDim2.new(1, -math.floor(_dragCBW+20*GS), 0, math.floor(48*GS))
    titleHitbox.Position = UDim2.new(0,0,0,0)
    titleHitbox.BackgroundTransparency = 1; titleHitbox.Text = ""; titleHitbox.ZIndex = 20
    titleHitbox.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.Touch then
            mobDragging = true
            mobDragStart = inp.Position
            mobFrameStart = main.Position
        end
    end)
    titleHitbox.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.Touch then mobDragging = false end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if mobDragging and inp.UserInputType == Enum.UserInputType.Touch then
            local delta = inp.Position - mobDragStart
            main.Position = UDim2.new(
                mobFrameStart.X.Scale, mobFrameStart.X.Offset + delta.X,
                mobFrameStart.Y.Scale, mobFrameStart.Y.Offset + delta.Y
            )
        end
    end)
end

local TITLE_H = math.floor(48*GS)
local titleTxt = Instance.new("TextLabel", main)
titleTxt.Size=UDim2.new(1,0,0,TITLE_H); titleTxt.Position=UDim2.new(0,0,0,0)
titleTxt.BackgroundTransparency=1; titleTxt.Text="HAVOCHUB HELPER V2"; titleTxt.TextColor3=C.white
titleTxt.Font=Enum.Font.GothamBlack; titleTxt.TextSize=math.floor(24*GS)
titleTxt.TextXAlignment=Enum.TextXAlignment.Center; titleTxt.TextYAlignment=Enum.TextYAlignment.Center
titleTxt.ZIndex=1

local CBW = math.floor(22*GS)
local closeBtn = Instance.new("TextButton", main)
closeBtn.Size=UDim2.new(0,CBW,0,CBW)
closeBtn.Position=UDim2.new(1,-math.floor(CBW+10*GS),0,math.floor((TITLE_H-CBW)/2))
closeBtn.BackgroundColor3=C.dangerDark; closeBtn.Text="×"; closeBtn.TextColor3=C.white
closeBtn.Font=Enum.Font.GothamBold; closeBtn.TextSize=math.floor(14*GS); closeBtn.BorderSizePixel=0
rc(closeBtn, math.floor(CBW/2)); st(closeBtn, 2, C.danger, 0)

local divider = Instance.new("Frame", main)
divider.Size=UDim2.new(1,-math.floor(16*GS),0,1); divider.Position=UDim2.new(0,math.floor(8*GS),0,TITLE_H)
divider.BackgroundColor3=C.border; divider.BorderSizePixel=0

local SCROLL_Y = TITLE_H + 2
local scroll = Instance.new("ScrollingFrame", main)
scroll.Size=UDim2.new(1,0,0,WIN_H-SCROLL_Y); scroll.Position=UDim2.new(0,0,0,SCROLL_Y)
scroll.BackgroundTransparency=1; scroll.BorderSizePixel=0
scroll.ScrollBarThickness=math.floor(3*GS); scroll.ScrollBarImageColor3=C.dim
scroll.CanvasSize=UDim2.new(0,0,0,0); scroll.AutomaticCanvasSize=Enum.AutomaticSize.Y
scroll.ScrollingDirection=Enum.ScrollingDirection.Y

local layout = Instance.new("UIListLayout", scroll)
layout.SortOrder=Enum.SortOrder.LayoutOrder; layout.Padding=UDim.new(0,math.floor(3*GS))

local pad = Instance.new("UIPadding", scroll)
pad.PaddingTop=UDim.new(0,math.floor(6*GS)); pad.PaddingBottom=UDim.new(0,math.floor(10*GS))
pad.PaddingLeft=UDim.new(0,math.floor(8*GS)); pad.PaddingRight=UDim.new(0,math.floor(8*GS))

VisualSetters = {}
local SliderSetters     = {}
local waitingForKeybind = nil
local KeyBindBtns       = {}

local ROW_H = math.floor(36*GS)
local SL_H  = math.floor(52*GS)

local function createSectionHeader(order, txt)
    local w = Instance.new("Frame", scroll)
    w.Size=UDim2.new(1,0,0,math.floor(20*GS)); w.BackgroundTransparency=1; w.LayoutOrder=order
    local lbl = Instance.new("TextLabel", w)
    lbl.Size=UDim2.new(1,0,1,0); lbl.BackgroundTransparency=1; lbl.Text=txt
    lbl.TextColor3=C.muted; lbl.Font=Enum.Font.GothamBold; lbl.TextSize=math.floor(9*GS)
    lbl.TextXAlignment=Enum.TextXAlignment.Left
    local rule = Instance.new("Frame", w)
    rule.Size=UDim2.new(1,0,0,1); rule.Position=UDim2.new(0,0,1,-1)
    rule.BackgroundColor3=C.border; rule.BorderSizePixel=0
end

local KB_W = math.floor(48*GS)
local KB_H = math.floor(20*GS)

local function createKeybindBadge(parent, keybindKey)
    if not keybindKey then return nil end
    local kc0 = KEYBINDS[keybindKey]
    local btn = Instance.new("TextButton", parent)
    btn.Size             = UDim2.new(0, KB_W, 0, KB_H)
    local pillRight      = math.floor(40*GS) + math.floor(8*GS)
    btn.Position         = UDim2.new(1, -(pillRight + KB_W + math.floor(6*GS)), 0.5, -math.floor(KB_H/2))
    btn.BackgroundColor3 = C.badge
    btn.Text             = (kc0 == Enum.KeyCode.Unknown) and "—" or kc0.Name
    btn.TextColor3       = C.white
    btn.Font             = Enum.Font.GothamBold
    btn.TextSize         = math.floor(8*GS)
    btn.TextScaled       = false
    btn.TextTruncate     = Enum.TextTruncate.AtEnd
    btn.BorderSizePixel  = 0
    -- ZIndex 15: sits above the toggle click layer (ZIndex 10) so badge clicks don't trigger toggle
    btn.ZIndex           = 15
    rc(btn, math.floor(5*GS))
    st(btn, 1.5, C.dim, 0.3)
    KeyBindBtns[keybindKey] = btn
    btn.MouseButton1Click:Connect(function()
        if waitingForKeybind == keybindKey then
            waitingForKeybind = nil
            local kc2 = KEYBINDS[keybindKey]
            btn.Text = (kc2 == Enum.KeyCode.Unknown) and "—" or kc2.Name
            TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = C.badge}):Play()
            return
        end
        if waitingForKeybind then
            local prev = KeyBindBtns[waitingForKeybind]
            if prev then
                local pkc = KEYBINDS[waitingForKeybind]
                prev.Text = (pkc == Enum.KeyCode.Unknown) and "—" or pkc.Name
                TweenService:Create(prev, TweenInfo.new(0.15), {BackgroundColor3 = C.badge}):Play()
            end
        end
        waitingForKeybind = keybindKey
        btn.Text = "?"
        TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = C.badgeActive}):Play()
        playSound("rbxassetid://6895079813", 0.3, 1.5)
    end)
    btn.MouseButton2Click:Connect(function()
        KEYBINDS[keybindKey] = Enum.KeyCode.Unknown
        btn.Text = "—"
        waitingForKeybind = nil
        TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = C.badge}):Play()
    end)
    return btn
end

-- ============================================================
-- createToggle  —  KEY FIX:
--   • clk covers the FULL row (no width trimming)
--   • keybind badge is ZIndex 15 so it sits above clk (ZIndex 10)
--     and captures its own clicks without triggering the toggle
--   • doToggle() guards against firing while waitingForKeybind is set
-- ============================================================
local function createToggle(order, labelTxt, enabledKey, callback, _unused, keybindKey)
    local row = Instance.new("Frame", scroll)
    row.Size=UDim2.new(1,0,0,ROW_H); row.BackgroundColor3=C.bgRow
    row.BorderSizePixel=0; row.LayoutOrder=order
    rc(row, CR); st(row, 2, C.border, 0.45)

    local PW = math.floor(40*GS)
    local PH = math.floor(22*GS)

    -- Label: leave room for pill + optional keybind badge
    local rightReserve = PW + math.floor(8*GS)
        + (keybindKey and (KB_W + math.floor(6*GS)) or 0)
        + math.floor(8*GS)
    local lbl = Instance.new("TextLabel", row)
    lbl.Size=UDim2.new(1, -(math.floor(10*GS) + rightReserve), 1, 0)
    lbl.Position=UDim2.new(0,math.floor(10*GS),0,0); lbl.BackgroundTransparency=1
    lbl.Text=labelTxt; lbl.TextColor3=C.white; lbl.Font=Enum.Font.GothamSemibold
    lbl.TextSize=math.floor(11*GS); lbl.TextXAlignment=Enum.TextXAlignment.Left
    lbl.TextTruncate=Enum.TextTruncate.AtEnd; lbl.ZIndex=2

    local isOn = Enabled[enabledKey] or false

    -- Toggle pill (ZIndex 5)
    local pill = Instance.new("Frame", row)
    pill.Size=UDim2.new(0,PW,0,PH); pill.Position=UDim2.new(1,-(PW+math.floor(8*GS)),0.5,-PH/2)
    pill.BackgroundColor3=isOn and Color3.fromRGB(120,90,255) or C.off; pill.BorderSizePixel=0; pill.ZIndex=5
    rc(pill, PH/2); st(pill, 1.5, C.dim, 0.4)

    local KW = math.floor(16*GS)
    local knob = Instance.new("Frame", pill)
    knob.Size=UDim2.new(0,KW,0,KW)
    knob.Position=isOn and UDim2.new(1,-(KW+3),0.5,-KW/2) or UDim2.new(0,3,0.5,-KW/2)
    knob.BackgroundColor3=isOn and C.bg or C.dim; knob.BorderSizePixel=0; knob.ZIndex=6
    rc(knob, KW/2)

    -- Keybind badge (ZIndex 15 — above click overlay)
    createKeybindBadge(row, keybindKey)

    -- Full-row invisible click overlay (ZIndex 10)
    -- The badge sits above this (ZIndex 15), so clicking the badge
    -- will NOT bubble down to trigger the toggle.
    local clk = Instance.new("TextButton", row)
    clk.Size                = UDim2.new(1, 0, 1, 0)   -- full row, no cutoff
    clk.BackgroundTransparency = 1
    clk.Text                = ""
    clk.ZIndex              = 10

    local function setVisual(state, skipCB)
        isOn = state
        TweenService:Create(pill,TweenInfo.new(0.18),{BackgroundColor3=isOn and C.white or C.off}):Play()
        TweenService:Create(knob,TweenInfo.new(0.18,Enum.EasingStyle.Back),{
            BackgroundColor3 = isOn and C.bg or C.dim,
            Position = isOn and UDim2.new(1,-(KW+3),0.5,-KW/2) or UDim2.new(0,3,0.5,-KW/2)
        }):Play()
        if not skipCB then callback(isOn) end
    end
    VisualSetters[enabledKey] = setVisual

    local function doToggle()
        -- Don't accidentally toggle while waiting for a keybind input
        if waitingForKeybind then return end
        isOn = not isOn; Enabled[enabledKey] = isOn
        setVisual(isOn)
        playSound("rbxassetid://6895079813", 0.3, isOn and 1.1 or 0.9)
    end

    if isMobile then
        -- Activated fires only on a clean tap (not drag), avoiding false triggers
        clk.Activated:Connect(doToggle)
    else
        clk.MouseButton1Click:Connect(doToggle)
    end

    return row, setVisual
end

local function createSlider(order, labelTxt, minV, maxV, valueKey, callback)
    local f = Instance.new("Frame", scroll)
    f.Size=UDim2.new(1,0,0,SL_H); f.BackgroundColor3=C.bgRow
    f.BorderSizePixel=0; f.LayoutOrder=order
    rc(f, CR); st(f, 2, C.border, 0.45)

    local lbl = Instance.new("TextLabel", f)
    lbl.Size=UDim2.new(0.6,0,0,math.floor(16*GS)); lbl.Position=UDim2.new(0,math.floor(10*GS),0,math.floor(5*GS))
    lbl.BackgroundTransparency=1; lbl.Text=labelTxt; lbl.TextColor3=C.dim
    lbl.Font=Enum.Font.GothamMedium; lbl.TextSize=math.floor(10*GS); lbl.TextXAlignment=Enum.TextXAlignment.Left

    local function r1(n) return math.floor(n*10+0.5)/10 end
    local function fmt(n) return string.format("%.1f",n) end

    local defVal = r1(Values[valueKey] or minV)
    local valBox = Instance.new("TextBox", f)
    valBox.Size=UDim2.new(0,math.floor(46*GS),0,math.floor(18*GS))
    valBox.Position=UDim2.new(1,-math.floor(52*GS),0,math.floor(4*GS))
    valBox.BackgroundColor3=C.off; valBox.Text=fmt(defVal); valBox.TextColor3=C.white
    valBox.Font=Enum.Font.GothamBold; valBox.TextSize=math.floor(10*GS)
    valBox.ClearTextOnFocus=false; valBox.BorderSizePixel=0
    rc(valBox, 5); st(valBox, 1.5, C.border, 0.4)

    local track = Instance.new("Frame", f)
    track.Size=UDim2.new(1,-math.floor(16*GS),0,math.floor(6*GS))
    track.Position=UDim2.new(0,math.floor(8*GS),1,-math.floor(14*GS))
    track.BackgroundColor3=C.off; track.BorderSizePixel=0
    rc(track, 4); st(track, 1.5, C.border, 0.5)

    local pct  = math.clamp((defVal-minV)/(maxV-minV), 0, 1)
    local fill = Instance.new("Frame", track)
    fill.Size=UDim2.new(pct,0,1,0); fill.BackgroundColor3=C.white; fill.BorderSizePixel=0; rc(fill, 4)

    local thumb = Instance.new("Frame", track)
    thumb.Size=UDim2.new(0,math.floor(12*GS),0,math.floor(12*GS))
    thumb.Position=UDim2.new(pct,-math.floor(6*GS),0.5,-math.floor(6*GS))
    thumb.BackgroundColor3=C.white; thumb.BorderSizePixel=0
    rc(thumb, math.floor(6*GS)); st(thumb, 1.5, C.dim, 0)

    local hitbox = Instance.new("TextButton", track)
    hitbox.Size=UDim2.new(1,0,5,0); hitbox.Position=UDim2.new(0,0,-2,0)
    hitbox.BackgroundTransparency=1; hitbox.Text=""

    local dragging = false
    local function setVal(rel)
        rel=math.clamp(rel,0,1)
        fill.Size=UDim2.new(rel,0,1,0)
        thumb.Position=UDim2.new(rel,-math.floor(6*GS),0.5,-math.floor(6*GS))
        local v=r1(math.clamp(r1(minV+(maxV-minV)*rel),minV,maxV))
        valBox.Text=fmt(v); Values[valueKey]=v; callback(v)
    end
    local function setSlider(v)
        v=r1(math.clamp(v,minV,maxV)); local r=(v-minV)/(maxV-minV)
        fill.Size=UDim2.new(r,0,1,0)
        thumb.Position=UDim2.new(r,-math.floor(6*GS),0.5,-math.floor(6*GS))
        valBox.Text=fmt(v); Values[valueKey]=v
    end
    SliderSetters[valueKey] = setSlider

    hitbox.MouseButton1Down:Connect(function() dragging=true end)
    hitbox.InputBegan:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.Touch then dragging=true end
    end)
    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then dragging=false end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if dragging and (inp.UserInputType==Enum.UserInputType.MouseMovement or inp.UserInputType==Enum.UserInputType.Touch) then
            setVal((inp.Position.X-track.AbsolutePosition.X)/track.AbsoluteSize.X)
        end
    end)
    valBox.FocusLost:Connect(function()
        local n=tonumber(valBox.Text)
        if n then setSlider(r1(math.clamp(n,minV,maxV))); callback(Values[valueKey])
        else valBox.Text=fmt(Values[valueKey] or minV) end
    end)
    return f, setSlider
end

local function createButtonRow(order, txt, bgCol, strokeCol, callback)
    local f = Instance.new("Frame", scroll)
    f.Size=UDim2.new(1,0,0,math.floor(33*GS)); f.BackgroundTransparency=1; f.LayoutOrder=order
    local btn = Instance.new("TextButton", f)
    btn.Size=UDim2.new(1,0,1,0); btn.BackgroundColor3=bgCol; btn.Text=txt
    btn.TextColor3=C.white; btn.Font=Enum.Font.GothamBold; btn.TextSize=math.floor(11*GS)
    btn.BorderSizePixel=0; rc(btn, CR); st(btn, 2, strokeCol, 0)
    onTap(btn, function() callback(btn) end)
    return f, btn
end

-- ============================================================
-- PROGRESS BAR
-- ============================================================
local PB_W = math.floor(390*GS)
local PB_H = math.floor(52*GS)

local progBar = Instance.new("Frame", sg)
progBar.Size=UDim2.new(0,PB_W,0,PB_H); progBar.Position=UDim2.new(0.5,-PB_W/2,0.8,-PB_H/2)
progBar.BackgroundColor3=Color3.fromRGB(14,14,14); progBar.BorderSizePixel=0
rc(progBar, CR); st(progBar, 3, C.white, 0)

ProgressPercentLabel = Instance.new("TextLabel", progBar)
ProgressPercentLabel.Size=UDim2.new(1,0,0,math.floor(28*GS))
ProgressPercentLabel.Position=UDim2.new(0,0,0,math.floor(3*GS))
ProgressPercentLabel.BackgroundTransparency=1; ProgressPercentLabel.Text="0%"
ProgressPercentLabel.TextColor3=C.white; ProgressPercentLabel.Font=Enum.Font.GothamBlack
ProgressPercentLabel.TextSize=math.floor(19*GS); ProgressPercentLabel.TextXAlignment=Enum.TextXAlignment.Center
ProgressPercentLabel.ZIndex=3

local IW = math.floor(42*GS)
local IH = math.floor(28*GS)
local function makePBInput(xOffset, labelStr, valueKey, isFloat, minV, maxV)
    local holder = Instance.new("Frame", progBar)
    holder.Size=UDim2.new(0,IW,0,IH); holder.Position=UDim2.new(1,-(IW+xOffset),0,math.floor(2*GS))
    holder.BackgroundColor3=Color3.fromRGB(24,24,24); holder.BorderSizePixel=0; holder.ZIndex=4
    rc(holder, 6)
    local lbl = Instance.new("TextLabel", holder)
    lbl.Size=UDim2.new(1,0,0,math.floor(11*GS)); lbl.BackgroundTransparency=1; lbl.Text=labelStr
    lbl.TextColor3=C.muted; lbl.Font=Enum.Font.GothamBold; lbl.TextSize=math.floor(7*GS)
    lbl.TextXAlignment=Enum.TextXAlignment.Center
    local box = Instance.new("TextBox", holder)
    box.Size=UDim2.new(1,-4,0,math.floor(14*GS)); box.Position=UDim2.new(0,2,0,math.floor(12*GS))
    box.BackgroundTransparency=1; box.Text=tostring(Values[valueKey]); box.TextColor3=C.white
    box.Font=Enum.Font.GothamBold; box.TextSize=math.floor(11*GS); box.ClearTextOnFocus=false
    box.BorderSizePixel=0; box.TextXAlignment=Enum.TextXAlignment.Center; box.ZIndex=5
    box.FocusLost:Connect(function()
        local n=tonumber(box.Text)
        if n then
            if isFloat then n=math.clamp(math.floor(n*100+0.5)/100,minV,maxV)
            else n=math.clamp(math.floor(n),minV,maxV) end
            Values[valueKey]=n; box.Text=tostring(n); SaveConfig()
        else box.Text=tostring(Values[valueKey]) end
    end)
end

makePBInput(math.floor(8*GS),      "RADIUS", "STEAL_RADIUS",   false, 5,    100)
makePBInput(math.floor(8*GS)+IW+6, "SPEED",  "STEAL_DURATION", true,  0.05, 5  )

local pbTrack = Instance.new("Frame", progBar)
pbTrack.Size=UDim2.new(1,-math.floor(16*GS),0,math.floor(7*GS))
pbTrack.Position=UDim2.new(0,math.floor(8*GS),1,-math.floor(10*GS))
pbTrack.BackgroundColor3=C.off; pbTrack.BorderSizePixel=0; pbTrack.ZIndex=2
rc(pbTrack, 4); st(pbTrack, 1.5, C.border, 0.4)

ProgressBarFill = Instance.new("Frame", pbTrack)
ProgressBarFill.Size=UDim2.new(0,0,1,0); ProgressBarFill.BackgroundColor3=C.white
ProgressBarFill.BorderSizePixel=0; ProgressBarFill.ZIndex=3; rc(ProgressBarFill, 4)

-- ============================================================
-- BUILD ALL ROWS
-- ============================================================
local o = 0

createSectionHeader(o,"MOVEMENT") o+=1
createToggle(o,"Speed Boost","SpeedBoost",
    function(s) Enabled.SpeedBoost=s; if s then startSpeedBoost() else stopSpeedBoost() end end,
    nil,"SPEED") o+=1
createSlider(o,"Boost Speed",1,70,"BoostSpeed",function(v) Values.BoostSpeed=v end) o+=1
createToggle(o,"Speed While Stealing","SpeedWhileStealing",
    function(s) Enabled.SpeedWhileStealing=s; if s then startSpeedWhileStealing() else stopSpeedWhileStealing() end end,
    nil, nil) o+=1
createSlider(o,"Carry Speed",10,35,"StealingSpeedValue",function(v) Values.StealingSpeedValue=v end) o+=1
createToggle(o,"Boosters (Galaxy)","Galaxy",
    function(s) Enabled.Galaxy=s; if s then startGalaxy() else stopGalaxy() end end,
    nil,"GALAXY") o+=1
createSlider(o,"Gravity %",25,130,"GalaxyGravityPercent",
    function(v) Values.GalaxyGravityPercent=v; if galaxyEnabled then adjustGalaxyJump() end end) o+=1
createSlider(o,"Jump Boost",10,80,"HOP_POWER",function(v) Values.HOP_POWER=v end) o+=1
createToggle(o,"Anti Ragdoll","AntiRagdoll",
    function(s) Enabled.AntiRagdoll=s; if s then startAntiRagdoll() else stopAntiRagdoll() end end,
    nil,"ANTIRAGDOLL") o+=1
createToggle(o,"Spin Bot","SpinBot",
    function(s) Enabled.SpinBot=s; if s then startSpinBot() else stopSpinBot() end end,
    nil,"SPIN") o+=1
createSlider(o,"Spin Speed",5,50,"SpinSpeed",function(v) Values.SpinSpeed=v end) o+=1

createToggle(o,"Float","Float",
    function(s) Enabled.Float=s; if s then startFloat() else stopFloat() end end,
    nil,"FLOAT") o+=1
createSlider(o,"Float Height",1,50,"FloatHeight",function(v) Values.FloatHeight=v end) o+=1


createSectionHeader(o,"STEAL") o+=1
createToggle(o,"Auto Grab","AutoSteal",
    function(s) Enabled.AutoSteal=s; if s then startAutoSteal() else stopAutoSteal() end end,
    nil, nil) o+=1

createSectionHeader(o,"MISC") o+=1
createToggle(o,"Optimizer + XRay","Optimizer",
    function(s) Enabled.Optimizer=s; if s then enableOptimizer() else disableOptimizer() end end,
    nil, nil) o+=1
createToggle(o,"Unwalk","Unwalk",
    function(s) Enabled.Unwalk=s; if s then startUnwalk() else stopUnwalk() end end,
    nil, nil) o+=1
createToggle(o,"Spam Bat","SpamBat",
    function(s) Enabled.SpamBat=s; if s then startSpamBat();startSpamBatCircle() else stopSpamBat();removeSpamBatCircle() end end,
    nil, nil) o+=1
createSlider(o,"FOV",30,120,"FOV",function(v)
    Values.FOV=v
    pcall(function() local cam=workspace.CurrentCamera; if cam then cam.FieldOfView=v end end)
end) o+=1
if not isMobile then
    createToggle(o,"Aimbot","Aimbot",
        function(s) if s==abActive then return end; abToggle() end,
        nil,"AIMBOT") o+=1
    abVisualSetter = function(on)
        if VisualSetters.Aimbot then VisualSetters.Aimbot(on,true) end
    end
end

createSectionHeader(o,"CONFIG") o+=1
createButtonRow(o,"💾  SAVE CONFIG",Color3.fromRGB(28,28,28),C.dim,
    function(btn)
        local ok = SaveConfig()
        btn.Text=ok and "✓  SAVED!" or "✗  FAILED"
        btn.BackgroundColor3=ok and C.off or C.dangerDark
        task.delay(2,function() btn.Text="💾  SAVE CONFIG"; btn.BackgroundColor3=Color3.fromRGB(28,28,28) end)
        playSound("rbxassetid://6895079813",0.4,ok and 1.2 or 0.7)
    end) o+=1
createButtonRow(o,"🗑  RESET CONFIG",Color3.fromRGB(55,10,10),C.dangerDark,
    function(btn)
        for k in pairs(Enabled) do Enabled[k]=false end; Enabled.AutoDisableSpeed=true
        Values.BoostSpeed=30; Values.SpinSpeed=30; Values.StealingSpeedValue=29
        Values.STEAL_RADIUS=20; Values.STEAL_DURATION=1.3; Values.DEFAULT_GRAVITY=196.2
        Values.GalaxyGravityPercent=70; Values.HOP_POWER=35; Values.HOP_COOLDOWN=0.08
        Values.FOV=70
        Values.FloatHeight=8
        KEYBINDS.SPEED=Enum.KeyCode.V; KEYBINDS.SPIN=Enum.KeyCode.N; KEYBINDS.GALAXY=Enum.KeyCode.M
        KEYBINDS.AUTOLEFT=Enum.KeyCode.Z; KEYBINDS.AUTORIGHT=Enum.KeyCode.C
        KEYBINDS.ANTIRAGDOLL=Enum.KeyCode.Unknown; KEYBINDS.AIMBOT=Enum.KeyCode.Unknown
        KEYBINDS.FLOAT=Enum.KeyCode.Unknown; KEYBINDS.FULLAUTODUEL=Enum.KeyCode.Unknown
        for _,setter in pairs(VisualSetters) do setter(false,true) end
        for k,setter in pairs(SliderSetters) do if Values[k] then setter(Values[k]) end end
        for k,badgeBtn in pairs(KeyBindBtns) do
            local kc=KEYBINDS[k]
            badgeBtn.Text = (kc==Enum.KeyCode.Unknown) and "—" or kc.Name
        end
        stopSpeedBoost(); stopAntiRagdoll(); stopSpinBot(); stopSpamBat(); removeSpamBatCircle()
        stopAutoSteal(); stopGalaxy(); stopSpeedWhileStealing(); stopUnwalk()
        stopAutoWalk(); stopAutoRight(); disableOptimizer(); stopFloat(); stopFullAutoDuel()
        if abActive then abToggle() end
        AutoWalkEnabled=false; AutoRightEnabled=false
        pcall(function() local cam=workspace.CurrentCamera; if cam then cam.FieldOfView=70 end end)
        btn.Text="✓  RESET!"; btn.BackgroundColor3=C.off
        task.delay(1.8,function() btn.Text="🗑  RESET CONFIG"; btn.BackgroundColor3=Color3.fromRGB(55,10,10) end)
        playSound("rbxassetid://6895079813",0.5,0.8)
    end) o+=1

-- ============================================================
-- MINI BUTTON
-- ============================================================
local miniBtn = Instance.new("TextButton", sg)
miniBtn.Size=UDim2.new(0,math.floor(38*GS),0,math.floor(38*GS))
miniBtn.Position=UDim2.new(1,-(math.floor(38*GS)+12),0,12)
miniBtn.BackgroundColor3=C.bg; miniBtn.Text="HH"; miniBtn.TextColor3=C.white
miniBtn.Font=Enum.Font.GothamBlack; miniBtn.TextSize=math.floor(14*GS)
miniBtn.BorderSizePixel=0; miniBtn.Visible=false
rc(miniBtn, math.floor(10*GS)); st(miniBtn, 3, C.white, 0)

onTap(miniBtn, function()
    main.Visible=true; miniBtn.Visible=false; playSound("rbxassetid://6895079813",0.4,1)
end)
onTap(closeBtn, function()
    main.Visible=false; miniBtn.Visible=true; playSound("rbxassetid://6895079813",0.4,1)
end)

-- ============================================================
-- MOBILE FLOATING BUTTONS
-- ============================================================
if isMobile then
    local mobSG = Instance.new("ScreenGui")
    mobSG.Name="ZAY_MOB"; mobSG.ResetOnSpawn=false; mobSG.DisplayOrder=999; mobSG.Parent=Player.PlayerGui

    local function makeDraggableMobBtn(parent, defaultPos, topLabel)
        local BTN_W = 108
        local BTN_H = 50
        local DRAG_THRESHOLD = 8

        local glow = Instance.new("Frame", parent)
        glow.Size = UDim2.new(0, BTN_W + 8, 0, BTN_H + 8)
        glow.Position = UDim2.new(0, defaultPos.X - 4, 0, defaultPos.Y - 4)
        glow.BackgroundColor3 = C.white
        glow.BackgroundTransparency = 0.92
        glow.BorderSizePixel = 0
        rc(glow, 15)

        local cont = Instance.new("Frame", parent)
        cont.Size = UDim2.new(0, BTN_W, 0, BTN_H)
        cont.Position = UDim2.new(0, defaultPos.X, 0, defaultPos.Y)
        cont.BackgroundColor3 = Color3.fromRGB(14, 14, 14)
        cont.BorderSizePixel = 0
        rc(cont, 12)
        local stroke = Instance.new("UIStroke", cont)
        stroke.Thickness = 2; stroke.Color = C.dim
        stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

        local topLbl = Instance.new("TextLabel", cont)
        topLbl.Size = UDim2.new(1, -8, 0.5, -1)
        topLbl.Position = UDim2.new(0, 4, 0, 2)
        topLbl.BackgroundTransparency = 1
        topLbl.Text = topLabel
        topLbl.TextColor3 = C.muted
        topLbl.Font = Enum.Font.GothamBlack
        topLbl.TextSize = 11
        topLbl.TextScaled = false
        topLbl.TextXAlignment = Enum.TextXAlignment.Center

        local statLbl = Instance.new("TextLabel", cont)
        statLbl.Size = UDim2.new(1, -8, 0.5, -2)
        statLbl.Position = UDim2.new(0, 4, 0.5, 0)
        statLbl.BackgroundTransparency = 1
        statLbl.Text = "OFF"
        statLbl.TextColor3 = C.muted
        statLbl.Font = Enum.Font.GothamBold
        statLbl.TextSize = 11
        statLbl.TextXAlignment = Enum.TextXAlignment.Center

        local hitBtn = Instance.new("TextButton", cont)
        hitBtn.Size = UDim2.new(1, 0, 1, 0)
        hitBtn.BackgroundTransparency = 1
        hitBtn.Text = ""
        hitBtn.ZIndex = 10

        local touchActive = false
        local touchId = nil
        local touchStart = nil
        local frameStart = nil
        local hasDragged = false
        local tapCallback = nil

        hitBtn.InputBegan:Connect(function(inp)
            if inp.UserInputType ~= Enum.UserInputType.Touch then return end
            touchActive = true
            touchId = inp
            touchStart = Vector2.new(inp.Position.X, inp.Position.Y)
            frameStart = cont.Position
            hasDragged = false
        end)

        UserInputService.InputChanged:Connect(function(inp)
            if not touchActive or inp ~= touchId then return end
            if inp.UserInputType ~= Enum.UserInputType.Touch then return end
            local delta = Vector2.new(inp.Position.X, inp.Position.Y) - touchStart
            if delta.Magnitude > DRAG_THRESHOLD then hasDragged = true end
            if hasDragged then
                local newX = frameStart.X.Offset + delta.X
                local newY = frameStart.Y.Offset + delta.Y
                cont.Position = UDim2.new(0, newX, 0, newY)
                glow.Position = UDim2.new(0, newX - 4, 0, newY - 4)
            end
        end)

        hitBtn.InputEnded:Connect(function(inp)
            if inp ~= touchId then return end
            if inp.UserInputType ~= Enum.UserInputType.Touch then return end
            touchActive = false
            if not hasDragged and tapCallback then tapCallback() end
        end)

        local function setOn(on)
            local col = on and C.white or C.dim
            TweenService:Create(stroke, TweenInfo.new(0.18), {Color = col}):Play()
            TweenService:Create(glow, TweenInfo.new(0.18), {
                BackgroundColor3 = col,
                BackgroundTransparency = on and 0.72 or 0.92
            }):Play()
            TweenService:Create(cont, TweenInfo.new(0.18), {
                BackgroundColor3 = on and Color3.fromRGB(22,22,22) or Color3.fromRGB(14,14,14)
            }):Play()
            statLbl.Text = on and "ON" or "OFF"
            statLbl.TextColor3 = on and C.white or C.muted
            topLbl.TextColor3 = on and C.white or C.muted
        end

        local function setTapCallback(cb) tapCallback = cb end
        return setOn, setTapCallback
    end

    local vp = workspace.CurrentCamera.ViewportSize
    local startX = math.floor(vp.X - 120)
    local startY = math.floor(vp.Y * 0.30)
    local spacing = 58
    local sbSetOn, sbSetCb = makeDraggableMobBtn(mobSG, Vector2.new(startX, startY + spacing*3), "")
    local sbActive = false
    sbSetCb(function()
        sbActive = not sbActive; sbSetOn(sbActive)
        Enabled.SpeedWhileStealing = sbActive
        if VisualSetters.SpeedWhileStealing then VisualSetters.SpeedWhileStealing(sbActive, true) end
        if sbActive then startSpeedWhileStealing() else stopSpeedWhileStealing() end
        playSound("rbxassetid://6895079813", 0.3, sbActive and 1.1 or 0.9)
    end)

    local flSetOn, flSetCb = makeDraggableMobBtn(mobSG, Vector2.new(startX, startY + spacing*4), "FLOAT")
    local flActive = false
    flSetCb(function()
        flActive = not flActive; flSetOn(flActive)
        Enabled.Float = flActive
        if VisualSetters.Float then VisualSetters.Float(flActive, true) end
        if flActive then startFloat() else stopFloat() end
        playSound("rbxassetid://6895079813", 0.3, flActive and 1.1 or 0.9)
    end)
    local _origFloatSetter = VisualSetters.Float
    VisualSetters.Float = function(on, skipCB)
        flActive = on; flSetOn(on)
        if _origFloatSetter then _origFloatSetter(on, skipCB) end
    end

    onAutoLeftDone = function()
        alActive = false; alSetOn(false)
        AutoWalkEnabled=false; Enabled.AutoWalkEnabled=false
        if VisualSetters.AutoWalkEnabled then VisualSetters.AutoWalkEnabled(false,true) end
    end
    onAutoRightDone = function()
        arActive = false; arSetOn(false)
        AutoRightEnabled=false; Enabled.AutoRightEnabled=false
        if VisualSetters.AutoRightEnabled then VisualSetters.AutoRightEnabled(false,true) end
    end

    local _origSWSetter = VisualSetters.SpeedWhileStealing
    VisualSetters.SpeedWhileStealing = function(on, skipCB)
        sbActive = on; sbSetOn(on)
        if _origSWSetter then _origSWSetter(on, skipCB) end
    end
    abVisualSetter = function(on) abSetOn(on) end
end

-- ============================================================
-- APPLY LOADED CONFIG
-- ============================================================
task.spawn(function()
    task.wait(2.5)
    local c = Player.Character
    if not c or not c:FindFirstChild("HumanoidRootPart") then
        c=Player.CharacterAdded:Wait(); task.wait(1)
    end
    for key,setter in pairs(VisualSetters) do setter(Enabled[key] or false, true) end
    for key,setter in pairs(SliderSetters) do if Values[key] then setter(Values[key]) end end
    for k,badgeBtn in pairs(KeyBindBtns) do
        local kc=KEYBINDS[k]
        badgeBtn.Text = (kc==Enum.KeyCode.Unknown) and "—" or kc.Name
    end
    pcall(function() local cam=workspace.CurrentCamera; if cam and Values.FOV then cam.FieldOfView=Values.FOV end end)
    if Enabled.AntiRagdoll        then startAntiRagdoll()       end
    if Enabled.AutoSteal          then startAutoSteal()          end
    if Enabled.Optimizer          then enableOptimizer()         end
    task.wait(0.3)
    if Enabled.SpeedBoost         then startSpeedBoost()         end
    if Enabled.SpinBot            then startSpinBot()            end
    if Enabled.SpamBat            then startSpamBat(); startSpamBatCircle() end
    if Enabled.Galaxy             then startGalaxy()             end
    if Enabled.SpeedWhileStealing then startSpeedWhileStealing() end
    if Enabled.Unwalk             then startUnwalk()             end
    if Enabled.Float              then startFloat()              end
    if Enabled.AutoWalkEnabled    then AutoWalkEnabled=true; startAutoWalk()   end
    if Enabled.AutoRightEnabled   then AutoRightEnabled=true; startAutoRight() end
    if Enabled.AutoLeftEnabled then AutoLeftEnabled=true; startAutoLeft() end
    if Enabled.FullAutoDuel       then startFullAutoDuel() end
    if Enabled.Aimbot and not abActive then abToggle() end
end)

-- ============================================================
-- KEYBIND DISPATCH
-- ============================================================
local function dispatchKey(kc)
    if kc==KEYBINDS.SPEED and KEYBINDS.SPEED~=Enum.KeyCode.Unknown then
        Enabled.SpeedBoost=not Enabled.SpeedBoost
        if VisualSetters.SpeedBoost then VisualSetters.SpeedBoost(Enabled.SpeedBoost) end
        if Enabled.SpeedBoost then startSpeedBoost() else stopSpeedBoost() end
    end
    if kc==KEYBINDS.SPIN and KEYBINDS.SPIN~=Enum.KeyCode.Unknown then
        Enabled.SpinBot=not Enabled.SpinBot
        if VisualSetters.SpinBot then VisualSetters.SpinBot(Enabled.SpinBot) end
        if Enabled.SpinBot then startSpinBot() else stopSpinBot() end
    end
    if kc==KEYBINDS.GALAXY and KEYBINDS.GALAXY~=Enum.KeyCode.Unknown then
        Enabled.Galaxy=not Enabled.Galaxy
        if VisualSetters.Galaxy then VisualSetters.Galaxy(Enabled.Galaxy) end
        if Enabled.Galaxy then startGalaxy() else stopGalaxy() end
    end
    if kc==KEYBINDS.AUTOLEFT and KEYBINDS.AUTOLEFT~=Enum.KeyCode.Unknown then
        AutoWalkEnabled=not AutoWalkEnabled; Enabled.AutoWalkEnabled=AutoWalkEnabled
        if VisualSetters.AutoWalkEnabled then VisualSetters.AutoWalkEnabled(AutoWalkEnabled) end
        if AutoWalkEnabled then startAutoWalk() else stopAutoWalk() end
    end
    if kc==KEYBINDS.AUTORIGHT and KEYBINDS.AUTORIGHT~=Enum.KeyCode.Unknown then
        AutoRightEnabled=not AutoRightEnabled; Enabled.AutoRightEnabled=AutoRightEnabled
        if VisualSetters.AutoRightEnabled then VisualSetters.AutoRightEnabled(AutoRightEnabled) end
        if AutoRightEnabled then startAutoRight() else stopAutoRight() end
    end
    if kc==KEYBINDS.ANTIRAGDOLL and KEYBINDS.ANTIRAGDOLL~=Enum.KeyCode.Unknown then
        Enabled.AntiRagdoll=not Enabled.AntiRagdoll
        if VisualSetters.AntiRagdoll then VisualSetters.AntiRagdoll(Enabled.AntiRagdoll) end
        if Enabled.AntiRagdoll then startAntiRagdoll() else stopAntiRagdoll() end
    end
    if kc==KEYBINDS.AIMBOT and KEYBINDS.AIMBOT~=Enum.KeyCode.Unknown then abToggle() end
    if kc==KEYBINDS.FLOAT and KEYBINDS.FLOAT~=Enum.KeyCode.Unknown then
        Enabled.Float=not Enabled.Float
        if VisualSetters.Float then VisualSetters.Float(Enabled.Float) end
        if Enabled.Float then startFloat() else stopFloat() end
    end
    if kc==KEYBINDS.FULLAUTODUEL and KEYBINDS.FULLAUTODUEL~=Enum.KeyCode.Unknown then
        Enabled.FullAutoDuel=not Enabled.FullAutoDuel
        if VisualSetters.FullAutoDuel then VisualSetters.FullAutoDuel(Enabled.FullAutoDuel) end
        if Enabled.FullAutoDuel then startFullAutoDuel() else stopFullAutoDuel() end
    end
end

-- ============================================================
-- INPUT HANDLER
-- ============================================================
local guiVisible = true

UserInputService.InputBegan:Connect(function(input, gpe)
    if input.KeyCode==Enum.KeyCode.Space then spaceHeld=true end

    if waitingForKeybind then
        if input.UserInputType~=Enum.UserInputType.Keyboard then return end
        if input.KeyCode==Enum.KeyCode.Unknown then return end
        local k = input.KeyCode
        KEYBINDS[waitingForKeybind] = k
        local badgeBtn = KeyBindBtns[waitingForKeybind]
        if badgeBtn then
            badgeBtn.Text = k.Name
            TweenService:Create(badgeBtn, TweenInfo.new(0.15), {BackgroundColor3 = C.badge}):Play()
        end
        waitingForKeybind = nil
        return
    end

    if gpe then return end

    if input.KeyCode==Enum.KeyCode.U then
        guiVisible=not guiVisible
        main.Visible=guiVisible; miniBtn.Visible=not guiVisible
        return
    end

    dispatchKey(input.KeyCode)
end)

UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode==Enum.KeyCode.Space then spaceHeld=false end
end)

-- ============================================================
-- CHARACTER RESPAWN
-- ============================================================
Player.CharacterAdded:Connect(function()
    task.wait(1)
    if Enabled.SpinBot   then stopSpinBot(); task.wait(0.1); startSpinBot()  end
    if Enabled.Galaxy    then setupGalaxyForce(); adjustGalaxyJump()         end
    if Enabled.SpamBat   then stopSpamBat(); task.wait(0.1); startSpamBat(); startSpamBatCircle() end
    if Enabled.Unwalk    then startUnwalk()   end
    if Enabled.AutoSteal then startAutoSteal() end
    if Enabled.Float     then stopFloat(); task.wait(0.1); startFloat() end
    task.wait(0.5)
    pcall(function() local cam=workspace.CurrentCamera; if cam and Values.FOV then cam.FieldOfView=Values.FOV end end)
end)

print("ZAY DUELS Loaded — Press U to toggle GUI.")


repeat task.wait() until game:IsLoaded()

local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- GUI
local gui = Instance.new("ScreenGui")
gui.Name = "MarcaGui"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

-- Botão
local button = Instance.new("TextButton")
button.Parent = gui
button.Size = UDim2.new(0,60,0,60)
button.Position = UDim2.new(0.02,0,0.4,0)
button.Text = "Taunt"
button.TextColor3 = Color3.fromRGB(255,255,255) -- branco puro
button.TextStrokeTransparency = 0.5 -- leve contorno pra destacar
button.TextScaled = true
button.Font = Enum.Font.GothamBold
button.BackgroundColor3 = Color3.fromRGB(40,40,40)
button.BorderSizePixel = 0
button.Active = true
button.Draggable = true

-- Bordas redondas
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0,12)
corner.Parent = button

-- Gradiente preto (claro em cima / escuro embaixo)
local gradient = Instance.new("UIGradient")
gradient.Parent = button
gradient.Rotation = 90
gradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(80,80,80)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(10,10,10))
}

-- Função de chat
button.MouseButton1Click:Connect(function()
    game:GetService("TextChatService").TextChannels.RBXGeneral:SendAsync("/havoc")
end)

local player = game.Players.LocalPlayer

local function criarTag(char)
    local head = char:WaitForChild("Head")

    if head:FindFirstChild("DiscordTag") then return end

    local gui = Instance.new("BillboardGui")
    gui.Name = "DiscordTag"
    gui.Adornee = head
    gui.Parent = head
    gui.Size = UDim2.new(0,200,0,50)
    gui.StudsOffset = Vector3.new(0,2.5,0)
    gui.AlwaysOnTop = true

    local text = Instance.new("TextLabel")
    text.Parent = gui
    text.Size = UDim2.new(1,0,1,0)
    text.BackgroundTransparency = 1
    text.Text = "discord.gg/fj8vNed6"
    text.TextColor3 = Color3.fromRGB(255,255,255)
    text.TextScaled = true
    text.Font = Enum.Font.SourceSansBold
end

if player.Character then
    criarTag(player.Character)
end

player.CharacterAdded:Connect(criarTag)
