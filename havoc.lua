-- HAVOC HUB | BK's Hub v5 STYLE | Xeno Drawing UI
-- FULL LOCKED LOADSTRING VERSION

if not Drawing then return warn("Drawing API not supported") end

local UIS = game:GetService("UserInputService")
local RS = game:GetService("RunService")

local visible = true
local dragging = false
local dragOffset = Vector2.new()

local pos = Vector2.new(260, 160)
local size = Vector2.new(520, 360)

local theme = {
    bg = Color3.fromRGB(20,20,25),
    panel = Color3.fromRGB(28,28,35),
    header = Color3.fromRGB(32,32,42),
    accent = Color3.fromRGB(170,90,255),
    text = Color3.fromRGB(230,230,230),
    subtext = Color3.fromRGB(180,180,180)
}

local currentTab = "Brainrots"
local tabs = {"Brainrots","Features","Misc","Settings","Credits"}
local objects, toggles = {}, {}

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

local bg = newSquare()
bg.Color = theme.bg
bg.Size = size

local header = newSquare()
header.Color = theme.header
header.Size = Vector2.new(size.X,44)

local title = newText()
title.Text = "HAVOC HUB"
title.Size = 18
title.Color = theme.accent

local sidebar = newSquare()
sidebar.Color = theme.panel
sidebar.Size = Vector2.new(70, size.Y-44)

local tabButtons = {}
for i,name in ipairs(tabs) do
    local t = newText()
    t.Text = name:sub(1,1)
    tabButtons[name] = t
end

local function createToggle(label, index)
    local text = newText()
    text.Text = label
    text.Color = theme.text

    local track = newSquare()
    track.Color = Color3.fromRGB(45,45,55)
    track.Size = Vector2.new(44,18)

    local knob = newSquare()
    knob.Color = theme.accent
    knob.Size = Vector2.new(16,16)

    table.insert(toggles,{
        label=text, track=track, knob=knob, on=false, index=index
    })
end

createToggle("Auto-Desync V3 on Start",1)
createToggle("Auto-Teleport on Start",2)
createToggle("Enable Body Swap",3)
createToggle("Go to Brainrot After TP",4)
createToggle("Auto-Clone After Teleport",5)
createToggle("Auto-Destroy Turret",7)
createToggle("Grapple Speed",8)
createToggle("Infinite Jump",9)

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

    for _,t in ipairs(toggles) do
        local y = pos.Y + 70 + (t.index-1)*32
        t.label.Position = Vector2.new(pos.X+90,y)
        t.track.Position = Vector2.new(pos.X+size.X-80,y+2)
        t.knob.Position = t.track.Position + Vector2.new(t.on and 26 or 2,1)
    end
end)

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

        for name,b in pairs(tabButtons) do
            if m.X>=b.Position.X and m.X<=b.Position.X+24
            and m.Y>=b.Position.Y and m.Y<=b.Position.Y+24 then
                currentTab=name
            end
        end

        for _,t in ipairs(toggles) do
            local p=t.track.Position
            if m.X>=p.X and m.X<=p.X+44 and m.Y>=p.Y and m.Y<=p.Y+18 then
                t.on=not t.on
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

print("HAVOC HUB LOADED | XENO SAFE")
