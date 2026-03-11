-- Havoc Duels Hub (refactored for stability)
-- NOTE: This script is written to avoid nil crashes and keep every toggle functional.

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")

local lp = Players.LocalPlayer
local playerGui = lp:WaitForChild("PlayerGui")

local state = {
    character = nil,
    humanoid = nil,
    hrp = nil,
    infiniteJump = false,
    slowFall = false,
    autoBat = false,
    autoWalk = false,
    walkGui = nil,
    walkRunning = false,
    walkSpeedConnection = nil,
    savedAnimate = nil,
    meleeEnabled = false,
    lockEnabled = false,
    autoSteal = false,
    autoMedusa = false,
}

local config = {
    MELEE_RANGE = 45,
    LOCK_RADIUS = 70,
    MEDUSA_RADIUS = 10,
    STEAL_RADIUS = 50,
}

local function setupCharacter(char)
    state.character = char
    state.hrp = char:WaitForChild("HumanoidRootPart", 8)
    state.humanoid = char:WaitForChild("Humanoid", 8)
end

if lp.Character then setupCharacter(lp.Character) end
lp.CharacterAdded:Connect(setupCharacter)

-- Optimizer
local optimizer = { enabled = false, savedLighting = {}, objects = {} }
local function enableOptimizer()
    if optimizer.enabled then return end
    optimizer.enabled = true
    optimizer.savedLighting = {
        GlobalShadows = Lighting.GlobalShadows,
        FogStart = Lighting.FogStart,
        FogEnd = Lighting.FogEnd,
        Brightness = Lighting.Brightness,
        EnvironmentDiffuseScale = Lighting.EnvironmentDiffuseScale,
        EnvironmentSpecularScale = Lighting.EnvironmentSpecularScale,
    }
    Lighting.GlobalShadows = false
    Lighting.FogStart = 0
    Lighting.FogEnd = 1e9
    Lighting.Brightness = 1
    Lighting.EnvironmentDiffuseScale = 0
    Lighting.EnvironmentSpecularScale = 0

    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") then
            optimizer.objects[v] = { v.Material, v.Reflectance }
            v.Material = Enum.Material.Plastic
            v.Reflectance = 0
        elseif v:IsA("Decal") or v:IsA("Texture") then
            optimizer.objects[v] = v.Transparency
            v.Transparency = 1
        elseif v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Smoke") or v:IsA("Fire") then
            optimizer.objects[v] = v.Enabled
            v.Enabled = false
        end
    end
end

local function disableOptimizer()
    if not optimizer.enabled then return end
    optimizer.enabled = false
    for k, v in pairs(optimizer.savedLighting) do Lighting[k] = v end
    for obj, val in pairs(optimizer.objects) do
        if obj and obj.Parent then
            if typeof(val) == "table" then
                obj.Material = val[1]
                obj.Reflectance = val[2]
            elseif typeof(val) == "boolean" then
                obj.Enabled = val
            else
                obj.Transparency = val
            end
        end
    end
    optimizer.objects = {}
end

-- Basic GUI
local sg = Instance.new("ScreenGui")
sg.Name = "HavocDuels"
sg.ResetOnSpawn = false
sg.Parent = playerGui

local hub = Instance.new("Frame")
hub.Name = "Main"
hub.Size = UDim2.new(0, 280, 0, 360)
hub.Position = UDim2.new(0, 20, 0.5, -180)
hub.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
hub.BackgroundTransparency = 0.25
hub.Parent = sg
Instance.new("UICorner", hub).CornerRadius = UDim.new(0, 14)

local stroke = Instance.new("UIStroke", hub)
stroke.Color = Color3.fromRGB(0, 120, 255)
stroke.Thickness = 2

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -20, 0, 38)
title.Position = UDim2.new(0, 12, 0, 8)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.TextSize = 21
title.TextXAlignment = Enum.TextXAlignment.Left
title.TextColor3 = Color3.fromRGB(0, 120, 255)
title.Text = "Havoc Duels"
title.Parent = hub

local list = Instance.new("ScrollingFrame")
list.Size = UDim2.new(1, -20, 1, -60)
list.Position = UDim2.new(0, 10, 0, 50)
list.BackgroundTransparency = 1
list.ScrollBarThickness = 4
list.CanvasSize = UDim2.new(0, 0, 0, 0)
list.Parent = hub

local layout = Instance.new("UIListLayout")
layout.Parent = list
layout.Padding = UDim.new(0, 8)
layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    list.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 8)
end)

local function createToggle(text, onToggle)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 40)
    row.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    row.BackgroundTransparency = 0.2
    row.Parent = list
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 10)
    Instance.new("UIStroke", row).Color = Color3.fromRGB(0, 120, 255)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.7, 0, 1, 0)
    label.Position = UDim2.new(0, 12, 0, 0)
    label.BackgroundTransparency = 1
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Font = Enum.Font.GothamBold
    label.TextSize = 14
    label.TextColor3 = Color3.fromRGB(0, 120, 255)
    label.Text = text
    label.Parent = row

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 52, 0, 24)
    btn.Position = UDim2.new(1, -62, 0.5, -12)
    btn.Text = ""
    btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    btn.Parent = row
    Instance.new("UICorner", btn).CornerRadius = UDim.new(1, 0)

    local dot = Instance.new("Frame")
    dot.Size = UDim2.new(0, 18, 0, 18)
    dot.Position = UDim2.new(0, 3, 0.5, -9)
    dot.BackgroundColor3 = Color3.fromRGB(225, 225, 225)
    dot.Parent = btn
    Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)

    local enabled = false
    btn.MouseButton1Click:Connect(function()
        enabled = not enabled
        TweenService:Create(btn, TweenInfo.new(0.2), { BackgroundColor3 = enabled and Color3.fromRGB(0,120,255) or Color3.fromRGB(50,50,50) }):Play()
        TweenService:Create(dot, TweenInfo.new(0.2), { Position = enabled and UDim2.new(1,-21,0.5,-9) or UDim2.new(0,3,0.5,-9) }):Play()
        onToggle(enabled)
    end)
end

-- Feature wiring (safe functional handlers)
createToggle("Optimizer", function(v) if v then enableOptimizer() else disableOptimizer() end end)
createToggle("Slow Fall", function(v) state.slowFall = v end)
createToggle("Infinite Jump", function(v) state.infiniteJump = v end)
createToggle("No Walk Animation", function(v)
    if not state.character then return end
    local animate = state.character:FindFirstChild("Animate")
    if v then
        state.savedAnimate = animate
        if animate then animate.Disabled = true end
    else
        if state.savedAnimate then state.savedAnimate.Disabled = false end
        state.savedAnimate = nil
    end
end)
createToggle("Auto Bat", function(v) state.autoBat = v end)

RunService.Heartbeat:Connect(function()
    if state.slowFall and state.humanoid and state.hrp and state.humanoid:GetState() == Enum.HumanoidStateType.Freefall then
        local vel = state.hrp.AssemblyLinearVelocity
        if vel.Y < -1 then
            state.hrp.AssemblyLinearVelocity = Vector3.new(vel.X, vel.Y * 0.5, vel.Z)
        end
    end
    if state.autoBat and state.character then
        local bat = state.character:FindFirstChild("Bat")
        if bat and bat:IsA("Tool") then pcall(function() bat:Activate() end) end
    end
end)

UserInputService.JumpRequest:Connect(function()
    if state.infiniteJump and state.hrp then
        local v = state.hrp.AssemblyLinearVelocity
        state.hrp.AssemblyLinearVelocity = Vector3.new(v.X, 50, v.Z)
    end
end)
