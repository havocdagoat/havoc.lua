--[[
    K7 Mini Hub - Complete final version
    - Progress bar attached below main panel
    - Drop button integrated
    - Working waypoint offsets (negative allowed)
    - Countdown detection
    - Full mutual exclusion on auto modes
]]

local Players      = game:GetService("Players")
local RunService   = game:GetService("RunService")
local UIS          = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Lighting     = game:GetService("Lighting")

local me   = Players.LocalPlayer
local pgui = me:WaitForChild("PlayerGui")

local vHum, vRoot
local function bindChar(char)
    vHum  = char:WaitForChild("Humanoid")
    vRoot = char:WaitForChild("HumanoidRootPart")
end
if me.Character then bindChar(me.Character) end
me.CharacterAdded:Connect(bindChar)

local function getHRP() local c=me.Character; return c and c:FindFirstChild("HumanoidRootPart") end
local function getHum() local c=me.Character; return c and c:FindFirstChildOfClass("Humanoid") end

-- ── WAYPOINTS ──────────────────────────────
local WPRight = {
    {label="R1", pos=Vector3.new(-475.37,-7,26.63),   color=Color3.new(0.313726,0.705882,1),   offset=Vector3.new(0,0,0)},
    {label="R2", pos=Vector3.new(-486.76,-3.65,17.55), color=Color3.new(0.392157,1,0.470588),   offset=Vector3.new(0,0,0)},
    {label="R3", pos=Vector3.new(-475.57,-5.62,31.04), color=Color3.new(1,0.862745,0.196078),   offset=Vector3.new(0,0,0)},
    {label="R4", pos=Vector3.new(-476.09,-6.56,97.06), color=Color3.new(1,0.313726,0.627451),   offset=Vector3.new(0,0,0)},
}
local WPLeft = {
    {label="L1", pos=Vector3.new(-476.48,-6.28,92.73), color=Color3.new(0.313726,0.705882,1),   offset=Vector3.new(0,0,0)},
    {label="L2", pos=Vector3.new(-483.12,-4.95,94.80), color=Color3.new(0.392157,1,0.470588),   offset=Vector3.new(0,0,0)},
    {label="L3", pos=Vector3.new(-473.38,-8.40,22.34), color=Color3.new(1,0.862745,0.196078),   offset=Vector3.new(0,0,0)},
    {label="L4", pos=Vector3.new(-483.12,-4.95,94.80), color=Color3.new(1,0.313726,0.627451),   offset=Vector3.new(0,0,0)},
}

local function wpPos(wp) return wp.pos + wp.offset end
local function getL1()     return wpPos(WPLeft[1])  end
local function getLEND()   return wpPos(WPLeft[2])  end
local function getLFINAL() return wpPos(WPLeft[3])  end
local function getR1()     return wpPos(WPRight[1]) end
local function getREND()   return wpPos(WPRight[2]) end
local function getRFINAL() return wpPos(WPRight[4]) end

local FSPD = 59; local RSPD = 30
local TPA  = Vector3.new(-472.60,-7.00,57.52)
local TPRB = Vector3.new(-471.76,-7.00,26.22)
local TPR1 = Vector3.new(-483.51,-5.10,18.89)

-- ── STATE ──────────────────────────────────
local S = {
    Speed=false,Float=false,AutoPlayTP=false,DropBrainrot=false,
    TPDown=false,AutoSteal=false,AutoLeft=false,AutoRight=false,
    AutoPlayLeft=false,AutoPlayRight=false,AutoPlayCD=false,
    BatAimbot=false,AutoSwing=false,AntiRagdoll=false,
    MedusaCounter=false,Unwalk=false,InfJump=false,
    NoCamCol=false,ShinyGraphics=false,Optimizer=false,RemoveAccs=false
}
local lastAutoPlayMode = "Left"
local btnRefreshFns    = {}

-- ── SPEED ──────────────────────────────────
RunService.Heartbeat:Connect(function()
    if not S.Speed or not vHum or not vRoot then return end
    local md = vHum.MoveDirection
    if md.Magnitude > 0 then
        vRoot.AssemblyLinearVelocity = Vector3.new(md.X*60, vRoot.AssemblyLinearVelocity.Y, md.Z*60)
    end
end)

-- ── FLOAT ──────────────────────────────────
local floatConn
local function startFloat()
    if floatConn then floatConn:Disconnect() end
    local h = getHRP()
    if h then
        h.CFrame = CFrame.new(h.Position.X, h.Position.Y+8, h.Position.Z)
        h.AssemblyLinearVelocity = Vector3.new(h.AssemblyLinearVelocity.X,0,h.AssemblyLinearVelocity.Z)
    end
    floatConn = RunService.Heartbeat:Connect(function()
        if not S.Float then floatConn:Disconnect(); floatConn=nil; return end
        local h2 = getHRP(); if not h2 then return end
        h2.AssemblyLinearVelocity = Vector3.new(h2.AssemblyLinearVelocity.X,0,h2.AssemblyLinearVelocity.Z)
    end)
end
local function stopFloat() if floatConn then floatConn:Disconnect(); floatConn=nil end end

-- ── INF JUMP ───────────────────────────────
UIS.JumpRequest:Connect(function()
    if not S.InfJump then return end
    local h = getHRP(); if not h then return end
    h.AssemblyLinearVelocity = Vector3.new(h.AssemblyLinearVelocity.X,50,h.AssemblyLinearVelocity.Z)
end)
RunService.Heartbeat:Connect(function()
    if not S.InfJump then return end
    local h = getHRP(); if not h then return end
    if h.AssemblyLinearVelocity.Y < -80 then
        h.AssemblyLinearVelocity = Vector3.new(h.AssemblyLinearVelocity.X,-80,h.AssemblyLinearVelocity.Z)
    end
end)

-- ── UNWALK ─────────────────────────────────
local unwalkConn
local function enableUnwalk()
    local c = me.Character; if not c then return end
    local hum = c:FindFirstChildOfClass("Humanoid"); if not hum then return end
    local anim = hum:FindFirstChildOfClass("Animator"); if not anim then return end
    for _,t in ipairs(anim:GetPlayingAnimationTracks()) do t:Stop(0) end
    if unwalkConn then unwalkConn:Disconnect() end
    unwalkConn = RunService.Heartbeat:Connect(function()
        if not S.Unwalk then unwalkConn:Disconnect(); unwalkConn=nil; return end
        local c2 = me.Character; if not c2 then return end
        local h2 = c2:FindFirstChildOfClass("Humanoid"); if not h2 then return end
        local a2 = h2:FindFirstChildOfClass("Animator"); if not a2 then return end
        for _,t in ipairs(a2:GetPlayingAnimationTracks()) do t:Stop(0) end
    end)
end
local function disableUnwalk() if unwalkConn then unwalkConn:Disconnect(); unwalkConn=nil end end

-- ── ANTI RAGDOLL ───────────────────────────
local ragConns = {}; local lastVel = Vector3.new()
local function ragClean()
    local c = me.Character; if not c then return end
    for _,v in pairs(c:GetDescendants()) do
        if v:IsA("BallSocketConstraint") or v:IsA("HingeConstraint") or v:IsA("NoCollisionConstraint") then
            pcall(function() v:Destroy() end)
        elseif v:IsA("Motor6D") then v.Enabled = true end
    end
end
local function enableAntiRagdoll()
    local c = me.Character or me.CharacterAdded:Wait()
    local hum = c:WaitForChild("Humanoid")
    table.insert(ragConns, hum.StateChanged:Connect(function()
        pcall(function() hum:ChangeState(Enum.HumanoidStateType.Running) end); ragClean()
    end))
    table.insert(ragConns, RunService.Heartbeat:Connect(function()
        if not S.AntiRagdoll then return end
        local c2 = me.Character; if not c2 then return end
        local hrp = c2:FindFirstChild("HumanoidRootPart"); if not hrp then return end
        local vel = hrp.AssemblyLinearVelocity
        if (vel-lastVel).Magnitude > 40 and vel.Magnitude > 25 then hrp.AssemblyLinearVelocity = vel.Unit*15 end
        lastVel = vel; ragClean()
    end))
end
local function disableAntiRagdoll()
    for _,c in pairs(ragConns) do pcall(function() c:Disconnect() end) end; ragConns={}
end
me.CharacterAdded:Connect(function()
    if S.AntiRagdoll then task.wait(0.5); disableAntiRagdoll(); enableAntiRagdoll() end
end)

-- ── BAT ────────────────────────────────────
local batCD = false
local function getBat()
    local c = me.Character; if not c then return end
    for _,t in ipairs(c:GetChildren()) do
        if t:IsA("Tool") and t.Name:lower():find("bat") then return t end
    end
    local bp = me:FindFirstChild("Backpack")
    if bp then
        for _,t in ipairs(bp:GetChildren()) do
            if t:IsA("Tool") and t.Name:lower():find("bat") then t.Parent=c; return t end
        end
    end
end
local function hitBat()
    if batCD then return end; batCD=true
    local bat = getBat()
    if bat then pcall(function() bat:Activate(); local e=bat:FindFirstChildWhichIsA("RemoteEvent"); if e then e:FireServer() end end) end
    task.delay(0.08, function() batCD=false end)
end
local function closestEnemy()
    local hrp = getHRP(); if not hrp then return nil,math.huge end
    local best,bestD = nil,math.huge
    for _,p in ipairs(Players:GetPlayers()) do
        if p~=me and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            local d=(hrp.Position-p.Character.HumanoidRootPart.Position).Magnitude
            if d<bestD then bestD=d; best=p end
        end
    end
    return best,bestD
end
local function flyToFront(tHRP)
    local hrp=getHRP(); if not hrp then return end
    local front=tHRP.Position+tHRP.CFrame.LookVector*1.5
    local dir=Vector3.new(front.X-hrp.Position.X,0,front.Z-hrp.Position.Z)
    if dir.Magnitude<0.1 then return end
    hrp.AssemblyLinearVelocity=Vector3.new(dir.Unit.X*56.5,hrp.AssemblyLinearVelocity.Y,dir.Unit.Z*56.5)
end
if not _G.K7BatLoop then _G.K7BatLoop=true
    RunService.Heartbeat:Connect(function()
        if not S.BatAimbot and not S.AutoSwing then return end
        local hrp=getHRP(); if not hrp then return end
        local target,dist=closestEnemy()
        if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
            if S.BatAimbot then flyToFront(target.Character.HumanoidRootPart) end
            if S.AutoSwing and dist<=5 then hitBat() end
        end
    end)
end

-- ── DROP BRAINROT ──────────────────────────
local function doDrop()
    local hrp = getHRP(); if not hrp then return end
    hrp.AssemblyLinearVelocity = Vector3.new(0, 125, 0)
    task.wait(0.4)
    hrp.AssemblyLinearVelocity = Vector3.new(0, -600, 0)
end

-- ── AUTO MOVEMENT ──────────────────────────
local alConn,arConn,aplConn,aprConn
local aplOn,aprOn = false,false

local function stopAutoLeft()
    if alConn then alConn:Disconnect(); alConn=nil end
    S.AutoLeft=false
    local h=getHum(); if h then h:Move(Vector3.zero,false) end
    if btnRefreshFns["AutoLeft"] then btnRefreshFns["AutoLeft"](false) end
end
local function stopAutoRight()
    if arConn then arConn:Disconnect(); arConn=nil end
    S.AutoRight=false
    local h=getHum(); if h then h:Move(Vector3.zero,false) end
    if btnRefreshFns["AutoRight"] then btnRefreshFns["AutoRight"](false) end
end
local function stopAutoPlayLeft()
    if aplConn then aplConn:Disconnect(); aplConn=nil end
    aplOn=false; S.AutoPlayLeft=false
    local h=getHum(); if h then h:Move(Vector3.zero,false) end
    if btnRefreshFns["AutoPlayLeft"] then btnRefreshFns["AutoPlayLeft"](false) end
end
local function stopAutoPlayRight()
    if aprConn then aprConn:Disconnect(); aprConn=nil end
    aprOn=false; S.AutoPlayRight=false
    local h=getHum(); if h then h:Move(Vector3.zero,false) end
    if btnRefreshFns["AutoPlayRight"] then btnRefreshFns["AutoPlayRight"](false) end
end

local function startAutoLeft()
    stopAutoRight(); stopAutoPlayLeft(); stopAutoPlayRight()
    if alConn then alConn:Disconnect() end
    local phase=1
    alConn=RunService.Heartbeat:Connect(function()
        if not S.AutoLeft then return end
        local h,hum=getHRP(),getHum(); if not h or not hum then return end
        local t = phase==1 and getL1() or getLEND()
        local d=Vector3.new(t.X-h.Position.X,0,t.Z-h.Position.Z)
        if d.Magnitude<1 then
            if phase==1 then phase=2
            else hum:Move(Vector3.zero,false); h.AssemblyLinearVelocity=Vector3.new(0,0,0); stopAutoLeft() end
            return
        end
        local md=d.Unit; hum:Move(md,false)
        h.AssemblyLinearVelocity=Vector3.new(md.X*FSPD,h.AssemblyLinearVelocity.Y,md.Z*FSPD)
    end)
end

local function startAutoRight()
    stopAutoLeft(); stopAutoPlayLeft(); stopAutoPlayRight()
    if arConn then arConn:Disconnect() end
    local phase=1
    arConn=RunService.Heartbeat:Connect(function()
        if not S.AutoRight then return end
        local h,hum=getHRP(),getHum(); if not h or not hum then return end
        local t = phase==1 and getR1() or getREND()
        local d=Vector3.new(t.X-h.Position.X,0,t.Z-h.Position.Z)
        if d.Magnitude<1 then
            if phase==1 then phase=2
            else hum:Move(Vector3.zero,false); h.AssemblyLinearVelocity=Vector3.new(0,0,0); stopAutoRight() end
            return
        end
        local md=d.Unit; hum:Move(md,false)
        h.AssemblyLinearVelocity=Vector3.new(md.X*FSPD,h.AssemblyLinearVelocity.Y,md.Z*FSPD)
    end)
end

local function startAutoPlayLeft()
    stopAutoLeft(); stopAutoRight(); stopAutoPlayRight()
    lastAutoPlayMode="Left"
    if aplConn then aplConn:Disconnect() end
    local phase=1
    aplConn=RunService.Heartbeat:Connect(function()
        if not aplOn then return end
        local h,hum=getHRP(),getHum(); if not h or not hum then return end
        if phase==1 then
            local t=getL1(); local d=Vector3.new(t.X-h.Position.X,0,t.Z-h.Position.Z)
            if d.Magnitude<1 then phase=2; return end
            local md=d.Unit; hum:Move(md,false); h.AssemblyLinearVelocity=Vector3.new(md.X*FSPD,h.AssemblyLinearVelocity.Y,md.Z*FSPD)
        elseif phase==2 then
            local t=getLEND(); local d=Vector3.new(t.X-h.Position.X,0,t.Z-h.Position.Z)
            if d.Magnitude<1 then phase=0; hum:Move(Vector3.zero,false); h.AssemblyLinearVelocity=Vector3.new(0,0,0); task.delay(0.1,function() if aplOn then phase=3 end end); return end
            local md=d.Unit; hum:Move(md,false); h.AssemblyLinearVelocity=Vector3.new(md.X*FSPD,h.AssemblyLinearVelocity.Y,md.Z*FSPD)
        elseif phase==0 then return
        elseif phase==3 then
            local t=getL1(); local d=Vector3.new(t.X-h.Position.X,0,t.Z-h.Position.Z)
            if d.Magnitude<1 then phase=4; return end
            local md=d.Unit; hum:Move(md,false); h.AssemblyLinearVelocity=Vector3.new(md.X*RSPD,h.AssemblyLinearVelocity.Y,md.Z*RSPD)
        elseif phase==4 then
            local t=getLFINAL(); local d=Vector3.new(t.X-h.Position.X,0,t.Z-h.Position.Z)
            if d.Magnitude<1 then hum:Move(Vector3.zero,false); h.AssemblyLinearVelocity=Vector3.new(0,0,0); stopAutoPlayLeft(); return end
            local md=d.Unit; hum:Move(md,false); h.AssemblyLinearVelocity=Vector3.new(md.X*RSPD,h.AssemblyLinearVelocity.Y,md.Z*RSPD)
        end
    end)
end

local function startAutoPlayRight()
    stopAutoLeft(); stopAutoRight(); stopAutoPlayLeft()
    lastAutoPlayMode="Right"
    if aprConn then aprConn:Disconnect() end
    local phase=1
    aprConn=RunService.Heartbeat:Connect(function()
        if not aprOn then return end
        local h,hum=getHRP(),getHum(); if not h or not hum then return end
        if phase==1 then
            local t=getR1(); local d=Vector3.new(t.X-h.Position.X,0,t.Z-h.Position.Z)
            if d.Magnitude<1 then phase=2; return end
            local md=d.Unit; hum:Move(md,false); h.AssemblyLinearVelocity=Vector3.new(md.X*FSPD,h.AssemblyLinearVelocity.Y,md.Z*FSPD)
        elseif phase==2 then
            local t=getREND(); local d=Vector3.new(t.X-h.Position.X,0,t.Z-h.Position.Z)
            if d.Magnitude<1 then phase=0; hum:Move(Vector3.zero,false); h.AssemblyLinearVelocity=Vector3.new(0,0,0); task.delay(0.1,function() if aprOn then phase=3 end end); return end
            local md=d.Unit; hum:Move(md,false); h.AssemblyLinearVelocity=Vector3.new(md.X*FSPD,h.AssemblyLinearVelocity.Y,md.Z*FSPD)
        elseif phase==0 then return
        elseif phase==3 then
            local t=getR1(); local d=Vector3.new(t.X-h.Position.X,0,t.Z-h.Position.Z)
            if d.Magnitude<1 then phase=4; return end
            local md=d.Unit; hum:Move(md,false); h.AssemblyLinearVelocity=Vector3.new(md.X*RSPD,h.AssemblyLinearVelocity.Y,md.Z*RSPD)
        elseif phase==4 then
            local t=getRFINAL(); local d=Vector3.new(t.X-h.Position.X,0,t.Z-h.Position.Z)
            if d.Magnitude<1 then hum:Move(Vector3.zero,false); h.AssemblyLinearVelocity=Vector3.new(0,0,0); stopAutoPlayRight(); return end
            local md=d.Unit; hum:Move(md,false); h.AssemblyLinearVelocity=Vector3.new(md.X*RSPD,h.AssemblyLinearVelocity.Y,md.Z*RSPD)
        end
    end)
end

-- ── COUNTDOWN ──────────────────────────────
local cdWatching=false; local cdLastNum=-1; local cdConn
local function scanForCountdown()
    local best=-1
    for _,gui in ipairs(pgui:GetChildren()) do
        if gui:IsA("ScreenGui") and gui.Name~="K7MiniHub" then
            for _,desc in ipairs(gui:GetDescendants()) do
                if desc:IsA("TextLabel") and desc.Visible then
                    local n=tonumber(desc.Text)
                    if n and n==math.floor(n) and n>=1 and n<=15 then
                        local abs=desc.AbsoluteSize
                        if abs.X>40 and abs.Y>30 and n>best then best=n end
                    end
                end
            end
        end
    end
    return best
end
local function beginCountdownWatch()
    if cdWatching then return end
    cdWatching=true; cdLastNum=-1
    if cdConn then cdConn:Disconnect() end
    cdConn=RunService.Heartbeat:Connect(function()
        if not S.AutoPlayCD then cdWatching=false; cdConn:Disconnect(); cdConn=nil; return end
        local n=scanForCountdown()
        if n>=1 then cdLastNum=n
        elseif cdLastNum>=1 then
            cdLastNum=-1; cdWatching=false; cdConn:Disconnect(); cdConn=nil
            task.wait(0.05)
            if lastAutoPlayMode=="Left" and not S.AutoPlayLeft then
                aplOn=true; S.AutoPlayLeft=true
                if btnRefreshFns["AutoPlayLeft"] then btnRefreshFns["AutoPlayLeft"](true) end
                startAutoPlayLeft()
            elseif lastAutoPlayMode=="Right" and not S.AutoPlayRight then
                aprOn=true; S.AutoPlayRight=true
                if btnRefreshFns["AutoPlayRight"] then btnRefreshFns["AutoPlayRight"](true) end
                startAutoPlayRight()
            end
        end
    end)
end
RunService.Heartbeat:Connect(function()
    if S.AutoPlayCD and not cdWatching and scanForCountdown()>=1 then beginCountdownWatch() end
end)

-- ── AUTO STEAL ─────────────────────────────
local stealConn,animalCache,promptCache,stealCache,isStealing=nil,{},{},{},false
local STEAL_R=7
local AnimalsData={}
pcall(function() local d=game:GetService("ReplicatedStorage"):FindFirstChild("Datas"); if d then local a=d:FindFirstChild("Animals"); if a then AnimalsData=require(a) end end end)
local function stealHRP() local c=me.Character; if not c then return nil end; return c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("UpperTorso") end
local function isMyBase(n) local p=workspace:FindFirstChild("Plots"); if not p then return false end; local pl=p:FindFirstChild(n); if not pl then return false end; local s=pl:FindFirstChild("PlotSign"); if not s then return false end; local y=s:FindFirstChild("YourBase"); return y and y:IsA("BillboardGui") and y.Enabled end
local function scanPlot(plot)
    if not plot or not plot:IsA("Model") then return end; if isMyBase(plot.Name) then return end
    local pods=plot:FindFirstChild("AnimalPodiums"); if not pods then return end
    for _,pod in ipairs(pods:GetChildren()) do
        if pod:IsA("Model") and pod:FindFirstChild("Base") then
            local name="Unknown"; local sp=pod.Base:FindFirstChild("Spawn")
            if sp then for _,ch in ipairs(sp:GetChildren()) do if ch:IsA("Model") and ch.Name~="PromptAttachment" then name=ch.Name; local i=AnimalsData[name]; if i and i.DisplayName then name=i.DisplayName end; break end end end
            table.insert(animalCache,{name=name,plot=plot.Name,slot=pod.Name,worldPosition=pod:GetPivot().Position,uid=plot.Name.."_"..pod.Name})
        end
    end
end
local function findPrompt(ad)
    if not ad then return nil end; local cp=promptCache[ad.uid]; if cp and cp.Parent then return cp end
    local plots=workspace:FindFirstChild("Plots"); if not plots then return nil end; local plot=plots:FindFirstChild(ad.plot); if not plot then return nil end
    local pods=plot:FindFirstChild("AnimalPodiums"); if not pods then return nil end; local pod=pods:FindFirstChild(ad.slot); if not pod then return nil end
    local base=pod:FindFirstChild("Base"); if not base then return nil end; local sp=base:FindFirstChild("Spawn"); if not sp then return nil end
    local att=sp:FindFirstChild("PromptAttachment"); if not att then return nil end
    for _,p in ipairs(att:GetChildren()) do if p:IsA("ProximityPrompt") then promptCache[ad.uid]=p; return p end end
end
local function buildCallbacks(prompt)
    if stealCache[prompt] then return end; local data={holdCallbacks={},triggerCallbacks={},ready=true}
    local ok1,c1=pcall(getconnections,prompt.PromptButtonHoldBegan); if ok1 and type(c1)=="table" then for _,conn in ipairs(c1) do if type(conn.Function)=="function" then table.insert(data.holdCallbacks,conn.Function) end end end
    local ok2,c2=pcall(getconnections,prompt.Triggered); if ok2 and type(c2)=="table" then for _,conn in ipairs(c2) do if type(conn.Function)=="function" then table.insert(data.triggerCallbacks,conn.Function) end end end
    if #data.holdCallbacks>0 or #data.triggerCallbacks>0 then stealCache[prompt]=data end
end
local function execSteal(prompt)
    local data=stealCache[prompt]; if not data or not data.ready then return end; data.ready=false; isStealing=true
    task.spawn(function() for _,fn in ipairs(data.holdCallbacks) do task.spawn(fn) end; task.wait(0.2); for _,fn in ipairs(data.triggerCallbacks) do task.spawn(fn) end; task.wait(0.01); data.ready=true; task.wait(0.01); isStealing=false end)
end
local function nearestAnimal()
    local hrp=stealHRP(); if not hrp then return nil end; local best,bestD=nil,math.huge
    for _,ad in ipairs(animalCache) do if not isMyBase(ad.plot) and ad.worldPosition then local d=(hrp.Position-ad.worldPosition).Magnitude; if d<bestD then bestD=d; best=ad end end end
    return best
end
local function startStealLoop()
    if stealConn then stealConn:Disconnect() end
    stealConn=RunService.Heartbeat:Connect(function()
        if not S.AutoSteal or isStealing then return end
        local target=nearestAnimal(); if not target then return end
        local hrp=stealHRP(); if not hrp then return end
        if (hrp.Position-target.worldPosition).Magnitude>STEAL_R then return end
        local prompt=promptCache[target.uid]; if not prompt or not prompt.Parent then prompt=findPrompt(target) end
        if prompt then buildCallbacks(prompt); execSteal(prompt) end
    end)
end
task.spawn(function()
    task.wait(2); local plots=workspace:WaitForChild("Plots",10); if not plots then return end
    for _,plot in ipairs(plots:GetChildren()) do if plot:IsA("Model") then scanPlot(plot) end end
    plots.ChildAdded:Connect(function(plot) if plot:IsA("Model") then task.wait(0.5); scanPlot(plot) end end)
    task.spawn(function() while task.wait(5) do animalCache={}; for _,plot in ipairs(plots:GetChildren()) do if plot:IsA("Model") then scanPlot(plot) end end end end)
end)
startStealLoop()

-- ── TELEPORT ───────────────────────────────
local function tpTo(pos) local c=me.Character; if not c then return end; c:PivotTo(CFrame.new(pos)); local h=c:FindFirstChild("HumanoidRootPart"); if h then h.AssemblyLinearVelocity=Vector3.new(0,0,0) end end
local function doTPRight() tpTo(TPA); task.wait(0.1); tpTo(TPRB); task.wait(0.1); tpTo(TPR1) end
local function doTPDown() local h=getHRP(); if h then h.CFrame=h.CFrame*CFrame.new(0,-20,0) end end
local function doDropBrainrot() local h=getHRP(); if h then h.CFrame=h.CFrame*CFrame.new(0,-50,0) end end

-- ── OPTIMIZER / SHINY ──────────────────────
local function enableOptimizer()
    pcall(function() settings().Rendering.QualityLevel=Enum.QualityLevel.Level01; Lighting.GlobalShadows=false; Lighting.Brightness=2; Lighting.FogEnd=9e9; Lighting.FogStart=9e9; for _,fx in ipairs(Lighting:GetChildren()) do if fx:IsA("PostEffect") then fx.Enabled=false end end end)
    pcall(function() for _,obj in ipairs(workspace:GetDescendants()) do pcall(function() if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") or obj:IsA("Smoke") or obj:IsA("Fire") or obj:IsA("Sparkles") then obj.Enabled=false; obj:Destroy() elseif obj:IsA("BasePart") then obj.CastShadow=false; obj.Material=Enum.Material.Plastic; for _,child in ipairs(obj:GetChildren()) do if child:IsA("Decal") or child:IsA("Texture") or child:IsA("SurfaceAppearance") then child:Destroy() end end elseif obj:IsA("Sky") then obj:Destroy() end end) end end)
end
local function disableOptimizer() pcall(function() settings().Rendering.QualityLevel=Enum.QualityLevel.Automatic; Lighting.GlobalShadows=true; Lighting.FogEnd=100000; Lighting.FogStart=0 end) end
local function applyShiny() for _,v in ipairs(workspace:GetDescendants()) do if v:IsA("BasePart") then v.Material=Enum.Material.SmoothPlastic; v.Reflectance=0.25 end end end

RunService.Heartbeat:Connect(function()
    if not S.MedusaCounter then return end
    local c=me.Character; if not c then return end
    local hum=c:FindFirstChildOfClass("Humanoid"); if not hum then return end
    if hum:GetState()==Enum.HumanoidStateType.Physics then pcall(function() hum:ChangeState(Enum.HumanoidStateType.Running) end) end
end)

-- ── SPEED BILLBOARD ────────────────────────
local speedBB
local function makeSpeedBB()
    local c=me.Character; if not c then return end
    local hrp=c:FindFirstChild("HumanoidRootPart"); if not hrp then return end
    if speedBB then speedBB:Destroy() end
    speedBB=Instance.new("BillboardGui"); speedBB.Name="K7SpeedBB"; speedBB.Adornee=hrp; speedBB.Size=UDim2.new(0,110,0,22); speedBB.StudsOffset=Vector3.new(0,3,0); speedBB.AlwaysOnTop=true; speedBB.Parent=hrp
    local lbl=Instance.new("TextLabel"); lbl.Name="SpeedLbl"; lbl.Size=UDim2.new(1,0,1,0); lbl.BackgroundTransparency=1; lbl.TextColor3=Color3.new(1,1,1); lbl.TextStrokeColor3=Color3.new(0,0,0); lbl.TextStrokeTransparency=0; lbl.Font=Enum.Font.GothamBold; lbl.TextScaled=true; lbl.Text="Speed: 0"; lbl.Parent=speedBB
end
me.CharacterAdded:Connect(function() task.wait(0.5); makeSpeedBB() end)
if me.Character then makeSpeedBB() end
RunService.Heartbeat:Connect(function()
    local c=me.Character; if not c then return end
    local hrp=c:FindFirstChild("HumanoidRootPart"); if not hrp then return end
    if not speedBB or not speedBB.Parent then makeSpeedBB() end
    local lbl=speedBB and speedBB:FindFirstChild("SpeedLbl"); if not lbl then return end
    local vel=hrp.AssemblyLinearVelocity; lbl.Text="Speed: "..math.floor(Vector3.new(vel.X,0,vel.Z).Magnitude)
end)

-- ══════════════════════════════════════════
-- COLORS & HELPERS
-- ══════════════════════════════════════════
local C={
    BG=Color3.new(0.0392157,0.0392157,0.0470588), TitleBG=Color3.new(0.0705882,0.0196078,0.0313726),
    Accent=Color3.new(0.823529,0.117647,0.196078), AccText=Color3.new(1,0.235294,0.313726),
    Panel=Color3.new(0.0862745,0.0862745,0.101961), PanelSt=Color3.new(0.235294,0.0392157,0.0627451),
    SubText=Color3.new(0.470588,0.470588,0.509804), White=Color3.new(0.941176,0.941176,0.941176),
    KeyBG=Color3.new(0.156863,0.0313726,0.0470588), GearBG=Color3.new(0.0784314,0.0784314,0.109804),
    GearBlue=Color3.new(0.313726,0.705882,1), SW_Off=Color3.new(0.156863,0.156863,0.188235),
    SW_Knob=Color3.new(0.470588,0.470588,0.509804),
}
local function mkC(p,r) local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,r or 6); c.Parent=p end
local function mkS(p,col,th,tr) local s=Instance.new("UIStroke"); s.Color=col or C.Accent; s.Thickness=th or 1.5; s.Transparency=tr or 0.4; s.Parent=p end

-- ══════════════════════════════════════════
-- SCREEN GUI
-- ══════════════════════════════════════════
if pgui:FindFirstChild("K7MiniHub") then pgui.K7MiniHub:Destroy() end
local ScreenGui=Instance.new("ScreenGui"); ScreenGui.Name="K7MiniHub"; ScreenGui.ResetOnSpawn=false; ScreenGui.DisplayOrder=10; ScreenGui.Parent=pgui

-- ── MAIN PANEL ─────────────────────────────
local Main=Instance.new("Frame"); Main.Name="K7Main"; Main.Size=UDim2.new(0,225,0,500); Main.Position=UDim2.new(0,16,0,80); Main.BackgroundColor3=C.BG; Main.BorderSizePixel=0; Main.ZIndex=201; Main.Parent=ScreenGui; mkC(Main,10); mkS(Main,C.Accent,1.5,0.3)

-- Title bar
local TBar=Instance.new("Frame"); TBar.Size=UDim2.new(1,0,0,36); TBar.BackgroundColor3=C.TitleBG; TBar.BorderSizePixel=0; TBar.ZIndex=202; TBar.Parent=Main
local TLbl=Instance.new("TextLabel"); TLbl.Size=UDim2.new(1,-44,1,0); TLbl.Position=UDim2.new(0,12,0,0); TLbl.BackgroundTransparency=1; TLbl.Text="K7 HUB"; TLbl.TextColor3=C.AccText; TLbl.TextSize=15; TLbl.Font=Enum.Font.GothamBold; TLbl.TextXAlignment=Enum.TextXAlignment.Left; TLbl.ZIndex=203; TLbl.Parent=TBar
local SepLine=Instance.new("Frame"); SepLine.Size=UDim2.new(1,0,0,2); SepLine.Position=UDim2.new(0,0,0,36); SepLine.BackgroundColor3=C.Accent; SepLine.BackgroundTransparency=0.4; SepLine.BorderSizePixel=0; SepLine.ZIndex=202; SepLine.Parent=Main
local XBtn=Instance.new("TextButton"); XBtn.Size=UDim2.new(0,26,0,26); XBtn.Position=UDim2.new(1,-32,0.5,-13); XBtn.BackgroundColor3=C.Accent; XBtn.BorderSizePixel=0; XBtn.Text="X"; XBtn.TextColor3=C.White; XBtn.Font=Enum.Font.GothamBold; XBtn.TextSize=13; XBtn.ZIndex=204; XBtn.Parent=TBar; mkC(XBtn,5)

-- Drag main panel
local _drag,_ds,_sp=false,nil,nil
TBar.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then _drag=true;_ds=i.Position;_sp=Main.Position end end)
TBar.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then _drag=false end end)
UIS.InputChanged:Connect(function(i)
    if _drag and i.UserInputType==Enum.UserInputType.MouseMovement then
        local d=i.Position-_ds; Main.Position=UDim2.new(_sp.X.Scale,_sp.X.Offset+d.X,_sp.Y.Scale,_sp.Y.Offset+d.Y)
    end
end)

-- Scroll content
local Scroll=Instance.new("ScrollingFrame"); Scroll.Size=UDim2.new(1,0,1,-40); Scroll.Position=UDim2.new(0,0,0,40); Scroll.BackgroundTransparency=1; Scroll.BorderSizePixel=0; Scroll.ScrollBarThickness=3; Scroll.ScrollBarImageColor3=C.Accent; Scroll.CanvasSize=UDim2.new(0,0,0,0); Scroll.AutomaticCanvasSize=Enum.AutomaticSize.Y; Scroll.ZIndex=202; Scroll.Parent=Main

-- ── STEAL BAR — attached BELOW Main panel ──
-- Uses absolute pixel offset from Main's bottom edge
-- We'll position it relative to Main using a Frame inside ScreenGui
-- and update its position whenever Main moves

local StealBar=Instance.new("Frame")
StealBar.Name="StealBar"
StealBar.Size=UDim2.new(0,225,0,52)   -- same width as Main panel
StealBar.BackgroundColor3=Color3.new(0.0470588,0.00784314,0.00784314)
StealBar.BackgroundTransparency=0.08
StealBar.BorderSizePixel=0
StealBar.Visible=false
StealBar.ZIndex=10
StealBar.Active=true
StealBar.Parent=ScreenGui
mkC(StealBar,12)
mkS(StealBar,C.Accent,1.5,0.4)

-- Keep StealBar glued 6px below Main panel
local function syncStealBar()
    StealBar.Position=UDim2.new(
        Main.Position.X.Scale,
        Main.Position.X.Offset,
        Main.Position.Y.Scale,
        Main.Position.Y.Offset + Main.AbsoluteSize.Y + 6
    )
end
syncStealBar()

-- Update position whenever Main moves (drag)
RunService.Heartbeat:Connect(function()
    if _drag then syncStealBar() end
end)

-- Also sync when Main size changes (canvas grow)
Main:GetPropertyChangedSignal("AbsoluteSize"):Connect(syncStealBar)
Main:GetPropertyChangedSignal("AbsolutePosition"):Connect(syncStealBar)

-- Close button also destroys steal bar
XBtn.MouseButton1Click:Connect(function()
    Main:Destroy(); StealBar:Destroy()
    if _G.K7WPPanel then _G.K7WPPanel:Destroy() end
end)

-- StealBar contents
local SBTitle=Instance.new("TextLabel",StealBar); SBTitle.Size=UDim2.new(0,90,0,18); SBTitle.Position=UDim2.new(0,10,0,4); SBTitle.BackgroundTransparency=1; SBTitle.Text="AUTO STEAL"; SBTitle.Font=Enum.Font.GothamBlack; SBTitle.TextSize=11; SBTitle.TextColor3=C.Accent; SBTitle.TextXAlignment=Enum.TextXAlignment.Left; SBTitle.ZIndex=11

local SBStatus=Instance.new("TextLabel",StealBar); SBStatus.Size=UDim2.new(0,120,0,18); SBStatus.Position=UDim2.new(0,100,0,4); SBStatus.BackgroundTransparency=1; SBStatus.Text="READY"; SBStatus.Font=Enum.Font.Gotham; SBStatus.TextTransparency=0.3; SBStatus.TextColor3=C.White; SBStatus.TextSize=11; SBStatus.ZIndex=11

local SBPct=Instance.new("TextLabel",StealBar); SBPct.Size=UDim2.new(0,40,0,16); SBPct.Position=UDim2.new(0,8,0,4); SBPct.BackgroundTransparency=1; SBPct.Text="0%"; SBPct.TextSize=13; SBPct.TextColor3=C.White; SBPct.TextXAlignment=Enum.TextXAlignment.Left; SBPct.ZIndex=11

local SBRadLbl=Instance.new("TextLabel",StealBar); SBRadLbl.Size=UDim2.new(0,50,0,16); SBRadLbl.Position=UDim2.new(1,-100,0,4); SBRadLbl.BackgroundTransparency=1; SBRadLbl.Text="Radius:"; SBRadLbl.TextColor3=C.White; SBRadLbl.TextSize=11; SBRadLbl.Font=Enum.Font.Gotham; SBRadLbl.ZIndex=11

local SBRadBtn=Instance.new("TextButton",StealBar); SBRadBtn.Size=UDim2.new(0,44,0,16); SBRadBtn.Position=UDim2.new(1,-50,0,4); SBRadBtn.BackgroundColor3=Color3.new(0.137255,0.0235294,0.0392157); SBRadBtn.BorderSizePixel=0; SBRadBtn.Text="20"; SBRadBtn.TextColor3=C.AccText; SBRadBtn.Font=Enum.Font.GothamBlack; SBRadBtn.TextSize=11; SBRadBtn.ZIndex=11; mkC(SBRadBtn,4)
local radSteps={7,10,15,20}; local radIdx=4
SBRadBtn.MouseButton1Click:Connect(function() radIdx=(radIdx%#radSteps)+1; STEAL_R=radSteps[radIdx]; SBRadBtn.Text=tostring(STEAL_R) end)

-- Progress track
local SBTrack=Instance.new("Frame",StealBar)
SBTrack.Size=UDim2.new(1,-16,0,10)
SBTrack.Position=UDim2.new(0,8,0,34)
SBTrack.BackgroundColor3=Color3.new(0.117647,0.0196078,0.0196078)
SBTrack.BackgroundTransparency=0.2
SBTrack.BorderSizePixel=0
SBTrack.ClipsDescendants=true   -- critical: makes fill respect rounded corners
SBTrack.ZIndex=11
mkC(SBTrack,5)

local SBFill=Instance.new("Frame",SBTrack)
SBFill.Size=UDim2.new(0,0,1,0)
SBFill.Position=UDim2.new(0,0,0,0)
SBFill.BackgroundColor3=C.Accent
SBFill.BorderSizePixel=0
SBFill.ZIndex=12
-- No UICorner on fill — parent clips it cleanly

local stealTimer=0
RunService.Heartbeat:Connect(function(dt)
    StealBar.Visible=S.AutoSteal
    if S.AutoSteal then
        stealTimer=stealTimer+dt
        local p=math.clamp((stealTimer%3)/3,0,1)
        -- pixel-based fill so ClipsDescendants handles the rounding
        SBFill.Size=UDim2.new(0, math.floor(SBTrack.AbsoluteSize.X*p), 1, 0)
        SBPct.Text=math.floor(p*100).."%"
        SBStatus.Text=(p>=0.99) and "STEALING" or "READY"
    else
        stealTimer=0; SBFill.Size=UDim2.new(0,0,1,0); SBPct.Text="0%"; SBStatus.Text="READY"
    end
end)

-- ── DROP BUTTON — floating, draggable ──────
local DropBtn=Instance.new("TextButton"); DropBtn.Size=UDim2.new(0,70,0,28); DropBtn.Position=UDim2.new(0,16,0,0); DropBtn.BackgroundColor3=Color3.fromRGB(10,10,12); DropBtn.TextColor3=Color3.new(1,1,1); DropBtn.Text="Drop"; DropBtn.Font=Enum.Font.GothamBold; DropBtn.TextSize=13; DropBtn.AutoButtonColor=false; DropBtn.ZIndex=220; DropBtn.Parent=ScreenGui; mkC(DropBtn,4); mkS(DropBtn,Color3.fromRGB(130,80,255),2,0)

-- Position drop button right below the steal bar
local function syncDropBtn()
    DropBtn.Position=UDim2.new(
        Main.Position.X.Scale,
        Main.Position.X.Offset,
        Main.Position.Y.Scale,
        Main.Position.Y.Offset + Main.AbsoluteSize.Y + 6 + 52 + 6
    )
end
syncDropBtn()
RunService.Heartbeat:Connect(function() if _drag then syncDropBtn() end end)
Main:GetPropertyChangedSignal("AbsolutePosition"):Connect(syncDropBtn)
Main:GetPropertyChangedSignal("AbsoluteSize"):Connect(syncDropBtn)

-- Drag drop button independently
local _dd,_dds,_ddp=false,nil,nil
DropBtn.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then _dd=true;_dds=i.Position;_ddp=DropBtn.Position end end)
DropBtn.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then _dd=false end end)
UIS.InputChanged:Connect(function(i)
    if _dd and i.UserInputType==Enum.UserInputType.MouseMovement then
        local d=i.Position-_dds; DropBtn.Position=UDim2.new(_ddp.X.Scale,_ddp.X.Offset+d.X,_ddp.Y.Scale,_ddp.Y.Offset+d.Y)
    end
end)
DropBtn.MouseButton1Click:Connect(function() task.spawn(doDrop) end)

-- ══════════════════════════════════════════
-- WP OFFSET PANEL
-- ══════════════════════════════════════════
local WPPanel

function openWPPanel(side)
    if WPPanel then WPPanel:Destroy(); WPPanel=nil end
    local wps=(side=="Right") and WPRight or WPLeft
    local titleTxt=(side=="Right") and "OFFSET;RIGHT" or "OFFSET;LEFT"
    WPPanel=Instance.new("Frame"); WPPanel.Name="WPOffsetPanel"; _G.K7WPPanel=WPPanel
    WPPanel.Size=UDim2.new(0,218,0,108); WPPanel.Position=UDim2.new(0,270,0,200)
    WPPanel.BackgroundColor3=Color3.new(0.054902,0.054902,0.0784314); WPPanel.BorderSizePixel=0; WPPanel.ZIndex=50; WPPanel.Active=true; WPPanel.Parent=ScreenGui
    mkC(WPPanel,8); mkS(WPPanel,Color3.new(1,0.392157,0.313726),1.5,0.35)
    local _pd,_pds,_psp=false,nil,nil
    WPPanel.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then _pd=true;_pds=i.Position;_psp=WPPanel.Position end end)
    WPPanel.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then _pd=false end end)
    UIS.InputChanged:Connect(function(i) if _pd and i.UserInputType==Enum.UserInputType.MouseMovement then local d=i.Position-_pds; WPPanel.Position=UDim2.new(_psp.X.Scale,_psp.X.Offset+d.X,_psp.Y.Scale,_psp.Y.Offset+d.Y) end end)
    local hdr=Instance.new("Frame"); hdr.Size=UDim2.new(1,0,0,26); hdr.BackgroundColor3=Color3.new(0.054902,0.054902,0.0784314); hdr.BorderSizePixel=0; hdr.ZIndex=51; hdr.Parent=WPPanel
    local ttl=Instance.new("TextLabel"); ttl.Size=UDim2.new(1,-80,1,0); ttl.Position=UDim2.new(0,10,0,0); ttl.BackgroundTransparency=1; ttl.Text=titleTxt; ttl.TextColor3=Color3.new(1,0.392157,0.313726); ttl.TextSize=11; ttl.Font=Enum.Font.GothamBold; ttl.TextXAlignment=Enum.TextXAlignment.Left; ttl.ZIndex=52; ttl.Parent=hdr
    local rst=Instance.new("TextButton"); rst.Size=UDim2.new(0,32,0,18); rst.Position=UDim2.new(1,-58,0.5,-9); rst.BackgroundColor3=Color3.new(0.137255,0.0980392,0); rst.BorderSizePixel=0; rst.Text="RST"; rst.TextColor3=Color3.new(1,0.784314,0.196078); rst.TextSize=9; rst.Font=Enum.Font.Gotham; rst.ZIndex=53; rst.Parent=hdr; mkC(rst,3); mkS(rst,Color3.new(1,0.784314,0.196078),1,0.4)
    rst.MouseButton1Click:Connect(function() for _,wp in ipairs(wps) do wp.offset=Vector3.new(0,0,0) end; WPPanel:Destroy(); WPPanel=nil; openWPPanel(side) end)
    local cls=Instance.new("TextButton"); cls.Size=UDim2.new(0,20,0,18); cls.Position=UDim2.new(1,-24,0.5,-9); cls.BackgroundColor3=Color3.new(0.156863,0.0313726,0.0470588); cls.BorderSizePixel=0; cls.Text="X"; cls.TextColor3=C.Accent; cls.TextSize=10; cls.Font=Enum.Font.GothamBold; cls.ZIndex=53; cls.Parent=hdr; mkC(cls,3)
    cls.MouseButton1Click:Connect(function() WPPanel:Destroy(); WPPanel=nil end)
    local colXs={8,60,112,164}
    for i,wp in ipairs(wps) do
        local cx=colXs[i]
        if i>1 then local div=Instance.new("Frame"); div.Size=UDim2.new(0,1,0,74); div.Position=UDim2.new(0,cx-4,0,30); div.BackgroundColor3=Color3.new(0.137255,0.137255,0.188235); div.BorderSizePixel=0; div.ZIndex=51; div.Parent=WPPanel end
        local wlbl=Instance.new("TextLabel"); wlbl.Size=UDim2.new(0,46,0,14); wlbl.Position=UDim2.new(0,cx,0,30); wlbl.BackgroundTransparency=1; wlbl.Text=wp.label; wlbl.TextColor3=C.SubText; wlbl.TextSize=10; wlbl.Font=Enum.Font.GothamBold; wlbl.TextXAlignment=Enum.TextXAlignment.Center; wlbl.ZIndex=51; wlbl.Parent=WPPanel
        local cbar=Instance.new("Frame"); cbar.Size=UDim2.new(0,42,0,2); cbar.Position=UDim2.new(0,cx,0,44); cbar.BackgroundColor3=wp.color; cbar.BorderSizePixel=0; cbar.ZIndex=51; cbar.Parent=WPPanel; mkC(cbar,1)
        local function makeSpinner(axis, rowY)
            local axCol=(axis=="X") and Color3.new(1,0.431373,0.431373) or Color3.new(0.392157,0.705882,1)
            local xl=Instance.new("TextLabel"); xl.Size=UDim2.new(0,46,0,10); xl.Position=UDim2.new(0,cx,0,rowY-10); xl.BackgroundTransparency=1; xl.Text=axis; xl.TextColor3=axCol; xl.TextSize=9; xl.TextXAlignment=Enum.TextXAlignment.Center; xl.ZIndex=51; xl.Parent=WPPanel
            local minus=Instance.new("TextButton"); minus.Size=UDim2.new(0,14,0,16); minus.Position=UDim2.new(0,cx,0,rowY); minus.BackgroundColor3=Color3.new(0.109804,0.109804,0.14902); minus.BorderSizePixel=0; minus.Text="-"; minus.TextColor3=axCol; minus.TextSize=10; minus.Font=Enum.Font.GothamBold; minus.ZIndex=52; minus.Parent=WPPanel
            local box=Instance.new("TextBox"); box.Size=UDim2.new(0,18,0,16); box.Position=UDim2.new(0,cx+14,0,rowY); box.BackgroundColor3=Color3.new(0.0627451,0.0627451,0.0862745); box.BorderSizePixel=0; box.Text="0"; box.TextColor3=C.White; box.Font=Enum.Font.GothamBold; box.TextSize=8; box.ClearTextOnFocus=false; box.ZIndex=52; box.Parent=WPPanel; mkS(box,axCol,1,0.6)
            local plus=Instance.new("TextButton"); plus.Size=UDim2.new(0,14,0,16); plus.Position=UDim2.new(0,cx+32,0,rowY); plus.BackgroundColor3=Color3.new(0.109804,0.109804,0.14902); plus.BorderSizePixel=0; plus.Text="+"; plus.TextColor3=axCol; plus.TextSize=10; plus.Font=Enum.Font.GothamBold; plus.ZIndex=52; plus.Parent=WPPanel
            local function applyVal(val)
                local cur=wp.offset
                if axis=="X" then wp.offset=Vector3.new(val, cur.Y, cur.Z)
                else             wp.offset=Vector3.new(cur.X, cur.Y, val) end
            end
            local function step(d)
                local next=(tonumber(box.Text) or 0)+d
                box.Text=tostring(next); applyVal(next)
            end
            minus.MouseButton1Click:Connect(function() step(-1) end)
            plus.MouseButton1Click:Connect(function() step(1) end)
            box.FocusLost:Connect(function()
                local raw=box.Text:match("^%-?%d+") or "0"
                local val=tonumber(raw) or 0; box.Text=tostring(val); applyVal(val)
            end)
        end
        makeSpinner("X",58); makeSpinner("Y",86)
    end
end

-- ══════════════════════════════════════════
-- SCROLL BUTTONS
-- ══════════════════════════════════════════
local yPos=6

local function secLabel(text)
    local l=Instance.new("TextLabel"); l.Size=UDim2.new(1,-12,0,18); l.Position=UDim2.new(0,6,0,yPos); l.BackgroundTransparency=1; l.Text=text; l.TextColor3=C.SubText; l.TextSize=9; l.Font=Enum.Font.Gotham; l.TextXAlignment=Enum.TextXAlignment.Left; l.ZIndex=203; l.Parent=Scroll; yPos=yPos+20
end

local function toggleBtn(label, keyText, callback, hasGearBtn, gearSide, stateKey)
    local btn=Instance.new("TextButton"); btn.Size=UDim2.new(1,-12,0,28); btn.Position=UDim2.new(0,6,0,yPos); btn.BackgroundColor3=C.Panel; btn.BorderSizePixel=0; btn.Text=""; btn.AutoButtonColor=false; btn.ZIndex=203; btn.Parent=Scroll; mkC(btn,5); mkS(btn,C.PanelSt,1,0.2)
    local labelX=6
    if keyText~="" then
        local badge=Instance.new("TextLabel"); badge.Size=UDim2.new(0,24,0,16); badge.Position=UDim2.new(0,5,0.5,-8); badge.BackgroundColor3=C.KeyBG; badge.BackgroundTransparency=0; badge.BorderSizePixel=0; badge.Text=keyText; badge.TextSize=8; badge.TextColor3=C.Accent; badge.Font=Enum.Font.Gotham; badge.ZIndex=205; badge.Parent=btn; mkC(badge,3); mkS(badge,C.PanelSt,1,0.5)
        labelX=34
    end
    local rightPad=hasGearBtn and 30 or 20
    local lbl=Instance.new("TextLabel"); lbl.Size=UDim2.new(1,-(labelX+rightPad),1,0); lbl.Position=UDim2.new(0,labelX,0,0); lbl.BackgroundTransparency=1; lbl.Text=label; lbl.TextColor3=C.White; lbl.TextSize=11; lbl.Font=Enum.Font.Gotham; lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.ZIndex=204; lbl.Parent=btn
    if hasGearBtn then
        local gBtn=Instance.new("TextButton"); gBtn.Size=UDim2.new(0,22,0,22); gBtn.Position=UDim2.new(1,-26,0.5,-11); gBtn.BackgroundColor3=C.GearBG; gBtn.BorderSizePixel=0; gBtn.Text="⚙"; gBtn.TextColor3=C.GearBlue; gBtn.TextSize=12; gBtn.Font=Enum.Font.Gotham; gBtn.ZIndex=206; gBtn.Parent=btn; mkC(gBtn,4)
        gBtn.MouseButton1Click:Connect(function() openWPPanel(gearSide) end)
    else
        local gLbl=Instance.new("TextLabel"); gLbl.Size=UDim2.new(0,14,1,0); gLbl.Position=UDim2.new(1,-16,0,0); gLbl.BackgroundTransparency=1; gLbl.Text="⚙"; gLbl.TextColor3=C.SubText; gLbl.TextSize=10; gLbl.ZIndex=204; gLbl.Parent=btn
    end
    local on=false
    local function refresh(forceVal)
        if forceVal~=nil then on=forceVal end
        btn.BackgroundColor3=on and Color3.new(0.15,0.03,0.05) or C.Panel
    end
    if stateKey then btnRefreshFns[stateKey]=refresh end
    btn.MouseButton1Click:Connect(function() on=not on; refresh(); if callback then callback(on) end end)
    btn.MouseButton2Click:Connect(function() on=false; refresh(); if callback then callback(false) end end)
    yPos=yPos+33
end

local function countdownSwitch(callback)
    local row=Instance.new("Frame"); row.Size=UDim2.new(1,-12,0,36); row.Position=UDim2.new(0,6,0,yPos); row.BackgroundColor3=C.Panel; row.BorderSizePixel=0; row.ZIndex=203; row.Parent=Scroll; mkC(row,5)
    local lbl=Instance.new("TextLabel"); lbl.Size=UDim2.new(1,-50,1,0); lbl.Position=UDim2.new(0,8,0,0); lbl.BackgroundTransparency=1; lbl.Text="Auto Play After Countdown"; lbl.TextColor3=C.White; lbl.TextSize=10; lbl.Font=Enum.Font.Gotham; lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.TextWrapped=true; lbl.ZIndex=204; lbl.Parent=row
    local swO=Instance.new("Frame"); swO.Size=UDim2.new(0,34,0,17); swO.Position=UDim2.new(1,-42,0.5,-8); swO.BackgroundColor3=C.SW_Off; swO.BorderSizePixel=0; swO.ZIndex=204; swO.Parent=row; mkC(swO,8)
    local swK=Instance.new("Frame"); swK.Size=UDim2.new(0,13,0,13); swK.Position=UDim2.new(0,2,0.5,-6); swK.BackgroundColor3=C.SW_Knob; swK.BorderSizePixel=0; swK.ZIndex=205; swK.Parent=swO; mkC(swK,6)
    local swB=Instance.new("TextButton"); swB.Size=UDim2.new(1,0,1,0); swB.BackgroundTransparency=1; swB.Text=""; swB.ZIndex=206; swB.Parent=row
    local on=false
    local function refresh() TweenService:Create(swK,TweenInfo.new(0.12),{Position=on and UDim2.new(0,19,0.5,-6) or UDim2.new(0,2,0.5,-6),BackgroundColor3=on and C.Accent or C.SW_Knob}):Play(); swO.BackgroundColor3=on and Color3.new(0.12,0.03,0.05) or C.SW_Off end
    swB.MouseButton1Click:Connect(function() on=not on; refresh(); if callback then callback(on) end end)
    yPos=yPos+42
end

secLabel("── MOVEMENT ──")
toggleBtn("Speed","Q",function(on) S.Speed=on end)
toggleBtn("Float","F",function(on) S.Float=on; if on then startFloat() else stopFloat() end end)

secLabel("── TELEPORT ──")
toggleBtn("TP RIGHT","V",function(on) if on then task.spawn(doTPRight) end end)
toggleBtn("Auto Play after TP","",function(on) S.AutoPlayTP=on end)
toggleBtn("Drop Brainrot","X",function(on) if on then task.spawn(doDropBrainrot) end end)
toggleBtn("TP Down","G",function(on) if on then task.spawn(doTPDown) end end)

secLabel("── AUTO ──")
toggleBtn("Auto Steal","",function(on) S.AutoSteal=on end)
toggleBtn("Auto Left","Z",function(on)
    S.AutoLeft=on; if on then startAutoLeft() else stopAutoLeft() end
end, false, nil, "AutoLeft")
toggleBtn("Auto Right","C",function(on)
    S.AutoRight=on; if on then startAutoRight() else stopAutoRight() end
end, false, nil, "AutoRight")
toggleBtn("Auto Play Left","J",function(on)
    aplOn=on; S.AutoPlayLeft=on; if on then startAutoPlayLeft() else stopAutoPlayLeft() end
end, true, "Left", "AutoPlayLeft")
toggleBtn("Auto Play Right","K",function(on)
    aprOn=on; S.AutoPlayRight=on; if on then startAutoPlayRight() else stopAutoPlayRight() end
end, true, "Right", "AutoPlayRight")
countdownSwitch(function(on) S.AutoPlayCD=on end)

secLabel("── BAT AIMBOT ──")
toggleBtn("Bat Aimbot","E",function(on) S.BatAimbot=on end)
toggleBtn("Auto Swing","",function(on) S.AutoSwing=on end)

secLabel("── DEFENSE ──")
toggleBtn("Anti Ragdoll","",function(on) S.AntiRagdoll=on; if on then enableAntiRagdoll() else disableAntiRagdoll() end end)
toggleBtn("Medusa Counter","",function(on) S.MedusaCounter=on end)
toggleBtn("Unwalk","",function(on) S.Unwalk=on; if on then enableUnwalk() else disableUnwalk() end end)
toggleBtn("Infinite Jump","",function(on) S.InfJump=on end)

secLabel("── VISUAL ──")
toggleBtn("No Cam Collision","",function(on) S.NoCamCol=on; workspace.CurrentCamera.CameraType=on and Enum.CameraType.Scriptable or Enum.CameraType.Custom end)
toggleBtn("Shiny Graphics","",function(on) S.ShinyGraphics=on; if on then task.spawn(applyShiny) end end)
toggleBtn("Optimizer","",function(on) S.Optimizer=on; if on then task.spawn(enableOptimizer) else task.spawn(disableOptimizer) end end)
toggleBtn("Remove Accessories","",function(on)
    if on then local c=me.Character; if c then for _,v in ipairs(c:GetDescendants()) do if v:IsA("Accessory") then v:Destroy() end end end end
end)

print("[K7] Mini Hub loaded")
