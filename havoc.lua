-- HAVOC HUB | BK's Hub v5 STYLE | FULL LOGIC | XENO SAFE

if not Drawing then return warn("Drawing API not supported") end

-- ================= SERVICES =================
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RS = game:GetService("RunService")

local LP = Players.LocalPlayer
local Char, Humanoid, HRP

local function refreshChar()
    Char = LP.Character or LP.CharacterAdded:Wait()
    Humanoid = Char:WaitForChild("Humanoid")
    HRP = Char:WaitForChild("HumanoidRootPart")
end
refreshChar()
LP.CharacterAdded:Connect(refreshChar)

-- ================= TOGGLES =================
local Toggles = {
    AutoDesync = false,
    AutoTeleport = false,
    BodySwap = false,
    ReturnAfterTP = false,
    AutoClone = false,
    AutoDestroyTurret = false,
    GrappleSpeed = false,
    InfiniteJump = false
}

-- ================= UI STATE =================
local visible = true
local dragging = false
local dragOffset = Vector2.new()
local pos = Vector2.new(260,160)
local size = Vector2.new(520,360)

local theme = {
    bg = Color3.fromRGB(20,20,25),
    panel = Color3.fromRGB(28,28,35),
    header = Color3.fromRGB(32,32,42),
    accent = Color3.fromRGB(170,90,255),
    text = Color3.fromRGB(230,230,230)
}

local tabs = {"Brainrots","Features","Misc","Settings","Credits"}
local currentTab = "Brainrots"
local objects, togglesUI = {}, {}

-- ================= DRAW HELPERS =================
local function newSquare()
    local s = Drawing.new("Square")
    s.Filled = true
    s.Visible = true
    table.insert(objects,s)
    return s
end

local function newText()
    local t = Drawing.new("Text")
    t.Font = 2
    t.Size = 16
    t.Visible = true
    table.insert(objects,t)
    return t
end

-- ================= MAIN UI =================
local bg = newSquare()
bg.Size = size
bg.Color = theme.bg

local header = newSquare()
header.Size = Vector2.new(size.X,44)
header.Color = theme.header

local sidebar = newSquare()
sidebar.Size = Vector2.new(70,size.Y-44)
sidebar.Color = theme.panel

local title = newText()
title.Text = "HAVOC HUB"
title.Size = 18
title.Color = theme.accent

local tabButtons = {}
for i,name in ipairs(tabs) do
    local t = newText()
    t.Text = name:sub(1,1)
    tabButtons[name] = t
end

-- ================= TOGGLE CREATOR =================
local function createToggle(label,index,flag)
    local text = newText()
    text.Text = label
    text.Color = theme.text

    local track = newSquare()
    track.Size = Vector2.new(44,18)
    track.Color = Color3.fromRGB(45,45,55)

    local knob = newSquare()
    knob.Size = Vector2.new(16,16)
    knob.Color = theme.accent

    togglesUI[#togglesUI+1] = {
        label=text, track=track, knob=knob,
        index=index, flag=flag
    }
end

createToggle("Auto-Desync V3",1,"AutoDesync")
createToggle("Auto Teleport",2,"AutoTeleport")
createToggle("Body Swap",3,"BodySwap")
createToggle("Return After TP",4,"ReturnAfterTP")
createToggle("Auto Clone",5,"AutoClone")
createToggle("Destroy Turrets",7,"AutoDestroyTurret")
createToggle("Grapple Speed",8,"GrappleSpeed")
createToggle("Infinite Jump",9,"InfiniteJump")

-- ================= FEATURE LOGIC =================

-- Auto Desync
RS.Heartbeat:Connect(function()
    if Toggles.AutoDesync and HRP then
        HRP.Velocity = Vector3.new(math.random(-45,45),0,math.random(-45,45))
    end
end)

-- Auto Teleport (brainrot)
local function tpBrainrot()
    for _,v in pairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") and v.Name:lower():find("brainrot") then
            HRP.CFrame = v.CFrame + Vector3.new(0,3,0)
            return
        end
    end
end

task.spawn(function()
    while task.wait(2) do
        if Toggles.AutoTeleport then
            tpBrainrot()
        end
    end
end)

-- Body Swap
task.spawn(function()
    while task.wait(0.5) do
        if Humanoid then
            Humanoid.CameraOffset = Toggles.BodySwap and Vector3.new(2,0,0) or Vector3.zero
        end
    end
end)

-- Return After TP
local lastPos
RS.Heartbeat:Connect(function()
    if HRP then lastPos = HRP.CFrame end
end)

task.spawn(function()
    while task.wait(3) do
        if Toggles.ReturnAfterTP and lastPos then
            HRP.CFrame = lastPos
        end
    end
end)

-- Auto Clone
task.spawn(function()
    while task.wait(4) do
        if Toggles.AutoClone and Char then
            local c = Char:Clone()
            c.Parent = workspace
            c:SetPrimaryPartCFrame(HRP.CFrame * CFrame.new(3,0,0))
            task.delay(2,function() c:Destroy() end)
        end
    end
end)

-- Destroy Turrets
task.spawn(function()
    while task.wait(1) do
        if Toggles.AutoDestroyTurret then
            for _,v in pairs(workspace:GetDescendants()) do
                if v:IsA("BasePart") and v.Name:lower():find("turret") then
                    v:Destroy()
                end
            end
        end
    end
end)

-- Grapple Speed
RS.Heartbeat:Connect(function()
    if Humanoid then
        Humanoid.WalkSpeed = Toggles.GrappleSpeed and 40 or 16
    end
end)

-- Infinite Jump
UIS.JumpRequest:Connect(function()
    if Toggles.InfiniteJump and Humanoid then
        Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

-- ================= RENDER =================
RS.RenderStepped:Connect(function()
    bg.Position = pos
    header.Position = pos
    sidebar.Position = pos + Vector2.new(0,44)
    title.Position = pos + Vector2.new(18,12)

    for i,name in ipairs(tabs) do
        local b = tabButtons[name]
        b.Position = pos + Vector2.new(26,64+(i-1)*46)
        b.Color = (name==currentTab) and theme.accent or theme.text
    end

    for _,t in ipairs(togglesUI) do
        local y = pos.Y + 70 + (t.index-1)*32
        t.label.Position = Vector2.new(pos.X+90,y)
        t.track.Position = Vector2.new(pos.X+size.X-80,y+2)
        t.knob.Position = t.track.Position + Vector2.new(Toggles[t.flag] and 26 or 2,1)
    end
end)

-- ================= INPUT =================
UIS.InputBegan:Connect(function(i)
    if i.KeyCode == Enum.KeyCode.RightShift then
        visible = not visible
        for _,o in ipairs(objects) do o.Visible = visible end
    end

    if i.UserInputType == Enum.UserInputType.MouseButton1 then
        local m = UIS:GetMouseLocation()

        if m.X>=pos.X and m.X<=pos.X+size.X and m.Y>=pos.Y and m.Y<=pos.Y+44 then
            dragging=true
            dragOffset=m-pos
        end

        for _,t in ipairs(togglesUI) do
            local p=t.track.Position
            if m.X>=p.X and m.X<=p.X+44 and m.Y>=p.Y and m.Y<=p.Y+18 then
                Toggles[t.flag]=not Toggles[t.flag]
            end
        end
    end
end)

UIS.InputEnded:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end
end)

UIS.InputChanged:Connect(function(i)
    if dragging and i.UserInputType==Enum.UserInputType.MouseMovement then
        pos=UIS:GetMouseLocation()-dragOffset
    end
end)

print("HAVOC HUB FULLY LOADED | XENO")
