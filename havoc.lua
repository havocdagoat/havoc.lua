-- HAVOC HUB
-- Exact clone layout of BK's Hub (Orange Theme)

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer

-- Gui
local gui = Instance.new("ScreenGui")
gui.Name = "HavocHub"
gui.Parent = player:WaitForChild("PlayerGui")

-- Main container
local main = Instance.new("Frame")
main.Size = UDim2.fromScale(0.52, 0.62)
main.Position = UDim2.fromScale(0.5, 0.5)
main.AnchorPoint = Vector2.new(0.5,0.5)
main.BackgroundColor3 = Color3.fromRGB(15,15,15)
main.BackgroundTransparency = 0.05
main.Parent = gui
Instance.new("UICorner", main).CornerRadius = UDim.new(0,18)

-- Top bar
local top = Instance.new("Frame")
top.Size = UDim2.new(1,0,0,55)
top.BackgroundTransparency = 1
top.Parent = main

local title = Instance.new("TextLabel")
title.Text = "HAVOC HUB  v1"
title.Font = Enum.Font.GothamBold
title.TextSize = 24
title.TextColor3 = Color3.fromRGB(255,140,0)
title.BackgroundTransparency = 1
title.Position = UDim2.new(0,20,0,0)
title.Size = UDim2.new(1,-40,1,0)
title.TextXAlignment = Left
title.Parent = top

-- Sidebar
local sidebar = Instance.new("Frame")
sidebar.Size = UDim2.new(0,150,1,-65)
sidebar.Position = UDim2.new(0,0,0,65)
sidebar.BackgroundColor3 = Color3.fromRGB(18,18,18)
sidebar.Parent = main
Instance.new("UICorner", sidebar).CornerRadius = UDim.new(0,14)

-- Content
local content = Instance.new("Frame")
content.Size = UDim2.new(1,-170,1,-65)
content.Position = UDim2.new(0,160,0,65)
content.BackgroundTransparency = 1
content.Parent = main

-- Sidebar buttons
local tabs = {"Brainrots","Features","Misc","Settings","Credits"}
local pages = {}

local function sidebarButton(text, index)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1,-20,0,40)
    b.Position = UDim2.new(0,10,0,10 + (index-1)*45)
    b.Text = text
    b.Font = Enum.Font.GothamBold
    b.TextSize = 14
    b.TextColor3 = Color3.new(1,1,1)
    b.BackgroundColor3 = Color3.fromRGB(255,140,0)
    b.BackgroundTransparency = 0.15
    b.Parent = sidebar
    Instance.new("UICorner", b).CornerRadius = UDim.new(0,10)

    b.MouseButton1Click:Connect(function()
        for _,p in pairs(pages) do
            p.Visible = false
        end
        pages[index].Visible = true
    end)
end

-- Pages
local function newPage()
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1,0,1,0)
    f.BackgroundTransparency = 1
    f.Visible = false
    f.Parent = content
    return f
end

for i=1,#tabs do
    sidebarButton(tabs[i], i)
    pages[i] = newPage()
end

pages[1].Visible = true

-- Toggle creator (matches screenshot rows)
local function createToggle(parent, text, y)
    local holder = Instance.new("Frame")
    holder.Size = UDim2.new(1,-20,0,50)
    holder.Position = UDim2.new(0,10,0,y)
    holder.BackgroundColor3 = Color3.fromRGB(25,25,25)
    holder.BackgroundTransparency = 0.1
    holder.Parent = parent
    Instance.new("UICorner", holder).CornerRadius = UDim.new(0,12)

    local label = Instance.new("TextLabel")
    label.Text = text
    label.Font = Enum.Font.Gotham
    label.TextSize = 14
    label.TextColor3 = Color3.fromRGB(255,200,120)
    label.BackgroundTransparency = 1
    label.Position = UDim2.new(0,15,0,0)
    label.Size = UDim2.new(1,-80,1,0)
    label.TextXAlignment = Left
    label.Parent = holder

    local toggle = Instance.new("TextButton")
    toggle.Size = UDim2.new(0,46,0,24)
    toggle.Position = UDim2.new(1,-60,0.5,-12)
    toggle.Text = ""
    toggle.BackgroundColor3 = Color3.fromRGB(60,60,60)
    toggle.Parent = holder
    Instance.new("UICorner", toggle).CornerRadius = UDim.new(1,0)

    local on = false
    toggle.MouseButton1Click:Connect(function()
        on = not on
        TweenService:Create(
            toggle,
            TweenInfo.new(0.25),
            {BackgroundColor3 = on and Color3.fromRGB(255,140,0) or Color3.fromRGB(60,60,60)}
        ):Play()
    end)
end

-- Main Features 
local y = 0
createToggle(pages[1],"Auto-Desync V3 on Start",y); y+=55
createToggle(pages[1],"Auto-Teleport on Start",y); y+=55
createToggle(pages[1],"Enable Body Swap",y); y+=55
createToggle(pages[1],"Go to Brainrot After TP",y); y+=55
createToggle(pages[1],"Auto-Clone After Teleport",y); y+=55
createToggle(pages[1],"Auto-Destroy Turret",y); y+=55
createToggle(pages[1],"Infinite Jump",y)local y = 0
createToggle(pages[1],"Auto-Desync V3 on Start",y,"AutoDesync",enableDesync,disableDesync); y+=55
createToggle(pages[1],"Auto-Teleport on Start",y,"AutoTeleport",enableAutoTP,disableAutoTP); y+=55
createToggle(pages[1],"Enable Body Swap",y,"BodySwap",enableBodySwap,disableBodySwap); y+=55
createToggle(pages[1],"Go to Brainrot After TP",y,"GoBrainrotAfterTP"); y+=55
createToggle(pages[1],"Auto-Clone After Teleport",y,"AutoClone"); y+=55
createToggle(pages[1],"Auto-Destroy Turret",y,"AutoDestroyTurret",enableTurretDestroy,disableTurretDestroy); y+=55
createToggle(pages[1],"Grapple Speed",y,"GrappleSpeed"); y+=55
createToggle(pages[1],"Infinite Jump",y,"InfiniteJump",enableInfiniteJump,disableInfiniteJump)
