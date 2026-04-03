-- anonym Dumper v2 premium (beta beautify)

local Players  = game:GetService("Players")
local UIS      = game:GetService("UserInputService")
local RS       = game:GetService("RunService")
local TS       = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")

local me   = Players.LocalPlayer
local pgui = me:WaitForChild("PlayerGui")

local cfg = {
    NormalSpeed       = 60,
    CarrySpeed        = 30,
    FloatHeight       = 8,
    DodgeHeight       = 7,
    StealRadius       = 7,
    BatRadius         = 20,
    HardHitRadius     = 10,
    SpinSpeed         = 19,
    GravityPercent    = 70,
    HopPower          = 35,
    JumpPower         = 50,

    SpeedKey          = Enum.KeyCode.Q,

    AutoPlayLeft      = false,
    AutoPlayRight     = false,
    AutoSteal         = true,
    AutoBat           = true,
    BatAimbot         = false,
    AntiRagdoll       = true,
    InfiniteJump      = false,
    Float             = false,
    Dodge             = false,
    SpinBot           = false,
    Unwalk            = true,
    Optimizer         = false,
    PlayerESP         = true,
    LockUI            = false,
    MobileMode        = false,
    HardHit           = true,
    LowGravity        = false,
    FloatPlayL        = false,
    FloatPlayR        = false,
    AutoLeft          = false,
    AutoRight         = false,
    AutoTpLeft        = false,
    AutoTpRight       = false,
}


local T = {
    BG           = Color3.fromRGB(5, 5, 5),
    Surface      = Color3.fromRGB(10, 10, 10),
    Card         = Color3.fromRGB(20, 20, 20),
    CardHover    = Color3.fromRGB(35, 0, 0),
    Input        = Color3.fromRGB(15, 15, 15),
    Separator    = Color3.fromRGB(40, 0, 0),
    Border       = Color3.fromRGB(120, 0, 0),
    BorderHi     = Color3.fromRGB(255, 0, 0),
    Accent       = Color3.fromRGB(200, 0, 0),
    AccentMid    = Color3.fromRGB(220, 0, 0),
    AccentSoft   = Color3.fromRGB(255, 60, 60),
    AccentBright = Color3.fromRGB(255, 120, 120),
    Text         = Color3.fromRGB(255, 255, 255),
    TextSub      = Color3.fromRGB(200, 200, 200),
    TextMuted    = Color3.fromRGB(150, 150, 150),
    TrkOff       = Color3.fromRGB(30, 0, 0),
    TrkOn        = Color3.fromRGB(255, 0, 0),
    KnobOff      = Color3.fromRGB(120, 120, 120),
    KnobOn       = Color3.fromRGB(255, 0, 0),
    PrgBG        = Color3.fromRGB(20, 0, 0),
    PrgFill      = Color3.fromRGB(255, 0, 0),
    ErrRed       = Color3.fromRGB(255, 0, 0),
    Green        = Color3.fromRGB(0, 255, 100)
}

local L1     = Vector3.new(-476.48, -6.28,  92.73)
local LEND   = Vector3.new(-483.12, -4.95,  94.80)
local LFINAL = Vector3.new(-473.38, -8.40,  22.34)
local R1     = Vector3.new(-476.16, -6.52,  25.62)
local REND   = Vector3.new(-483.04, -5.09,  23.14)
local RFINAL = Vector3.new(-476.17, -7.91,  97.91)
local FSPD, RSPD = 59, 30

-- doc 3 TP coords (exact)
local TP_A  = Vector3.new(-472.60, -7.00,  57.52)
local TP_B1 = Vector3.new(-472.65, -7.00,  95.69)
local TP_B2 = Vector3.new(-471.76, -7.00,  26.22)
local TP_F1 = Vector3.new(-483.59, -5.04, 104.24)
local TP_F2 = Vector3.new(-483.51, -5.10,  18.89)



local vHum, vRoot
local function bindChar(char)
    vHum  = char:WaitForChild("Humanoid")
    vRoot = char:WaitForChild("HumanoidRootPart")
end
if me.Character then bindChar(me.Character) end
me.CharacterAdded:Connect(bindChar)

local function getHRP() local c=me.Character; return c and c:FindFirstChild("HumanoidRootPart") end
local function getHum() local c=me.Character; return c and c:FindFirstChildOfClass("Humanoid") end


local speedToggled = false

UIS.InputBegan:Connect(function(inp, gameProcessed)
    if gameProcessed then return end
    if inp.UserInputType == Enum.UserInputType.Keyboard
        and inp.KeyCode == cfg.SpeedKey then
        speedToggled = not speedToggled
    end
end)

RS.Heartbeat:Connect(function()
    if not vHum or not vRoot then return end
    local spd = speedToggled and cfg.NormalSpeed or cfg.CarrySpeed
    local md  = vHum.MoveDirection
    if md.Magnitude > 0 then
        vRoot.AssemblyLinearVelocity = Vector3.new(
            md.X*spd, vRoot.AssemblyLinearVelocity.Y, md.Z*spd)
    end
end)

local IJF, IJC = 50, 80
UIS.JumpRequest:Connect(function()
    if not cfg.InfiniteJump then return end
    local hrp = getHRP(); if not hrp then return end
    hrp.AssemblyLinearVelocity = Vector3.new(
        hrp.AssemblyLinearVelocity.X, IJF, hrp.AssemblyLinearVelocity.Z)
end)
RS.Heartbeat:Connect(function()
    if not cfg.InfiniteJump then return end
    local hrp = getHRP(); if not hrp then return end
    if hrp.AssemblyLinearVelocity.Y < -IJC then
        hrp.AssemblyLinearVelocity = Vector3.new(
            hrp.AssemblyLinearVelocity.X, -IJC, hrp.AssemblyLinearVelocity.Z)
    end
end)


local spinBAV = nil
local function killSpin()
    if spinBAV then spinBAV:Destroy(); spinBAV = nil end
    local c = me.Character
    if c then
        local r = c:FindFirstChild("HumanoidRootPart")
        if r then
            for _,v in pairs(r:GetChildren()) do
                if v.Name == "EgoSpinBAV" then v:Destroy() end
            end
        end
    end
end
local function startSpin()
    killSpin()
    local c = me.Character; if not c then return end
    local root = c:FindFirstChild("HumanoidRootPart"); if not root then return end
    spinBAV = Instance.new("BodyAngularVelocity")
    spinBAV.Name = "EgoSpinBAV"
    spinBAV.MaxTorque = Vector3.new(0, math.huge, 0)
    spinBAV.AngularVelocity = Vector3.new(0, cfg.SpinSpeed, 0)
    spinBAV.Parent = root
end
RS.Heartbeat:Connect(function()
    if cfg.SpinBot and spinBAV and me.Character then
        spinBAV.AngularVelocity = Vector3.new(0, cfg.SpinSpeed, 0)
    end
end)


local ragConns = {}
local lastVel  = Vector3.new()
local function ragClean()
    local char = me.Character; if not char then return end
    for _,v in pairs(char:GetDescendants()) do
        if v:IsA("BallSocketConstraint") or v:IsA("HingeConstraint")
            or v:IsA("NoCollisionConstraint") then
            pcall(function() v:Destroy() end)
        elseif v:IsA("Motor6D") then v.Enabled = true end
    end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        local anim = hum:FindFirstChildOfClass("Animator")
        if anim then
            for _,t in pairs(anim:GetPlayingAnimationTracks()) do
                local n = t.Animation and t.Animation.Name:lower() or ""
                if n:find("rag") or n:find("fall") or n:find("hurt") then t:Stop(0) end
            end
        end
    end
end
local function enableAntiRagdoll()
    local char = me.Character or me.CharacterAdded:Wait()
    local hum  = char:WaitForChild("Humanoid")
    table.insert(ragConns, hum.StateChanged:Connect(function()
        pcall(function() hum:ChangeState(Enum.HumanoidStateType.Running) end)
        ragClean()
    end))
    table.insert(ragConns, RS.Heartbeat:Connect(function()
        if not cfg.AntiRagdoll then return end
        local c = me.Character; if not c then return end
        local hrp = c:FindFirstChild("HumanoidRootPart"); if not hrp then return end
        local vel = hrp.AssemblyLinearVelocity
        if (vel - lastVel).Magnitude > 40 and vel.Magnitude > 25 then
            hrp.AssemblyLinearVelocity = vel.Unit * 15
        end
        lastVel = vel; ragClean()
    end))
end
local function disableAntiRagdoll()
    for _,c in pairs(ragConns) do pcall(function() c:Disconnect() end) end
    ragConns = {}
end
if cfg.AntiRagdoll then enableAntiRagdoll() end


local batCD   = false
local batRing = nil
local function getBat()
    local char = me.Character; if not char then return nil end
    for _,t in ipairs(char:GetChildren()) do
        if t:IsA("Tool") and t.Name:lower():find("bat") then return t end
    end
    local bp = me:FindFirstChild("Backpack")
    if bp then
        for _,t in ipairs(bp:GetChildren()) do
            if t:IsA("Tool") and t.Name:lower():find("bat") then
                t.Parent = char; return t end
        end
    end
end
local function hitBat()
    if batCD then return end; batCD = true
    local bat = getBat()
    if bat then
        pcall(function()
            bat:Activate()
            local evt = bat:FindFirstChildWhichIsA("RemoteEvent")
            if evt then evt:FireServer() end
        end)
    end
    task.delay(0.08, function() batCD = false end)
end
local function closestPlayer()
    local char = me.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil, math.huge end
    local best, bestD = nil, math.huge
    for _,p in ipairs(Players:GetPlayers()) do
        if p ~= me and p.Character
            and p.Character:FindFirstChild("HumanoidRootPart") then
            local d = (hrp.Position
                - p.Character.HumanoidRootPart.Position).Magnitude
            if d < bestD then bestD = d; best = p end
        end
    end
    return best, bestD
end
local function flyToFront(tHRP)
    local char = me.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local front = tHRP.Position + tHRP.CFrame.LookVector * 1.5
    local dir   = Vector3.new(
        front.X - hrp.Position.X, 0, front.Z - hrp.Position.Z)
    if dir.Magnitude < 0.1 then return end
    hrp.AssemblyLinearVelocity = Vector3.new(
        dir.Unit.X*56.5, hrp.AssemblyLinearVelocity.Y, dir.Unit.Z*56.5)
end
local function showBatRing()
    if batRing and batRing.Parent then return end
    local char = me.Character; if not char then return end
    local hrp  = char:FindFirstChild("HumanoidRootPart"); if not hrp then return end
    local r = Instance.new("Part")
    r.Name = "22sBatRing"
    r.Size = Vector3.new(cfg.BatRadius*2, 0.2, cfg.BatRadius*2)
    r.Anchored = true; r.CanCollide = false
    r.Material = Enum.Material.Neon
    r.Color = T.AccentMid; r.Transparency = 0.35
    r.CFrame = CFrame.new(hrp.Position.X, hrp.Position.Y-2.5, hrp.Position.Z)
    r.Parent = workspace
    Instance.new("CylinderMesh", r)
    batRing = r
end
local function hideBatRing()
    if batRing then batRing:Destroy(); batRing = nil end
end
if not _G.TwoBatLoop then
    _G.TwoBatLoop = true
    RS.Heartbeat:Connect(function()
        if not cfg.AutoBat then return end
        local char = me.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        if batRing and batRing.Parent and hrp then
            batRing.CFrame = CFrame.new(
                hrp.Position.X, hrp.Position.Y-2.5, hrp.Position.Z)
            batRing.Size = Vector3.new(cfg.BatRadius*2, 0.2, cfg.BatRadius*2)
        end
        if not hrp then return end
        local target, dist = closestPlayer()
        if target and target.Character
            and target.Character:FindFirstChild("HumanoidRootPart") then
            flyToFront(target.Character.HumanoidRootPart)
            if dist <= 5 then hitBat() end
        end
    end)
end
if cfg.AutoBat then showBatRing() end


local espConns = {}
local function makeESP(plr)
    if plr == me or not plr.Character then return end
    local char = plr.Character
    pcall(function() char["runji"]:Destroy() end)
    pcall(function() char["runji"]:Destroy() end)
    local hrp  = char:FindFirstChild("HumanoidRootPart")
    local head = char:FindFirstChild("Head")
    if not (hrp and head) then return end
    local box = Instance.new("BoxHandleAdornment")
    box.Name = "runji"; box.Adornee = hrp
    box.Size = Vector3.new(4,6,2); box.Color3 = T.AccentMid
    box.Transparency = 0.5; box.ZIndex = 10
    box.AlwaysOnTop = true; box.Parent = char
    local bb = Instance.new("BillboardGui")
    bb.Name = "runjiName"; bb.Adornee = head
    bb.Size = UDim2.new(0,200,0,50)
    bb.StudsOffset = Vector3.new(0,3,0)
    bb.AlwaysOnTop = true; bb.Parent = char
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1,0,1,0)
    lbl.BackgroundTransparency = 1
    lbl.Text = plr.DisplayName or plr.Name
    lbl.TextColor3 = T.AccentBright
    lbl.Font = Enum.Font.GothamBold
    lbl.TextScaled = true
    lbl.TextStrokeTransparency = 0.5
    lbl.Parent = bb
end
local function removeESP(plr)
    if not plr.Character then return end
    pcall(function() plr.Character["runjihub"]:Destroy() end)
    pcall(function() plr.Character["runjihub"]:Destroy() end)
end
local function enableESP()
    for _,plr in ipairs(Players:GetPlayers()) do
        if plr ~= me then
            if plr.Character then makeESP(plr) end
            table.insert(espConns, plr.CharacterAdded:Connect(function()
                task.wait(0.1)
                if cfg.PlayerESP then makeESP(plr) end
            end))
        end
    end
    table.insert(espConns, Players.PlayerAdded:Connect(function(plr)
        if plr == me then return end
        table.insert(espConns, plr.CharacterAdded:Connect(function()
            task.wait(0.1)
            if cfg.PlayerESP then makeESP(plr) end
        end))
    end))
end
local function disableESP()
    for _,plr in ipairs(Players:GetPlayers()) do removeESP(plr) end
    for _,c in ipairs(espConns) do
        if c and c.Connected then c:Disconnect() end
    end
    espConns = {}
end
me.CharacterAdded:Connect(function()
    task.wait(0.1)
    if cfg.PlayerESP then enableESP() end
end)
if cfg.PlayerESP then enableESP() end


local xrayOrig = {}
local function enableOptimizer()
    pcall(function()
        settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 9e9; Lighting.FogStart = 9e9
        for _,fx in ipairs(Lighting:GetChildren()) do
            if fx:IsA("PostEffect") then fx.Enabled = false end
        end
    end)
    pcall(function()
        for _,obj in ipairs(workspace:GetDescendants()) do
            pcall(function()
                if obj:IsA("ParticleEmitter") or obj:IsA("Trail")
                    or obj:IsA("Beam") or obj:IsA("Smoke")
                    or obj:IsA("Fire") or obj:IsA("Sparkles") then
                    obj.Enabled = false; obj:Destroy()
                elseif obj:IsA("SelectionBox") then obj:Destroy()
                elseif obj:IsA("BasePart") then
                    obj.CastShadow = false
                    for _,child in ipairs(obj:GetChildren()) do
                        if child:IsA("Decal") or child:IsA("Texture")
                            or child:IsA("SurfaceAppearance") then
                            child:Destroy() end
                    end
                elseif obj:IsA("Sky") then obj:Destroy() end
            end)
        end
    end)
end
local function disableOptimizer()
    pcall(function()
        settings().Rendering.QualityLevel = Enum.QualityLevel.Automatic
        Lighting.GlobalShadows = true
        Lighting.FogEnd = 100000; Lighting.FogStart = 0
    end)
end
local function enableXray()
    xrayOrig = {}
    pcall(function()
        for _,obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") and obj.Anchored and
                (obj.Name:lower():find("base") or
                (obj.Parent and obj.Parent.Name:lower():find("base"))) then
                xrayOrig[obj] = obj.LocalTransparencyModifier
                obj.LocalTransparencyModifier = 0.88
            end
        end
    end)
end
local function disableXray()
    for part, val in pairs(xrayOrig) do
        if part and part.Parent then
            part.LocalTransparencyModifier = val
        end
    end
    xrayOrig = {}
end


local floatConn = nil
local function startFloat()
    if floatConn then floatConn:Disconnect() end
    local char = me.Character
    if char then
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then
            hrp.CFrame = CFrame.new(
                hrp.Position.X, hrp.Position.Y + cfg.FloatHeight, hrp.Position.Z)
            hrp.AssemblyLinearVelocity = Vector3.new(
                hrp.AssemblyLinearVelocity.X, 0, hrp.AssemblyLinearVelocity.Z)
        end
    end
    floatConn = RS.Heartbeat:Connect(function()
        if not cfg.Float then floatConn:Disconnect(); floatConn = nil; return end
        local c = me.Character; if not c then return end
        local h = c:FindFirstChild("HumanoidRootPart"); if not h then return end
        h.AssemblyLinearVelocity = Vector3.new(
            h.AssemblyLinearVelocity.X, 0, h.AssemblyLinearVelocity.Z)
    end)
end
local function stopFloat()
    cfg.Float = false
    if floatConn then floatConn:Disconnect(); floatConn = nil end
end


local dodgeConn = nil
local function startDodge()
    if dodgeConn then dodgeConn:Disconnect() end
    local char = me.Character
    if char then
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then
            hrp.CFrame = CFrame.new(
                hrp.Position.X, hrp.Position.Y + cfg.DodgeHeight, hrp.Position.Z)
            hrp.AssemblyLinearVelocity = Vector3.new(
                hrp.AssemblyLinearVelocity.X, 0, hrp.AssemblyLinearVelocity.Z)
        end
    end
    dodgeConn = RS.Heartbeat:Connect(function()
        if not cfg.Dodge then dodgeConn:Disconnect(); dodgeConn = nil; return end
        local c = me.Character; if not c then return end
        local h = c:FindFirstChild("HumanoidRootPart"); if not h then return end
        h.AssemblyLinearVelocity = Vector3.new(
            h.AssemblyLinearVelocity.X, 0, h.AssemblyLinearVelocity.Z)
    end)
end
local function stopDodge()
    cfg.Dodge = false
    if dodgeConn then dodgeConn:Disconnect(); dodgeConn = nil end
end

local hhRing = nil
local function showHHRing()
    local char = me.Character; if not char then return end
    local hrp  = char:FindFirstChild("HumanoidRootPart"); if not hrp then return end
    if hhRing and hhRing.Parent then return end
    local cyl = Instance.new("CylinderHandleAdornment")
    cyl.Name = "runjiHHRing"; cyl.Adornee = hrp
    cyl.Color3 = T.AccentSoft; cyl.AlwaysOnTop = true; cyl.Transparency = 0
    cyl.Radius = cfg.HardHitRadius
    cyl.InnerRadius = cfg.HardHitRadius - 0.3
    cyl.Height = 0.15
    cyl.CFrame = CFrame.new(0, -3, 0)
    cyl.Parent = hrp; hhRing = cyl
end
local function hideHHRing()
    if hhRing then hhRing:Destroy(); hhRing = nil end
end
RS.Heartbeat:Connect(function()
    if not cfg.HardHit then return end
    local char = me.Character; if not char then return end
    if not char:FindFirstChild("HumanoidRootPart") then return end
    if not hhRing or not hhRing.Parent then showHHRing() end
    if hhRing then
        hhRing.Radius = cfg.HardHitRadius
        hhRing.InnerRadius = cfg.HardHitRadius - 0.3
    end
end)
if cfg.HardHit then showHHRing() end


local unwalkConn = nil
local function enableUnwalk()
    local char = me.Character; if not char then return end
    local hum  = char:FindFirstChildOfClass("Humanoid"); if not hum then return end
    local anim = hum:FindFirstChildOfClass("Animator"); if not anim then return end
    for _,t in ipairs(anim:GetPlayingAnimationTracks()) do t:Stop(0) end
    if unwalkConn then unwalkConn:Disconnect() end
    unwalkConn = RS.Heartbeat:Connect(function()
        if not cfg.Unwalk then
            unwalkConn:Disconnect(); unwalkConn = nil; return end
        local c = me.Character; if not c then return end
        local h = c:FindFirstChildOfClass("Humanoid"); if not h then return end
        local an = h:FindFirstChildOfClass("Animator"); if not an then return end
        for _,t in ipairs(an:GetPlayingAnimationTracks()) do t:Stop(0) end
    end)
end
local function disableUnwalk()
    if unwalkConn then unwalkConn:Disconnect(); unwalkConn = nil end
end
if cfg.Unwalk then enableUnwalk() end


local normalGrav  = workspace.Gravity
local lowGravConn = nil
local function applyLowGrav()
    if not cfg.LowGravity then
        workspace.Gravity = normalGrav
        if lowGravConn then lowGravConn:Disconnect(); lowGravConn = nil end
        return
    end
    workspace.Gravity = normalGrav * (cfg.GravityPercent / 100)
    if lowGravConn then lowGravConn:Disconnect() end
    lowGravConn = RS.Heartbeat:Connect(function()
        if not cfg.LowGravity then
            workspace.Gravity = normalGrav
            lowGravConn:Disconnect(); lowGravConn = nil; return
        end
        workspace.Gravity = normalGrav * (cfg.GravityPercent / 100)
        local char = me.Character; if not char then return end
        local hrp  = char:FindFirstChild("HumanoidRootPart"); if not hrp then return end
        if hrp.AssemblyLinearVelocity.Y < -cfg.HopPower then
            hrp.AssemblyLinearVelocity = Vector3.new(
                hrp.AssemblyLinearVelocity.X,
                -cfg.HopPower,
                hrp.AssemblyLinearVelocity.Z)
        end
    end)
end


local isTeleporting = false
local hasRecovered  = true

local function moveTo(pos)
    local char = me.Character; if not char then return end
    char:PivotTo(CFrame.new(pos))
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if hrp then hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0) end
end

local function executeTpSequence(side)
    isTeleporting = true
    hasRecovered  = false
    local targetB     = side == "Left" and TP_B1 or TP_B2
    local targetFinal = side == "Left" and TP_F1 or TP_F2
    moveTo(TP_A);    task.wait(0.12)
    moveTo(targetB); task.wait(0.12)
    moveTo(targetFinal)
    isTeleporting = false
end

RS.Heartbeat:Connect(function()
    local char = me.Character
    local hum  = char and char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    local state  = hum:GetState()
    local isRag  = (state == Enum.HumanoidStateType.Physics
        or state == Enum.HumanoidStateType.Ragdoll
        or state == Enum.HumanoidStateType.FallingDown)
    if not isRag then hasRecovered = true end
    if not isTeleporting and hasRecovered and isRag then
        if cfg.AutoTpLeft then
            task.spawn(function() executeTpSequence("Left") end)
        elseif cfg.AutoTpRight then
            task.spawn(function() executeTpSequence("Right") end)
        end
    end
end)

local alEnabled, arEnabled = false, false
local alPhase,   arPhase   = 1, 1
local alConn,    arConn    = nil, nil
local function stopAutoLeft()
    if alConn then alConn:Disconnect(); alConn = nil end
    alPhase = 1; alEnabled = false
    local h = getHum(); if h then h:Move(Vector3.zero, false) end
end
local function stopAutoRight()
    if arConn then arConn:Disconnect(); arConn = nil end
    arPhase = 1; arEnabled = false
    local h = getHum(); if h then h:Move(Vector3.zero, false) end
end
local function startAutoLeft()
    if alConn then alConn:Disconnect() end; alPhase = 1
    alConn = RS.Heartbeat:Connect(function()
        if not alEnabled then return end
        local h, hum = getHRP(), getHum(); if not h or not hum then return end
        local target = alPhase == 1 and L1 or LEND
        local d = Vector3.new(
            target.X - h.Position.X, 0, target.Z - h.Position.Z)
        if d.Magnitude < 1 then
            if alPhase == 1 then alPhase = 2; return
            else
                hum:Move(Vector3.zero, false)
                h.AssemblyLinearVelocity = Vector3.new(0,0,0)
                stopAutoLeft(); return
            end
        end
        local md = d.Unit; hum:Move(md, false)
        h.AssemblyLinearVelocity = Vector3.new(
            md.X*FSPD, h.AssemblyLinearVelocity.Y, md.Z*FSPD)
    end)
end
local function startAutoRight()
    if arConn then arConn:Disconnect() end; arPhase = 1
    arConn = RS.Heartbeat:Connect(function()
        if not arEnabled then return end
        local h, hum = getHRP(), getHum(); if not h or not hum then return end
        local target = arPhase == 1 and R1 or REND
        local d = Vector3.new(
            target.X - h.Position.X, 0, target.Z - h.Position.Z)
        if d.Magnitude < 1 then
            if arPhase == 1 then arPhase = 2; return
            else
                hum:Move(Vector3.zero, false)
                h.AssemblyLinearVelocity = Vector3.new(0,0,0)
                stopAutoRight(); return
            end
        end
        local md = d.Unit; hum:Move(md, false)
        h.AssemblyLinearVelocity = Vector3.new(
            md.X*FSPD, h.AssemblyLinearVelocity.Y, md.Z*FSPD)
    end)
end
local aplConn, aprConn   = nil, nil
local aplOn,   aprOn     = false, false
local aplPhase, aprPhase = 1, 1
local function stopAutoPlayLeft()
    if aplConn then aplConn:Disconnect(); aplConn = nil end
    aplPhase = 1; aplOn = false
    local h = getHum(); if h then h:Move(Vector3.zero, false) end
end
local function stopAutoPlayRight()
    if aprConn then aprConn:Disconnect(); aprConn = nil end
    aprPhase = 1; aprOn = false
    local h = getHum(); if h then h:Move(Vector3.zero, false) end
end
local function startAutoPlayLeft()
    if aplConn then aplConn:Disconnect() end; aplPhase = 1
    aplConn = RS.Heartbeat:Connect(function()
        if not aplOn then return end
        local h, hum = getHRP(), getHum(); if not h or not hum then return end
        if aplPhase == 1 then
            local d = Vector3.new(L1.X-h.Position.X, 0, L1.Z-h.Position.Z)
            if d.Magnitude < 1 then aplPhase = 2; return end
            local md = d.Unit; hum:Move(md, false)
            h.AssemblyLinearVelocity = Vector3.new(
                md.X*FSPD, h.AssemblyLinearVelocity.Y, md.Z*FSPD)
        elseif aplPhase == 2 then
            local d = Vector3.new(LEND.X-h.Position.X, 0, LEND.Z-h.Position.Z)
            if d.Magnitude < 1 then
                aplPhase = 0; hum:Move(Vector3.zero, false)
                h.AssemblyLinearVelocity = Vector3.new(0,0,0)
                task.delay(0.1, function() if aplOn then aplPhase = 3 end end)
                return
            end
            local md = d.Unit; hum:Move(md, false)
            h.AssemblyLinearVelocity = Vector3.new(
                md.X*FSPD, h.AssemblyLinearVelocity.Y, md.Z*FSPD)
        elseif aplPhase == 0 then return
        elseif aplPhase == 3 then
            local d = Vector3.new(L1.X-h.Position.X, 0, L1.Z-h.Position.Z)
            if d.Magnitude < 1 then aplPhase = 4; return end
            local md = d.Unit; hum:Move(md, false)
            local vy = cfg.FloatPlayL
                and math.clamp((11-h.Position.Y)*5, -RSPD, RSPD)
                or h.AssemblyLinearVelocity.Y
            h.AssemblyLinearVelocity = Vector3.new(md.X*RSPD, vy, md.Z*RSPD)
        elseif aplPhase == 4 then
            local d = Vector3.new(LFINAL.X-h.Position.X, 0, LFINAL.Z-h.Position.Z)
            if d.Magnitude < 1 then
                hum:Move(Vector3.zero, false)
                h.AssemblyLinearVelocity = Vector3.new(0,0,0)
                stopAutoPlayLeft(); return
            end
            local md = d.Unit; hum:Move(md, false)
            local vy = cfg.FloatPlayL
                and math.clamp((11-h.Position.Y)*5, -RSPD, RSPD)
                or h.AssemblyLinearVelocity.Y
            h.AssemblyLinearVelocity = Vector3.new(md.X*RSPD, vy, md.Z*RSPD)
        end
    end)
end
local function startAutoPlayRight()
    if aprConn then aprConn:Disconnect() end; aprPhase = 1
    aprConn = RS.Heartbeat:Connect(function()
        if not aprOn then return end
        local h, hum = getHRP(), getHum(); if not h or not hum then return end
        if aprPhase == 1 then
            local d = Vector3.new(R1.X-h.Position.X, 0, R1.Z-h.Position.Z)
            if d.Magnitude < 1 then aprPhase = 2; return end
            local md = d.Unit; hum:Move(md, false)
            h.AssemblyLinearVelocity = Vector3.new(
                md.X*FSPD, h.AssemblyLinearVelocity.Y, md.Z*FSPD)
        elseif aprPhase == 2 then
            local d = Vector3.new(REND.X-h.Position.X, 0, REND.Z-h.Position.Z)
            if d.Magnitude < 1 then
                aprPhase = 0; hum:Move(Vector3.zero, false)
                h.AssemblyLinearVelocity = Vector3.new(0,0,0)
                task.delay(0.1, function() if aprOn then aprPhase = 3 end end)
                return
            end
            local md = d.Unit; hum:Move(md, false)
            h.AssemblyLinearVelocity = Vector3.new(
                md.X*FSPD, h.AssemblyLinearVelocity.Y, md.Z*FSPD)
        elseif aprPhase == 0 then return
        elseif aprPhase == 3 then
            local d = Vector3.new(R1.X-h.Position.X, 0, R1.Z-h.Position.Z)
            if d.Magnitude < 1 then aprPhase = 4; return end
            local md = d.Unit; hum:Move(md, false)
            local vy = cfg.FloatPlayR
                and math.clamp((11-h.Position.Y)*5, -RSPD, RSPD)
                or h.AssemblyLinearVelocity.Y
            h.AssemblyLinearVelocity = Vector3.new(md.X*RSPD, vy, md.Z*RSPD)
        elseif aprPhase == 4 then
            local d = Vector3.new(RFINAL.X-h.Position.X, 0, RFINAL.Z-h.Position.Z)
            if d.Magnitude < 1 then
                hum:Move(Vector3.zero, false)
                h.AssemblyLinearVelocity = Vector3.new(0,0,0)
                stopAutoPlayRight(); return
            end
            local md = d.Unit; hum:Move(md, false)
            local vy = cfg.FloatPlayR
                and math.clamp((11-h.Position.Y)*5, -RSPD, RSPD)
                or h.AssemblyLinearVelocity.Y
            h.AssemblyLinearVelocity = Vector3.new(md.X*RSPD, vy, md.Z*RSPD)
        end
    end)
end

local stealActive  = cfg.AutoSteal
local stealConn    = nil
local isStealing   = false
local animalCache  = {}
local promptCache  = {}
local stealCache   = {}
local AnimalsData  = {}
pcall(function()
    local rep   = game:GetService("ReplicatedStorage")
    local datas = rep:FindFirstChild("Datas")
    if datas then
        local animals = datas:FindFirstChild("Animals")
        if animals then AnimalsData = require(animals) end
    end
end)
local function stealHRP()
    local c = me.Character; if not c then return nil end
    return c:FindFirstChild("HumanoidRootPart")
        or c:FindFirstChild("UpperTorso")
end
local function isMyBase(plotName)
    local plots = workspace:FindFirstChild("Plots")
    local plot  = plots and plots:FindFirstChild(plotName)
    if not plot then return false end
    local sign = plot:FindFirstChild("PlotSign")
    if not sign then return false end
    local yb = sign:FindFirstChild("YourBase")
    return yb and yb:IsA("BillboardGui") and yb.Enabled == true
end
local function scanPlot(plot)
    if not plot or not plot:IsA("Model") then return end
    if isMyBase(plot.Name) then return end
    local podiums = plot:FindFirstChild("AnimalPodiums")
    if not podiums then return end
    for _,pod in ipairs(podiums:GetChildren()) do
        if pod:IsA("Model") and pod:FindFirstChild("Base") then
            local name  = "Unknown"
            local spawn = pod.Base:FindFirstChild("Spawn")
            if spawn then
                for _,child in ipairs(spawn:GetChildren()) do
                    if child:IsA("Model")
                        and child.Name ~= "PromptAttachment" then
                        name = child.Name
                        local info = AnimalsData[name]
                        if info and info.DisplayName then
                            name = info.DisplayName end
                        break
                    end
                end
            end
            table.insert(animalCache, {
                name = name, plot = plot.Name, slot = pod.Name,
                worldPosition = pod:GetPivot().Position,
                uid  = plot.Name.."_"..pod.Name,
            })
        end
    end
end
local function findPrompt(ad)
    if not ad then return nil end
    local cp = promptCache[ad.uid]
    if cp and cp.Parent then return cp end
    local plots = workspace:FindFirstChild("Plots")
    if not plots then return nil end
    local plot  = plots:FindFirstChild(ad.plot); if not plot  then return nil end
    local pods  = plot:FindFirstChild("AnimalPodiums"); if not pods  then return nil end
    local pod   = pods:FindFirstChild(ad.slot); if not pod   then return nil end
    local base  = pod:FindFirstChild("Base"); if not base  then return nil end
    local sp    = base:FindFirstChild("Spawn"); if not sp    then return nil end
    local att   = sp:FindFirstChild("PromptAttachment"); if not att then return nil end
    for _,p in ipairs(att:GetChildren()) do
        if p:IsA("ProximityPrompt") then
            promptCache[ad.uid] = p; return p end
    end
end
local function buildCallbacks(prompt)
    if stealCache[prompt] then return end
    local data = {holdCallbacks={}, triggerCallbacks={}, ready=true}
    local ok1,c1 = pcall(getconnections, prompt.PromptButtonHoldBegan)
    if ok1 and type(c1)=="table" then
        for _,conn in ipairs(c1) do
            if type(conn.Function)=="function" then
                table.insert(data.holdCallbacks, conn.Function) end
        end
    end
    local ok2,c2 = pcall(getconnections, prompt.Triggered)
    if ok2 and type(c2)=="table" then
        for _,conn in ipairs(c2) do
            if type(conn.Function)=="function" then
                table.insert(data.triggerCallbacks, conn.Function) end
        end
    end
    if #data.holdCallbacks>0 or #data.triggerCallbacks>0 then
        stealCache[prompt] = data end
end
local function execSteal(prompt)
    local data = stealCache[prompt]
    if not data or not data.ready then return false end
    data.ready = false; isStealing = true
    task.spawn(function()
        for _,fn in ipairs(data.holdCallbacks) do task.spawn(fn) end
        task.wait(0.2)
        for _,fn in ipairs(data.triggerCallbacks) do task.spawn(fn) end
        task.wait(0.01); data.ready = true
        task.wait(0.01); isStealing = false
    end)
    return true
end
local function nearestAnimal()
    local hrp = stealHRP(); if not hrp then return nil end
    local best, bestD = nil, math.huge
    for _,ad in ipairs(animalCache) do
        if not isMyBase(ad.plot) and ad.worldPosition then
            local d = (hrp.Position - ad.worldPosition).Magnitude
            if d < bestD then bestD = d; best = ad end
        end
    end
    return best
end
local function startStealLoop()
    if stealConn then stealConn:Disconnect() end
    stealConn = RS.Heartbeat:Connect(function()
        if not stealActive or isStealing then return end
        local target = nearestAnimal(); if not target then return end
        local hrp = stealHRP(); if not hrp then return end
        if (hrp.Position - target.worldPosition).Magnitude
            > cfg.StealRadius then return end
        local prompt = promptCache[target.uid]
        if not prompt or not prompt.Parent then
            prompt = findPrompt(target) end
        if prompt then buildCallbacks(prompt); execSteal(prompt) end
    end)
end
task.spawn(function()
    task.wait(2)
    local plots = workspace:WaitForChild("Plots", 10)
    if not plots then return end
    for _,plot in ipairs(plots:GetChildren()) do
        if plot:IsA("Model") then scanPlot(plot) end
    end
    plots.ChildAdded:Connect(function(plot)
        if plot:IsA("Model") then task.wait(0.5); scanPlot(plot) end
    end)
    task.spawn(function()
        while task.wait(5) do
            animalCache = {}
            for _,plot in ipairs(plots:GetChildren()) do
                if plot:IsA("Model") then scanPlot(plot) end
            end
        end
    end)
end)
startStealLoop()

-- respawn wiring
me.CharacterAdded:Connect(function()
    task.wait(0.5)
    if cfg.AntiRagdoll then disableAntiRagdoll(); enableAntiRagdoll() end
    if cfg.SpinBot then killSpin(); startSpin() end
    if cfg.PlayerESP then enableESP() end
    if cfg.Unwalk then enableUnwalk() end
    if cfg.HardHit then showHHRing() end
end)


local function tw(obj,props,t,sty,dir)
    TS:Create(obj, TweenInfo.new(t or .18,
        sty  or Enum.EasingStyle.Quart,
        dir  or Enum.EasingDirection.Out), props):Play()
end
local function New(cls, parent, props)
    local o = Instance.new(cls)
    for k,v in pairs(props or {}) do o[k] = v end
    if parent then o.Parent = parent end
    return o
end
local function Corner(p,r)
    New("UICorner", p, {CornerRadius = UDim.new(0, r or 8)})
end
local function Stroke(p,c,t,tr)
    New("UIStroke", p, {
        Color=c or T.Border, Thickness=t or 1, Transparency=tr or 0})
end
local function Pad(p,top,bot,l,r)
    New("UIPadding", p, {
        PaddingTop    = UDim.new(0, top or 0),
        PaddingBottom = UDim.new(0, bot or 0),
        PaddingLeft   = UDim.new(0, l   or 0),
        PaddingRight  = UDim.new(0, r   or 0),
    })
end


local Gui = New("ScreenGui", pgui, {
    Name="runjihub", ResetOnSpawn=false,
    DisplayOrder=10, IgnoreGuiInset=true,
    ZIndexBehavior=Enum.ZIndexBehavior.Sibling,
})

local Main = New("Frame", Gui, {
    Name="Main",
    Size=UDim2.new(0,340,0,628), Position=UDim2.new(1,-349,0,18),
    BackgroundColor3=T.BG, BackgroundTransparency=.03,
    BorderSizePixel=0, ClipsDescendants=true, ZIndex=2, Active=true,
})
Corner(Main, 22)

local Stripe = New("Frame", Main, {
    Size=UDim2.new(.4,0,0,2), Position=UDim2.new(.3,0,0,0),
    BackgroundColor3=T.AccentSoft, BorderSizePixel=0, ZIndex=5,
})
Corner(Stripe, 1)

-- bob home tracking
local homeX    = Main.Position.X.Offset
local homeY    = Main.Position.Y.Offset
local bobTime  = 0
local isDragging = false


local Hdr = New("Frame", Main, {
    Name="Header", Size=UDim2.new(1,0,0,96),
    BackgroundColor3=T.Surface, BorderSizePixel=0,
    ZIndex=3, Active=true,
})
New("Frame", Hdr, {
    Size=UDim2.new(1,0,0,1), Position=UDim2.new(0,0,1,-1),
    BackgroundColor3=T.Border, BorderSizePixel=0, ZIndex=4,
})

local PingLbl = New("TextLabel", Hdr, {
    Size=UDim2.new(0,70,0,16), Position=UDim2.new(0,14,0,6),
    BackgroundTransparency=1, Text="0ms",
    Font=Enum.Font.GothamBold, TextSize=11,
    TextColor3=T.TextMuted, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=5,
})
local FPSLbl = New("TextLabel", Hdr, {
    Size=UDim2.new(0,70,0,16), Position=UDim2.new(1,-84,0,6),
    BackgroundTransparency=1, Text="0 FPS",
    Font=Enum.Font.GothamBold, TextSize=11,
    TextColor3=T.TextMuted, TextXAlignment=Enum.TextXAlignment.Right, ZIndex=5,
})
New("TextLabel", Hdr, {
    Size=UDim2.new(1,0,0,28), Position=UDim2.new(0,0,0,18),
    BackgroundTransparency=1, Text="runji HUB",
    Font=Enum.Font.GothamBlack, TextSize=22,
    TextColor3=T.AccentBright, TextXAlignment=Enum.TextXAlignment.Center,
    TextStrokeTransparency=0.5, TextStrokeColor3=T.Accent, ZIndex=5,
})
New("TextLabel", Hdr, {
    Size=UDim2.new(1,0,0,14), Position=UDim2.new(0,0,0,46),
    BackgroundTransparency=1, Text="discord.gg/22s",
    Font=Enum.Font.Gotham, TextSize=11,
    TextColor3=T.TextMuted, TextXAlignment=Enum.TextXAlignment.Center, ZIndex=5,
})

local SaveBtn = New("TextButton", Hdr, {
    Size=UDim2.new(1,-24,0,26), Position=UDim2.new(0,12,0,62),
    BackgroundColor3=T.Card, BorderSizePixel=0,
    Text="⇓  SAVE CONFIG", TextColor3=T.AccentBright,
    Font=Enum.Font.GothamBold, TextSize=11, ZIndex=6,
})
Corner(SaveBtn, 7); Stroke(SaveBtn, T.BorderHi, 1, .4)
SaveBtn.MouseEnter:Connect(function()
    tw(SaveBtn, {BackgroundColor3=T.CardHover}, .1) end)
SaveBtn.MouseLeave:Connect(function()
    tw(SaveBtn, {BackgroundColor3=T.Card}, .1) end)
SaveBtn.MouseButton1Click:Connect(function()
    tw(SaveBtn, {BackgroundColor3=T.Accent}, .08)
    task.delay(.2, function() tw(SaveBtn, {BackgroundColor3=T.Card}, .25) end)
end)

local CloseBtn = New("TextButton", Hdr, {
    Size=UDim2.new(0,26,0,26), Position=UDim2.new(1,-34,0,10),
    BackgroundColor3=Color3.fromRGB(44,18,18), BackgroundTransparency=.3,
    BorderSizePixel=0, Text="✕", TextColor3=T.ErrRed,
    TextSize=14, Font=Enum.Font.GothamBold, ZIndex=6,
})
Corner(CloseBtn, 13)
CloseBtn.MouseEnter:Connect(function()
    tw(CloseBtn, {BackgroundTransparency=0}, .1) end)
CloseBtn.MouseLeave:Connect(function()
    tw(CloseBtn, {BackgroundTransparency=.3}, .1) end)
CloseBtn.MouseButton1Click:Connect(function()
    tw(Main, {BackgroundTransparency=1}, .25, Enum.EasingStyle.Quart)
    task.delay(.3, function() Gui:Destroy() end)
end)

do
    local drag, ds, sp = false, nil, nil

    Hdr.InputBegan:Connect(function(i)
        if cfg.LockUI then return end
        if i.UserInputType == Enum.UserInputType.MouseButton1
            or i.UserInputType == Enum.UserInputType.Touch then
            drag       = true
            isDragging = true
            ds         = i.Position
            sp         = Main.Position
        end
    end)

    UIS.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
            or i.UserInputType == Enum.UserInputType.Touch then
            if drag then
                homeX = Main.Position.X.Offset
                homeY = Main.Position.Y.Offset
            end
            drag       = false
            isDragging = false
        end
    end)

    UIS.InputChanged:Connect(function(i)
        if cfg.LockUI then drag=false; isDragging=false; return end
        if not drag then return end
        if i.UserInputType == Enum.UserInputType.MouseMovement
            or i.UserInputType == Enum.UserInputType.Touch then
            local d = i.Position - ds
            Main.Position = UDim2.new(
                sp.X.Scale, sp.X.Offset + d.X,
                sp.Y.Scale, sp.Y.Offset + d.Y)
        end
    end)
end


local Scroll = New("ScrollingFrame", Main, {
    Size=UDim2.new(1,0,1,-96), Position=UDim2.new(0,0,0,96),
    BackgroundTransparency=1, BorderSizePixel=0,
    ScrollBarThickness=3, ScrollBarImageColor3=T.AccentMid,
    AutomaticCanvasSize=Enum.AutomaticSize.Y,
    CanvasSize=UDim2.new(0,0,0,0), ZIndex=2,
    ScrollingDirection=Enum.ScrollingDirection.Y,
    ElasticBehavior=Enum.ElasticBehavior.Never,
})
New("UIListLayout", Scroll, {
    SortOrder=Enum.SortOrder.LayoutOrder, Padding=UDim.new(0,3)})
Pad(Scroll, 8, 14, 10, 12)

local order = 0
local function O() order=order+1; return order end

local function Section(text)
    local w = New("Frame", Scroll, {Size=UDim2.new(1,0,0,24),
        BackgroundTransparency=1, LayoutOrder=O()})
    local pip = New("Frame", w, {Size=UDim2.new(0,3,0,11),
        Position=UDim2.new(0,2,.5,-5),
        BackgroundColor3=T.AccentSoft, BorderSizePixel=0})
    Corner(pip, 2)
    New("TextLabel", w, {Size=UDim2.new(1,-14,1,0), Position=UDim2.new(0,10,0,0),
        BackgroundTransparency=1, Text=text,
        Font=Enum.Font.GothamBold, TextSize=9,
        TextColor3=T.TextMuted, TextXAlignment=Enum.TextXAlignment.Left})
end
local function Rule()
    New("Frame", Scroll, {Size=UDim2.new(1,-6,0,1),
        BackgroundColor3=T.Separator, BorderSizePixel=0, LayoutOrder=O()})
end
local function Space(h)
    New("Frame", Scroll, {Size=UDim2.new(1,0,0,h or 4),
        BackgroundTransparency=1, LayoutOrder=O()})
end

-- toggle registry — stores fn + dot ref for pill sync
local toggleRegistry = {}

-- keybind map: KeyCode.Name -> doToggle fn
local keybindMap = {}

-- global listener fires any bound toggle on keypress
UIS.InputBegan:Connect(function(inp, gp)
    if gp then return end
    if inp.UserInputType ~= Enum.UserInputType.Keyboard then return end
    local fn = keybindMap[inp.KeyCode.Name]
    if fn then fn() end
end)

local function Toggle(label, key, onChange)
    local row = New("Frame", Scroll, {
        Size=UDim2.new(1,0,0,38), BackgroundColor3=T.Card,
        BackgroundTransparency=.28, BorderSizePixel=0, LayoutOrder=O(),
    })
    Corner(row, 7)
    -- label — narrowed to leave room for keybind chip
    New("TextLabel", row, {
        Size=UDim2.new(0,118,1,0), Position=UDim2.new(0,12,0,0),
        BackgroundTransparency=1, Text=label,
        Font=Enum.Font.Gotham, TextSize=11,
        TextColor3=T.Text, TextXAlignment=Enum.TextXAlignment.Left,
    })
    -- keybind chip (sits between label and toggle track)
    local listening = false
    local chip = New("TextButton", row, {
        Size=UDim2.new(0,38,0,20), Position=UDim2.new(1,-96,.5,-10),
        BackgroundColor3=T.Input, BorderSizePixel=0,
        Text="—", TextColor3=T.TextMuted,
        Font=Enum.Font.GothamBold, TextSize=10, ZIndex=5,
    })
    Corner(chip, 5); Stroke(chip, T.Border, 1)
    -- toggle track
    local track = New("Frame", row, {
        Size=UDim2.new(0,40,0,22), Position=UDim2.new(1,-50,.5,-11),
        BackgroundColor3=T.TrkOff, BorderSizePixel=0,
    })
    Corner(track, 11); Stroke(track, T.Border, 1, .4)
    local knob = New("Frame", track, {
        Size=UDim2.new(0,16,0,16), Position=UDim2.new(0,3,.5,-8),
        BackgroundColor3=T.KnobOff, BorderSizePixel=0,
    })
    Corner(knob, 8)
    -- invisible hit over the left 2/3 of the row (not over chip/track)
    local hit = New("TextButton", row, {
        Size=UDim2.new(1,-102,1,0), Position=UDim2.new(0,0,0,0),
        BackgroundTransparency=1, Text="", ZIndex=4,
    })
    local on = cfg[key] or false
    local function vis(s)
        tw(track, {BackgroundColor3=s and T.TrkOn or T.TrkOff}, .17)
        tw(knob,  {Position=s and UDim2.new(0,21,.5,-8) or UDim2.new(0,3,.5,-8)}, .17)
        tw(knob,  {BackgroundColor3=s and T.KnobOn or T.KnobOff}, .17)
    end
    vis(on)
    local function doToggle()
        on = not on; cfg[key] = on; vis(on)
        local reg = toggleRegistry[key]
        if reg and reg.dot then
            tw(reg.dot, {BackgroundColor3=on and T.Green or T.TextMuted}, .15)
        end
        if onChange then onChange(on) end
    end
    -- clicking the toggle track area also fires doToggle
    local trackHit = New("TextButton", row, {
        Size=UDim2.new(0,50,1,0), Position=UDim2.new(1,-52,0,0),
        BackgroundTransparency=1, Text="", ZIndex=5,
    })
    trackHit.MouseButton1Click:Connect(doToggle)
    hit.MouseButton1Click:Connect(doToggle)
    hit.MouseEnter:Connect(function() tw(row,{BackgroundTransparency=.1},.1) end)
    hit.MouseLeave:Connect(function() tw(row,{BackgroundTransparency=.28},.1) end)
    -- keybind chip logic
    chip.MouseEnter:Connect(function()
        if not listening then tw(chip,{BackgroundColor3=T.Card},.1) end end)
    chip.MouseLeave:Connect(function()
        if not listening then tw(chip,{BackgroundColor3=T.Input},.1) end end)
    chip.MouseButton1Click:Connect(function()
        if listening then return end
        listening = true
        chip.Text = "···"
        tw(chip,{BackgroundColor3=T.Card, TextColor3=T.AccentBright},.08)
        local c c = UIS.InputBegan:Connect(function(inp, _)
            if inp.UserInputType ~= Enum.UserInputType.Keyboard then return end
            local kname = inp.KeyCode.Name
            if inp.KeyCode == Enum.KeyCode.Escape then
                -- clear binding
                for k,v in pairs(keybindMap) do
                    if v == doToggle then keybindMap[k] = nil end
                end
                chip.Text = "—"
                tw(chip,{BackgroundColor3=T.Input, TextColor3=T.TextMuted},.12)
            else
                -- remove old entry for this toggle if any
                for k,v in pairs(keybindMap) do
                    if v == doToggle then keybindMap[k] = nil end
                end
                keybindMap[kname] = doToggle
                chip.Text = kname
                tw(chip,{BackgroundColor3=T.Input, TextColor3=T.AccentBright},.12)
            end
            listening = false
            c:Disconnect()
        end)
    end)
    toggleRegistry[key] = {fn=doToggle, dot=nil}
    return row
end

local function Input(label, default, onChange)
    local row = New("Frame", Scroll, {
        Size=UDim2.new(1,0,0,38), BackgroundColor3=T.Card,
        BackgroundTransparency=.28, BorderSizePixel=0, LayoutOrder=O(),
    })
    Corner(row, 7)
    New("TextLabel", row, {
        Size=UDim2.new(.58,0,1,0), Position=UDim2.new(0,12,0,0),
        BackgroundTransparency=1, Text=label,
        Font=Enum.Font.Gotham, TextSize=12,
        TextColor3=T.Text, TextXAlignment=Enum.TextXAlignment.Left,
    })
    local box = New("TextBox", row, {
        Size=UDim2.new(0,80,0,26), Position=UDim2.new(1,-88,.5,-13),
        BackgroundColor3=T.Input, BorderSizePixel=0,
        Text=tostring(default), TextColor3=T.AccentBright,
        Font=Enum.Font.GothamBold, TextSize=12,
        ClearTextOnFocus=false, ZIndex=4, MultiLine=false,
    })
    Corner(box, 6); Stroke(box, T.Border, 1)
    box.Focused:Connect(function() tw(box,{BackgroundColor3=T.Card},.12) end)
    box.FocusLost:Connect(function()
        tw(box,{BackgroundColor3=T.Input},.12)
        if onChange then onChange(box.Text) end
    end)
    return row, box
end

local function Keybind(label, defText, onChange)
    local row = New("Frame", Scroll, {
        Size=UDim2.new(1,0,0,38), BackgroundColor3=T.Card,
        BackgroundTransparency=.28, BorderSizePixel=0, LayoutOrder=O(),
    })
    Corner(row, 7)
    New("TextLabel", row, {
        Size=UDim2.new(.6,0,1,0), Position=UDim2.new(0,12,0,0),
        BackgroundTransparency=1, Text=label,
        Font=Enum.Font.Gotham, TextSize=12,
        TextColor3=T.Text, TextXAlignment=Enum.TextXAlignment.Left,
    })
    local listening = false
    local chip = New("TextButton", row, {
        Size=UDim2.new(0,52,0,25), Position=UDim2.new(1,-60,.5,-12),
        BackgroundColor3=T.Input, BorderSizePixel=0,
        Text=defText, TextColor3=T.TextSub,
        Font=Enum.Font.GothamBold, TextSize=11, ZIndex=5,
    })
    Corner(chip, 6); Stroke(chip, T.Border, 1)
    chip.MouseEnter:Connect(function() tw(chip,{BackgroundColor3=T.Card},.1) end)
    chip.MouseLeave:Connect(function()
        if not listening then tw(chip,{BackgroundColor3=T.Input},.1) end end)
    chip.MouseButton1Click:Connect(function()
        if listening then return end; listening = true
        chip.Text = "···"
        tw(chip, {BackgroundColor3=T.Card, TextColor3=T.AccentBright}, .08)
        local c c = UIS.InputBegan:Connect(function(inp, _)
            if inp.UserInputType ~= Enum.UserInputType.Keyboard then return end
            local name = inp.KeyCode == Enum.KeyCode.Escape
                and "—" or inp.KeyCode.Name
            chip.Text = name
            tw(chip, {BackgroundColor3=T.Input, TextColor3=T.TextSub}, .12)
            listening = false
            if onChange then onChange(inp.KeyCode) end
            c:Disconnect()
        end)
    end)
    return row, chip
end



Section("SPEED")
Input("Normal Speed", cfg.NormalSpeed, function(v)
    cfg.NormalSpeed = tonumber(v) or cfg.NormalSpeed end)
Input("Carry Speed", cfg.CarrySpeed, function(v)
    cfg.CarrySpeed = tonumber(v) or cfg.CarrySpeed end)
Keybind("Speed Key","Q",function(k) cfg.SpeedKey=k end)
Space(2); Rule(); Space(2)

Section("AUTO PLAY")
Toggle("Auto Play Left","AutoPlayLeft",function(on)
    aplOn = on
    if on then
        stopAutoPlayRight(); aprOn=false; startAutoPlayLeft()
    else stopAutoPlayLeft() end
end)
Toggle("Auto Play Right","AutoPlayRight",function(on)
    aprOn = on
    if on then
        stopAutoPlayLeft(); aplOn=false; startAutoPlayRight()
    else stopAutoPlayRight() end
end)
Toggle("Float Play L","FloatPlayL",function(on)
    if on then
        -- turn off right side first
        cfg.FloatPlayR = false
        local regR = toggleRegistry["FloatPlayR"]
        if regR and regR.fn then
            -- force visual off without re-calling onChange loop
            cfg.FloatPlayR = false
        end
        stopAutoPlayRight(); aprOn = false
        -- enable float
        cfg.Float = true
        startFloat()
        -- sync Float toggle visual
        local fReg = toggleRegistry["Float"]
        if fReg and fReg.fn then fReg.fn = fReg.fn end
        -- enable auto play left
        aplOn = true; cfg.AutoPlayLeft = true
        stopAutoPlayLeft(); startAutoPlayLeft()
        -- sync pill dots
        for _, k in ipairs({"Float","AutoPlayLeft"}) do
            local r = toggleRegistry[k]
            if r and r.dot then
                local TS2 = game:GetService("TweenService")
                TS2:Create(r.dot, TweenInfo.new(.15), {BackgroundColor3=T.Green}):Play()
            end
        end
    else
        -- turn off float and auto play left
        stopFloat(); cfg.Float = false
        stopAutoPlayLeft(); aplOn = false; cfg.AutoPlayLeft = false
        for _, k in ipairs({"Float","AutoPlayLeft"}) do
            local r = toggleRegistry[k]
            if r and r.dot then
                local TS2 = game:GetService("TweenService")
                TS2:Create(r.dot, TweenInfo.new(.15), {BackgroundColor3=T.TextMuted}):Play()
            end
        end
    end
end)
Toggle("Float Play R","FloatPlayR",function(on)
    if on then
        cfg.FloatPlayL = false
        stopAutoPlayLeft(); aplOn = false; cfg.AutoPlayLeft = false
        -- enable float
        cfg.Float = true
        startFloat()
        -- enable auto play right
        aprOn = true; cfg.AutoPlayRight = true
        stopAutoPlayRight(); startAutoPlayRight()
        for _, k in ipairs({"Float","AutoPlayRight"}) do
            local r = toggleRegistry[k]
            if r and r.dot then
                local TS2 = game:GetService("TweenService")
                TS2:Create(r.dot, TweenInfo.new(.15), {BackgroundColor3=T.Green}):Play()
            end
        end
    else
        stopFloat(); cfg.Float = false
        stopAutoPlayRight(); aprOn = false; cfg.AutoPlayRight = false
        for _, k in ipairs({"Float","AutoPlayRight"}) do
            local r = toggleRegistry[k]
            if r and r.dot then
                local TS2 = game:GetService("TweenService")
                TS2:Create(r.dot, TweenInfo.new(.15), {BackgroundColor3=T.TextMuted}):Play()
            end
        end
    end
end)
Space(2); Rule(); Space(2)

Section("MOVEMENT")
Toggle("Auto Left","AutoLeft",function(on)
    alEnabled = on
    if on then
        arEnabled=false; stopAutoRight(); startAutoLeft()
    else stopAutoLeft() end
end)
Toggle("Auto Right","AutoRight",function(on)
    arEnabled = on
    if on then
        alEnabled=false; stopAutoLeft(); startAutoRight()
    else stopAutoRight() end
end)
Toggle("Unwalk","Unwalk",function(on)
    if on then enableUnwalk() else disableUnwalk() end
end)
Space(2); Rule(); Space(2)

Section("TELEPORT  (ragdoll detect)")
Toggle("TP Left","AutoTpLeft",function(on)
    if on then cfg.AutoTpRight = false end
end)
Toggle("TP Right","AutoTpRight",function(on)
    if on then cfg.AutoTpLeft = false end
end)
Space(2); Rule(); Space(2)

Section("STEAL")
Toggle("Auto Steal","AutoSteal",function(on) stealActive = on end)
Input("Steal Radius", cfg.StealRadius, function(v)
    cfg.StealRadius = tonumber(v) or cfg.StealRadius end)
Space(2); Rule(); Space(2)

Section("COMBAT")
Toggle("Auto Bat","AutoBat",function(on)
    if on then showBatRing() else hideBatRing() end
end)
Toggle("Bat Aimbot","BatAimbot")
Input("Bat Radius", cfg.BatRadius, function(v)
    cfg.BatRadius = tonumber(v) or cfg.BatRadius end)
Toggle("Anti Ragdoll","AntiRagdoll",function(on)
    if on then enableAntiRagdoll() else disableAntiRagdoll() end
end)
Toggle("Hard Hit","HardHit",function(on)
    if not on then hideHHRing() end
end)
Input("Hard Hit Radius", cfg.HardHitRadius, function(v)
    cfg.HardHitRadius = tonumber(v) or cfg.HardHitRadius end)
Toggle("Spin Bot","SpinBot",function(on)
    if on then startSpin() else killSpin() end
end)
Input("Spin Speed", cfg.SpinSpeed, function(v)
    cfg.SpinSpeed = tonumber(v) or cfg.SpinSpeed end)
Space(2); Rule(); Space(2)

Section("FLOAT / DODGE")
Toggle("Float","Float",function(on)
    if on then startFloat() else stopFloat() end
end)
Input("Float Height", cfg.FloatHeight, function(v)
    cfg.FloatHeight = tonumber(v) or cfg.FloatHeight end)
Toggle("Dodge","Dodge",function(on)
    if on then startDodge() else stopDodge() end
end)
Input("Dodge Height", cfg.DodgeHeight, function(v)
    cfg.DodgeHeight = tonumber(v) or cfg.DodgeHeight end)
Space(2); Rule(); Space(2)

Section("MISC")
Toggle("Infinite Jump","InfiniteJump")
Toggle("Player ESP","PlayerESP",function(on)
    if on then enableESP() else disableESP() end
end)
Toggle("Optimizer + XRay","Optimizer",function(on)
    if on then enableOptimizer(); enableXray()
    else disableOptimizer(); disableXray() end
end)
Toggle("Low Gravity","LowGravity",function() applyLowGrav() end)
Input("Gravity %", cfg.GravityPercent, function(v)
    cfg.GravityPercent = tonumber(v) or cfg.GravityPercent end)
Toggle("Lock UI","LockUI",function(on)
    tw(Stripe,{BackgroundColor3=on and T.ErrRed or T.AccentSoft},.2)
end)
Toggle("Mobile Mode","MobileMode",function(on)
    setMobileMode(on)
end)
Space(8)


local wmShake  = 0
local wmBaseY  = 58

local WMGlow = New("Frame", Gui, {
    Name="WMGlow",
    Size=UDim2.new(0,216,0,50),
    Position=UDim2.new(0.5,-108,0,55),
    BackgroundTransparency=1,
    BorderSizePixel=0, ZIndex=19,
})
Corner(WMGlow, 25)
New("UIStroke", WMGlow, {
    Color=T.AccentMid, Thickness=1.5, Transparency=.18,
    ApplyStrokeMode=Enum.ApplyStrokeMode.Border,
})

local WM = New("Frame", Gui, {
    Name="Watermark",
    Size=UDim2.new(0,210,0,44),
    Position=UDim2.new(0.5,-105,0,wmBaseY),
    BackgroundColor3=Color3.fromRGB(8,6,18),
    BackgroundTransparency=.05,
    BorderSizePixel=0, ZIndex=20,
})
Corner(WM, 22)
New("UIStroke", WM, {
    Color=T.Accent, Thickness=1, Transparency=.3,
    ApplyStrokeMode=Enum.ApplyStrokeMode.Border,
})

New("TextLabel", WM, {
    Size=UDim2.new(1,-16,1,0), Position=UDim2.new(0,8,0,0),
    BackgroundTransparency=1,
    Text="❖ runji hub",
    Font=Enum.Font.GothamBlack, TextSize=20,
    TextColor3=Color3.fromRGB(235,228,255),
    TextXAlignment=Enum.TextXAlignment.Center,
    TextStrokeTransparency=.6,
    TextStrokeColor3=T.Accent,
    ZIndex=21,
})

local StealBarF = New("Frame", Gui, {
    Name="StealBar", Size=UDim2.new(0,392,0,68),
    Position=UDim2.new(0.5,-196,1,-144),
    BackgroundColor3=T.Surface, BackgroundTransparency=.06,
    BorderSizePixel=0, ZIndex=10, Active=true,
})
Corner(StealBarF, 12); Stroke(StealBarF, T.BorderHi, 1, .35)
do
    local d2,ds2,sp2=false,nil,nil
    StealBarF.InputBegan:Connect(function(i)
        if cfg.LockUI then return end
        if i.UserInputType==Enum.UserInputType.MouseButton1 then
            d2=true;ds2=i.Position;sp2=StealBarF.Position end
    end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then d2=false end
    end)
    UIS.InputChanged:Connect(function(i)
        if cfg.LockUI then d2=false; return end
        if not d2 then return end
        if i.UserInputType==Enum.UserInputType.MouseMovement then
            local dv=i.Position-ds2
            StealBarF.Position=UDim2.new(
                sp2.X.Scale,sp2.X.Offset+dv.X,
                sp2.Y.Scale,sp2.Y.Offset+dv.Y)
        end
    end)
end
local PctLabel = New("TextLabel", StealBarF, {
    Size=UDim2.new(0,44,0,18), Position=UDim2.new(0,12,0,8),
    BackgroundTransparency=1, Text="0%",
    Font=Enum.Font.GothamBold, TextSize=14,
    TextColor3=T.AccentBright, ZIndex=11,
})
New("TextLabel", StealBarF, {
    Size=UDim2.new(1,-80,0,18), Position=UDim2.new(0,60,0,8),
    BackgroundTransparency=1, Text="STEAL PROGRESS",
    Font=Enum.Font.GothamBold, TextSize=9,
    TextColor3=T.AccentBright,
    TextXAlignment=Enum.TextXAlignment.Left, ZIndex=11,
})
local BarTrack = New("Frame", StealBarF, {
    Size=UDim2.new(1,-24,0,9), Position=UDim2.new(0,12,0,32),
    BackgroundColor3=T.PrgBG, BorderSizePixel=0, ZIndex=11,
})
Corner(BarTrack, 5); Stroke(BarTrack, T.Border, 1, .6)
local BarFill = New("Frame", BarTrack, {
    Size=UDim2.new(0,0,1,0),
    BackgroundColor3=T.PrgFill, BorderSizePixel=0, ZIndex=12,
})
Corner(BarFill, 5)
New("TextLabel", StealBarF, {
    Size=UDim2.new(0,52,0,16), Position=UDim2.new(0,12,1,-20),
    BackgroundTransparency=1, Text="RADIUS",
    Font=Enum.Font.GothamBold, TextSize=9,
    TextColor3=T.TextMuted, ZIndex=11,
})
local RadBox = New("TextBox", StealBarF, {
    Size=UDim2.new(0,44,0,16), Position=UDim2.new(0,68,1,-20),
    BackgroundColor3=T.Input, BorderSizePixel=0,
    Text=tostring(cfg.StealRadius), TextColor3=T.AccentBright,
    Font=Enum.Font.GothamBold, TextSize=11,
    ClearTextOnFocus=false, ZIndex=12,
})
Corner(RadBox, 4); Stroke(RadBox, T.Border)
RadBox.FocusLost:Connect(function()
    cfg.StealRadius = tonumber(RadBox.Text) or cfg.StealRadius
    RadBox.Text = tostring(cfg.StealRadius)
end)

local function SetStealProgress(pct)
    pct = math.clamp(pct, 0, 1)
    tw(BarFill, {Size=UDim2.new(pct,0,1,0)}, .15)
    PctLabel.Text = math.floor(pct*100).."%"
end


-- Left column: movement / auto-play actions
local leftPillDefs = {
    {key="AutoLeft",      label="Auto Left"},
    {key="AutoRight",     label="Auto Right"},
    {key="AutoPlayLeft",  label="Auto Play L"},
    {key="AutoPlayRight", label="Auto Play R"},
    {key="AutoTpLeft",    label="TP Left"},
    {key="AutoTpRight",   label="TP Right"},
    {key="Unwalk",        label="Unwalk"},
}

-- Right column: combat / utility + a Menu pill to show/hide the main panel
local rightPillDefs = {
    {key="__MENU__",   label="Menu"},
    {key="AutoSteal",  label="Auto Steal"},
    {key="AutoBat",    label="Bat Aimbot"},
    {key="Float",      label="Float"},
    {key="Dodge",      label="Dodge"},
    {key="SpinBot",    label="Spin Bot"},
    {key="PlayerESP",  label="Player ESP"},
    {key="HardHit",    label="Hard Hit"},
}

local pillInstances = {}   -- flat list of {key, dot, pill}
local menuVisible   = true -- tracks main panel visibility in mobile mode

-- Pill containers — anchored to screen edges, stacked via UIListLayout
local LeftPillHolder = New("Frame", Gui, {
    Name       = "LeftPills",
    Size       = UDim2.new(0, 128, 1, -180),
    Position   = UDim2.new(0, 6, 0, 160),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ZIndex     = 40,
    Visible    = false,
    ClipsDescendants = false,
})
New("UIListLayout", LeftPillHolder, {
    SortOrder = Enum.SortOrder.LayoutOrder,
    Padding   = UDim.new(0, 5),
})

local RightPillHolder = New("Frame", Gui, {
    Name       = "RightPills",
    Size       = UDim2.new(0, 128, 1, -180),
    Position   = UDim2.new(1, -134, 0, 160),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ZIndex     = 40,
    Visible    = false,
    ClipsDescendants = false,
})
New("UIListLayout", RightPillHolder, {
    SortOrder = Enum.SortOrder.LayoutOrder,
    Padding   = UDim.new(0, 5),
})

-- Build a single pill inside a holder
local function makePill(holder, def, idx)
    local isOn = def.key == "__MENU__" and menuVisible or (cfg[def.key] or false)

    local pill = New("Frame", holder, {
        Name            = "Pill_" .. def.key,
        Size            = UDim2.new(1, 0, 0, 30),
        BackgroundColor3 = Color3.fromRGB(7, 5, 18),
        BackgroundTransparency = 0.08,
        BorderSizePixel = 0,
        LayoutOrder     = idx,
        ZIndex          = 41,
    })
    Corner(pill, 15)   -- full pill radius
    New("UIStroke", pill, {
        Color       = Color3.fromRGB(50, 42, 88),
        Thickness   = 1,
        Transparency = 0.1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    })

    -- status dot (green = on, dim = off)
    local dot = New("Frame", pill, {
        Size             = UDim2.new(0, 7, 0, 7),
        Position         = UDim2.new(0, 9, 0.5, -3.5),
        BackgroundColor3 = isOn and T.Green or T.TextMuted,
        BorderSizePixel  = 0,
        ZIndex           = 42,
    })
    Corner(dot, 4)

    -- label
    New("TextLabel", pill, {
        Size             = UDim2.new(1, -34, 1, 0),
        Position         = UDim2.new(0, 21, 0, 0),
        BackgroundTransparency = 1,
        Text             = def.label,
        Font             = Enum.Font.GothamBold,
        TextSize         = 11,
        TextColor3       = T.Text,
        TextXAlignment   = Enum.TextXAlignment.Left,
        ZIndex           = 42,
    })

    -- chevron arrow
    New("TextLabel", pill, {
        Size             = UDim2.new(0, 14, 1, 0),
        Position         = UDim2.new(1, -16, 0, 0),
        BackgroundTransparency = 1,
        Text             = "›",
        Font             = Enum.Font.GothamBold,
        TextSize         = 15,
        TextColor3       = T.TextMuted,
        TextXAlignment   = Enum.TextXAlignment.Center,
        ZIndex           = 42,
    })

    -- invisible hit button on top
    local hit = New("TextButton", pill, {
        Size                   = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text                   = "",
        ZIndex                 = 43,
    })

    local function updateDot(state)
        tw(dot, {BackgroundColor3 = state and T.Green or T.TextMuted}, .15)
    end

    hit.MouseButton1Click:Connect(function()
        -- brief press flash
        tw(pill, {BackgroundTransparency = 0}, .06)
        task.delay(.16, function() tw(pill, {BackgroundTransparency = .08}, .14) end)

        if def.key == "__MENU__" then
            menuVisible = not menuVisible
            Main.Visible = menuVisible
            updateDot(menuVisible)
            return
        end

        local reg = toggleRegistry[def.key]
        if reg and reg.fn then reg.fn() end
        updateDot(cfg[def.key] or false)
    end)

    hit.MouseEnter:Connect(function() tw(pill, {BackgroundTransparency = 0}, .08) end)
    hit.MouseLeave:Connect(function() tw(pill, {BackgroundTransparency = .08}, .08) end)

    -- register dot into toggleRegistry so main-panel toggles sync the pill dot
    if def.key ~= "__MENU__" then
        if not toggleRegistry[def.key] then
            toggleRegistry[def.key] = {fn=nil, dot=nil}
        end
        toggleRegistry[def.key].dot = dot
    end

    table.insert(pillInstances, {key = def.key, dot = dot, pill = pill})
    return pill
end

-- Build all pills (hidden until mobile mode activates)
for i, def in ipairs(leftPillDefs) do
    makePill(LeftPillHolder, def, i)
end
for i, def in ipairs(rightPillDefs) do
    makePill(RightPillHolder, def, i)
end


function setMobileMode(on)
    cfg.MobileMode = on
    if on then
        -- shrink main panel, inset slightly so all 4 corners stay rounded
        tw(Main, {
            Size     = UDim2.new(0, 220, 0, 420),
            Position = UDim2.new(1, -228, 0, 12),
        }, .3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

        -- shrink steal bar for mobile
        tw(StealBarF, {
            Size     = UDim2.new(0, 220, 0, 42),
            Position = UDim2.new(0.5, -110, 1, -56),
        }, .25)

        LeftPillHolder.Visible  = true
        RightPillHolder.Visible = true

        -- stagger pills in with a Back bounce
        for i, inst in ipairs(pillInstances) do
            inst.pill.Size = UDim2.new(1, 0, 0, 0)
            inst.pill.BackgroundTransparency = 1
            task.delay((i - 1) * 0.045, function()
                tw(inst.pill, {
                    Size                   = UDim2.new(1, 0, 0, 30),
                    BackgroundTransparency = 0.08,
                }, .32, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
            end)
        end
    else
        -- restore full panel size
        tw(Main, {
            Size     = UDim2.new(0, 340, 0, 628),
            Position = UDim2.new(1, -349, 0, 18),
        }, .25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

        -- restore steal bar
        tw(StealBarF, {
            Size     = UDim2.new(0, 392, 0, 68),
            Position = UDim2.new(0.5, -196, 1, -144),
        }, .25)

        Main.Visible = true
        menuVisible  = true

        -- stagger pills out
        local total = #pillInstances
        for i, inst in ipairs(pillInstances) do
            task.delay((total - i) * 0.03, function()
                tw(inst.pill, {
                    Size                   = UDim2.new(1, 0, 0, 0),
                    BackgroundTransparency = 1,
                }, .2, Enum.EasingStyle.Back, Enum.EasingDirection.In)
            end)
        end
        task.delay(total * 0.03 + 0.25, function()
            LeftPillHolder.Visible  = false
            RightPillHolder.Visible = false
        end)
    end
end


local SpeedLbl
local function AttachBB(char)
    local hrp = char:WaitForChild("HumanoidRootPart", 5)
    if not hrp then return end
    local old = hrp:FindFirstChild("22sSpeedBB")
    if old then old:Destroy() end
    local bb = New("BillboardGui", hrp, {
        Name="22sSpeedBB", Size=UDim2.new(0,130,0,26),
        StudsOffset=Vector3.new(0,4,0), AlwaysOnTop=true,
    })
    SpeedLbl = New("TextLabel", bb, {
        Size=UDim2.new(1,0,1,0), BackgroundTransparency=1,
        Text="Speed: 0", Font=Enum.Font.GothamBold, TextSize=13,
        TextColor3=T.AccentBright,
        TextStrokeTransparency=.4,
        TextStrokeColor3=Color3.new(0,0,0),
        TextXAlignment=Enum.TextXAlignment.Center,
    })
end
me.CharacterAdded:Connect(function(c) task.wait(.5); AttachBB(c) end)
if me.Character then AttachBB(me.Character) end


RS.Heartbeat:Connect(function(dt)
    bobTime = bobTime + dt
    if isDragging then return end
    local ox = math.sin(bobTime * 0.6)  * 2.2
    local oy = math.sin(bobTime * 1.15) * 4.0
    Main.Position = UDim2.new(
        Main.Position.X.Scale, homeX + ox,
        Main.Position.Y.Scale, homeY + oy)
end)


RS.Heartbeat:Connect(function(dt)
    wmShake = wmShake + dt
    local drift   = math.sin(wmShake * 0.9) * 5
    WM.Position   = UDim2.new(0.5,-105, 0, wmBaseY + drift)
    WMGlow.Position = UDim2.new(0.5,-108, 0, wmBaseY - 3 + drift)
end)

RS.RenderStepped:Connect(function(dt)
    FPSLbl.Text  = math.floor(1/dt).." FPS"
    PingLbl.Text = math.floor(me:GetNetworkPing()*1000).."ms"
end)

RS.Heartbeat:Connect(function()
    local char = me.Character; if not char then return end
    local hrp  = char:FindFirstChild("HumanoidRootPart"); if not hrp then return end
    if SpeedLbl then
        local v = hrp.AssemblyLinearVelocity
        SpeedLbl.Text = "Speed: "
            ..math.floor(Vector3.new(v.X,0,v.Z).Magnitude)
    end
    if cfg.AntiRagdoll then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum and hum:GetState()==Enum.HumanoidStateType.Physics then
            pcall(function()
                hum:ChangeState(Enum.HumanoidStateType.Running) end)
        end
    end
end)

print("[runji hub] Loaded ✦")
