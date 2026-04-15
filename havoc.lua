repeat task.wait() until game:IsLoaded()
local Players,RunService,UIS,TS,Lighting,HS = game:GetService("Players"),game:GetService("RunService"),game:GetService("UserInputService"),game:GetService("TweenService"),game:GetService("Lighting"),game:GetService("HttpService")
local LP = Players.LocalPlayer

local NS,CS,DAS,DAD = 60,30,150,0.2
local KB = {SpeedToggle=Enum.KeyCode.Q,DropBrainrot=Enum.KeyCode.X,AutoLeft=Enum.KeyCode.Z,AutoRight=Enum.KeyCode.C,AutoBat=Enum.KeyCode.E,TPLeft=Enum.KeyCode.V,TPRight=Enum.KeyCode.B,Unwalk=Enum.KeyCode.U,TPFloor=Enum.KeyCode.F}

local speedMode,autoGrabEnabled,antiRagdollEnabled,infJumpEnabled=false,false,false,false
local medusaCounterEnabled,brainrotLeftEnabled,brainrotRightEnabled,brainrotCooldown=false,false,false,false
local unwalkEnabled=false
local unwalkAnimations={}
local lastHealth,medusaDebounce,medusaLastUsed,dropActive,waitingForKey=100,false,0,false,nil
local antiLagEnabled,ultraModeEnabled,removeAccessoriesEnabled,descendantConnection,accessoryConnection=false,false,false,nil,nil
local autoLeftEnabled,autoRightEnabled,autoLeftConn,autoRightConn=false,false,nil,nil
local autoLeftPhase,autoRightPhase,autoLeftSetVisual,autoRightSetVisual=1,1,nil,nil
local speedLabel,speedBtn=nil,nil
local medusaConns={}

-- BAT AIMBOT
local autoBatEnabled,batHittingCooldown=false,false
local autoBatSetVisual=nil

local AP_L1,AP_L2=Vector3.new(-476.48,-6.28,92.73),Vector3.new(-483.12,-4.95,94.80)
local AP_R1,AP_R2=Vector3.new(-476.16,-6.52,25.62),Vector3.new(-483.06,-5.03,25.48)

-- Left: 3-step TP
local BR_L1,BR_L2,BR_L3=Vector3.new(-469,-6,78),Vector3.new(-471,-6,96),Vector3.new(-484,-4,99)
-- Right: 3-step TP
local BR_R1,BR_R2,BR_R3=Vector3.new(-468,-6,41),Vector3.new(-473,-6,24),Vector3.new(-484,-4,20)

-- ===== AUTO STEAL (replaced) =====
local Steal = {
	AutoStealEnabled = false, StealRadius = 20, StealDuration = 0.25,
	Data = {}, plotCache = {}, plotCacheTime = {},
	cachedPrompts = {}, promptCacheTime = 0,
}

local StealState = {
	isStealing = false, stealStartTime = nil, lastStealTick = 0,
}

local StealConns = { autoSteal = nil, progress = nil }

local PLOT_CACHE_DURATION = 2
local PROMPT_CACHE_REFRESH = 0.15
local STEAL_COOLDOWN = 0.1

-- keep legacy aliases so the rest of K7 still works
local function getIsStealing() return StealState.isStealing end
local function getStealStartTime() return StealState.stealStartTime end
local function getGrabDuration() return Steal.StealDuration end
local function setGrabDuration(v) Steal.StealDuration = v end
local function getGrabRadius() return Steal.StealRadius end
local function setGrabRadius(v) Steal.StealRadius = v end

local function resetProgressBar()
	-- wired up to the GUI fill bar below
end

local function isMyPlot(plotName)
	local ct = tick()
	if Steal.plotCache[plotName] and (ct - (Steal.plotCacheTime[plotName] or 0)) < PLOT_CACHE_DURATION then
		return Steal.plotCache[plotName]
	end
	local plots = workspace:FindFirstChild("Plots")
	if not plots then Steal.plotCache[plotName] = false; Steal.plotCacheTime[plotName] = ct; return false end
	local plot = plots:FindFirstChild(plotName)
	if not plot then Steal.plotCache[plotName] = false; Steal.plotCacheTime[plotName] = ct; return false end
	local sign = plot:FindFirstChild("PlotSign")
	if sign then
		local yb = sign:FindFirstChild("YourBase")
		if yb and yb:IsA("BillboardGui") then
			local r = yb.Enabled == true
			Steal.plotCache[plotName] = r; Steal.plotCacheTime[plotName] = ct; return r
		end
	end
	Steal.plotCache[plotName] = false; Steal.plotCacheTime[plotName] = ct; return false
end

local function findNearestPrompt()
	local char = LP.Character; if not char then return nil end
	local root = char:FindFirstChild("HumanoidRootPart"); if not root then return nil end
	local ct = tick()
	if ct - Steal.promptCacheTime < PROMPT_CACHE_REFRESH and #Steal.cachedPrompts > 0 then
		local np, nd = nil, math.huge
		for _, data in ipairs(Steal.cachedPrompts) do
			if data.spawn then
				local dist = (data.spawn.Position - root.Position).Magnitude
				if dist <= Steal.StealRadius and dist < nd then
					np = data.prompt; nd = dist
				end
			end
		end
		if np then return np end
	end
	Steal.cachedPrompts = {}; Steal.promptCacheTime = ct
	local plots = workspace:FindFirstChild("Plots"); if not plots then return nil end
	local np, nd = nil, math.huge
	for _, plot in ipairs(plots:GetChildren()) do
		if isMyPlot(plot.Name) then continue end
		local pods = plot:FindFirstChild("AnimalPodiums"); if not pods then continue end
		for _, pod in ipairs(pods:GetChildren()) do
			pcall(function()
				local base = pod:FindFirstChild("Base")
				local sp = base and base:FindFirstChild("Spawn")
				if sp then
					local att = sp:FindFirstChild("PromptAttachment")
					if att then
						for _, child in ipairs(att:GetChildren()) do
							if child:IsA("ProximityPrompt") then
								local dist = (sp.Position - root.Position).Magnitude
								table.insert(Steal.cachedPrompts, {prompt = child, spawn = sp, name = pod.Name})
								if dist <= Steal.StealRadius and dist < nd then
									np = child; nd = dist
								end
								break
							end
						end
					end
				end
			end)
		end
	end
	return np
end

local function executeSteal(prompt)
	local ct = tick()
	if ct - StealState.lastStealTick < STEAL_COOLDOWN then return end
	if StealState.isStealing then return end
	if not Steal.Data[prompt] then
		Steal.Data[prompt] = {hold = {}, trigger = {}, ready = true}
		pcall(function()
			if getconnections then
				for _, c in ipairs(getconnections(prompt.PromptButtonHoldBegan)) do
					if c.Function then table.insert(Steal.Data[prompt].hold, c.Function) end
				end
				for _, c in ipairs(getconnections(prompt.Triggered)) do
					if c.Function then table.insert(Steal.Data[prompt].trigger, c.Function) end
				end
			else
				Steal.Data[prompt].useFallback = true
			end
		end)
	end
	local data = Steal.Data[prompt]
	if not data.ready then return end
	data.ready = false; StealState.isStealing = true
	StealState.stealStartTime = ct; StealState.lastStealTick = ct
	if StealConns.progress then StealConns.progress:Disconnect() end
	StealConns.progress = RunService.Heartbeat:Connect(function()
		if not StealState.isStealing then StealConns.progress:Disconnect() end
		-- GUI progress bar is driven by the separate Heartbeat below
	end)
	task.spawn(function()
		local ok = false
		pcall(function()
			if not data.useFallback then
				for _, fn in ipairs(data.hold) do task.spawn(fn) end
				task.wait(Steal.StealDuration)
				for _, fn in ipairs(data.trigger) do task.spawn(fn) end
				ok = true
			end
		end)
		if not ok and fireproximityprompt then
			pcall(function() fireproximityprompt(prompt); ok = true end)
		end
		if not ok then
			pcall(function() prompt:InputHoldBegin(); task.wait(Steal.StealDuration); prompt:InputHoldEnd() end)
		end
		task.wait(Steal.StealDuration * 0.3)
		if StealConns.progress then StealConns.progress:Disconnect() end
		resetProgressBar()
		task.wait(0.05)
		data.ready = true; StealState.isStealing = false
	end)
end

local function startAutoSteal()
	if StealConns.autoSteal then return end
	Steal.AutoStealEnabled = true; autoGrabEnabled = true
	StealConns.autoSteal = RunService.Heartbeat:Connect(function()
		if not Steal.AutoStealEnabled or StealState.isStealing then return end
		local p = findNearestPrompt()
		if p then executeSteal(p) end
	end)
end

local function stopAutoSteal()
	if StealConns.autoSteal then StealConns.autoSteal:Disconnect(); StealConns.autoSteal = nil end
	Steal.AutoStealEnabled = false; autoGrabEnabled = false
	StealState.isStealing = false; StealState.lastStealTick = 0
	Steal.plotCache = {}; Steal.plotCacheTime = {}; Steal.cachedPrompts = {}
	resetProgressBar()
end
-- ===== END AUTO STEAL =====

-- No-clip others
RunService.Stepped:Connect(function()
	for _,p in ipairs(Players:GetPlayers()) do
		if p~=LP and p.Character then
			for _,part in ipairs(p.Character:GetDescendants()) do
				if part:IsA("BasePart") then part.CanCollide=false end
			end
		end
	end
end)

-- Movement
RunService.RenderStepped:Connect(function()
	local char=LP.Character; if not char then return end
	local hum=char:FindFirstChildOfClass("Humanoid")
	local hrp=char:FindFirstChild("HumanoidRootPart")
	if not hum or not hrp then return end
	local md=hum.MoveDirection
	local spd=speedMode and CS or NS
	if md.Magnitude>0 then hrp.AssemblyLinearVelocity=Vector3.new(md.X*spd,hrp.AssemblyLinearVelocity.Y,md.Z*spd) end
	if speedLabel then speedLabel.Text=string.format("Speed: %.1f",Vector3.new(hrp.AssemblyLinearVelocity.X,0,hrp.AssemblyLinearVelocity.Z).Magnitude) end
end)

-- Auto Play helpers
local function makeAutoPlay(getEnabled,setEnabled,getPhase,setPhase,getConn,setConn,getVisual,p1,p2,faceTgt)
	local function stop()
		local c=getConn(); if c then c:Disconnect(); setConn(nil) end
		setPhase(1)
		local char=LP.Character
		if char then local h=char:FindFirstChildOfClass("Humanoid"); if h then h:Move(Vector3.zero,false) end end
	end
	local function start()
		stop(); setPhase(1)
		setConn(RunService.Heartbeat:Connect(function()
			if not getEnabled() then return end
			local char=LP.Character; if not char then return end
			local hrp=char:FindFirstChild("HumanoidRootPart")
			local hum=char:FindFirstChildOfClass("Humanoid")
			if not hrp or not hum then return end
			local tgt=getPhase()==1 and p1 or p2
			local flat=Vector3.new(tgt.X,hrp.Position.Y,tgt.Z)
			if (flat-hrp.Position).Magnitude<1 then
				if getPhase()==2 then
					hum:Move(Vector3.zero,false); hrp.AssemblyLinearVelocity=Vector3.zero
					setEnabled(false); stop()
					local v=getVisual(); if v then v(false) end
					if faceTgt then
						local dir=Vector3.new(faceTgt.X,hrp.Position.Y,faceTgt.Z)-hrp.Position
						if dir.Magnitude>0.01 then hrp.CFrame=CFrame.new(hrp.Position,hrp.Position+dir.Unit) end
					end
					return
				end
				setPhase(2); return
			end
			local d=tgt-hrp.Position
			local mv=Vector3.new(d.X,0,d.Z).Unit
			hum:Move(mv,false)
			hrp.AssemblyLinearVelocity=Vector3.new(mv.X*NS,hrp.AssemblyLinearVelocity.Y,mv.Z*NS)
		end))
	end
	return start,stop
end

local alConn,arConn=nil,nil
local alPhase,arPhase=1,1
local startAutoLeft,stopAutoLeft=makeAutoPlay(
	function() return autoLeftEnabled end,function(v) autoLeftEnabled=v end,
	function() return alPhase end,function(v) alPhase=v end,
	function() return alConn end,function(v) alConn=v end,
	function() return autoLeftSetVisual end,AP_L1,AP_L2,Vector3.new(-482.25,-4.96,92.09))
local startAutoRight,stopAutoRight=makeAutoPlay(
	function() return autoRightEnabled end,function(v) autoRightEnabled=v end,
	function() return arPhase end,function(v) arPhase=v end,
	function() return arConn end,function(v) arConn=v end,
	function() return autoRightSetVisual end,AP_R1,AP_R2,Vector3.new(-482.06,-6.93,35.47))

-- Speed indicator
local function setupSpeedIndicator(char)
	local head=char:WaitForChild("Head",5); if not head then return end
	local bb=Instance.new("BillboardGui",head)
	bb.Size=UDim2.new(0,120,0,25); bb.StudsOffset=Vector3.new(0,3,0); bb.AlwaysOnTop=true
	speedLabel=Instance.new("TextLabel",bb)
	speedLabel.Size=UDim2.new(1,0,1,0); speedLabel.BackgroundTransparency=1
	speedLabel.Text="Speed: 0"; speedLabel.TextColor3=Color3.fromRGB(147,112,219)
	speedLabel.Font=Enum.Font.GothamBold; speedLabel.TextScaled=true
end

-- Anti Ragdoll
RunService.Heartbeat:Connect(function()
	if not antiRagdollEnabled then return end
	local char=LP.Character; if not char then return end
	local hum=char:FindFirstChildOfClass("Humanoid")
	local root=char:FindFirstChild("HumanoidRootPart")
	if hum then
		local st=hum:GetState()
		if st==Enum.HumanoidStateType.Physics or st==Enum.HumanoidStateType.Ragdoll or st==Enum.HumanoidStateType.FallingDown then
			hum:ChangeState(Enum.HumanoidStateType.Running)
			workspace.CurrentCamera.CameraSubject=hum
			pcall(function()
				local pm=LP.PlayerScripts:FindFirstChild("PlayerModule")
				if pm then require(pm:FindFirstChild("ControlModule")):Enable() end
			end)
			if root then root.Velocity=Vector3.zero; root.RotVelocity=Vector3.zero end
		end
	end
	for _,obj in ipairs(char:GetDescendants()) do
		if obj:IsA("Motor6D") and not obj.Enabled then obj.Enabled=true end
	end
end)

-- Infinite Jump
local IJ_JumpConn,IJ_FallConn=nil,nil
local function startInfiniteJump()
	if IJ_JumpConn then IJ_JumpConn:Disconnect() end
	if IJ_FallConn then IJ_FallConn:Disconnect() end
	IJ_JumpConn=UIS.JumpRequest:Connect(function()
		if not infJumpEnabled then return end
		local char=LP.Character; if not char then return end
		local root=char:FindFirstChild("HumanoidRootPart")
		if root then root.Velocity=Vector3.new(root.Velocity.X,55,root.Velocity.Z) end
	end)
	IJ_FallConn=RunService.Heartbeat:Connect(function()
		if not infJumpEnabled then return end
		local char=LP.Character; if not char then return end
		local root=char:FindFirstChild("HumanoidRootPart")
		if root and root.Velocity.Y<-120 then root.Velocity=Vector3.new(root.Velocity.X,-120,root.Velocity.Z) end
	end)
end
local function stopInfiniteJump()
	if IJ_JumpConn then IJ_JumpConn:Disconnect(); IJ_JumpConn=nil end
	if IJ_FallConn then IJ_FallConn:Disconnect(); IJ_FallConn=nil end
end

-- Unwalk
local function disableAnimations()
	local char=LP.Character; if not char then return end
	local hum=char:FindFirstChildOfClass("Humanoid")
	if not hum then return end
	for _,track in pairs(unwalkAnimations) do pcall(function() track:Stop() end) end
	unwalkAnimations={}
	local animator=hum:FindFirstChildOfClass("Animator")
	if animator then
		for _,track in pairs(animator:GetPlayingAnimationTracks()) do
			track:Stop(); table.insert(unwalkAnimations,track)
		end
	end
end

local function enableAnimations()
	local char=LP.Character; if not char then return end
	unwalkAnimations={}
end

RunService.Heartbeat:Connect(function()
	if not unwalkEnabled then return end
	disableAnimations()
end)

-- 3-STEP TP LOGIC
local function doTeleport(p1,p2,p3,faceDir)
	if brainrotCooldown then return end
	brainrotCooldown=true
	task.spawn(function()
		local char=LP.Character; if not char then brainrotCooldown=false; return end
		local hrp=char:FindFirstChild("HumanoidRootPart")
		local hum=char:FindFirstChildOfClass("Humanoid")
		if not hrp then brainrotCooldown=false; return end
		hrp.AssemblyLinearVelocity=Vector3.zero
		hrp.CFrame=CFrame.new(p1+Vector3.new(0,3,0))
		if hum then hum:ChangeState(Enum.HumanoidStateType.Running) end
		task.wait(0.1)
		hrp.AssemblyLinearVelocity=Vector3.zero
		hrp.CFrame=CFrame.new(p2+Vector3.new(0,3,0))
		if hum then hum:ChangeState(Enum.HumanoidStateType.Running) end
		task.wait(0.1)
		hrp.AssemblyLinearVelocity=Vector3.zero
		hrp.CFrame=CFrame.new(p3+Vector3.new(0,3,0))
		if hum then hum:ChangeState(Enum.HumanoidStateType.Running) end
		if faceDir then
			task.wait(0.05)
			local dir=(faceDir-hrp.Position)
			if dir.Magnitude>0.01 then
				hrp.CFrame=CFrame.new(hrp.Position,Vector3.new(faceDir.X,hrp.Position.Y,faceDir.Z))
			end
		end
		task.wait(0.6)
		brainrotCooldown=false
	end)
end

RunService.Heartbeat:Connect(function()
	if not(brainrotLeftEnabled or brainrotRightEnabled) or brainrotCooldown then return end
	local char=LP.Character; if not char then return end
	local hum=char:FindFirstChildOfClass("Humanoid"); if not hum then return end
	local hp=hum.Health
	local st=hum:GetState()
	local hit=hp<lastHealth-1
	local rag=st==Enum.HumanoidStateType.Physics or st==Enum.HumanoidStateType.Ragdoll or st==Enum.HumanoidStateType.FallingDown
	lastHealth=hp
	if hit or rag then
		if brainrotLeftEnabled then
			doTeleport(BR_L1,BR_L2,BR_L3,Vector3.new(-476,-4,99))
		elseif brainrotRightEnabled then
			doTeleport(BR_R1,BR_R2,BR_R3,Vector3.new(-476,-4,20))
		end
	end
end)

-- Drop Brainrot
local function runDrop()
	if dropActive then return end
	local char=LP.Character; if not char then return end
	local hrp=char:FindFirstChild("HumanoidRootPart"); if not hrp then return end
	dropActive=true; local t0=tick()
	local conn; conn=RunService.Heartbeat:Connect(function()
		local r=char and char:FindFirstChild("HumanoidRootPart")
		if not r then conn:Disconnect(); dropActive=false; return end
		if tick()-t0>=DAD then
			conn:Disconnect()
			local rp=RaycastParams.new()
			rp.FilterDescendantsInstances={char}; rp.FilterType=Enum.RaycastFilterType.Exclude
			local rr=workspace:Raycast(r.Position,Vector3.new(0,-2000,0),rp)
			if rr then
				local hum2=char:FindFirstChildOfClass("Humanoid")
				local off=(hum2 and hum2.HipHeight or 2)+(r.Size.Y/2)
				r.CFrame=CFrame.new(r.Position.X,rr.Position.Y+off,r.Position.Z)
				r.AssemblyLinearVelocity=Vector3.zero
			end
			dropActive=false; return
		end
		r.AssemblyLinearVelocity=Vector3.new(r.AssemblyLinearVelocity.X,DAS,r.AssemblyLinearVelocity.Z)
	end)
end

-- TP to Floor (instant raycast snap to ground)
local function runTPFloor()
	pcall(function()
		local char=LP.Character; if not char then return end
		local hum=char:FindFirstChildOfClass("Humanoid"); if not hum then return end
		local hrp=char:FindFirstChild("HumanoidRootPart"); if not hrp then return end
		local rp=RaycastParams.new()
		rp.FilterDescendantsInstances={char}
		rp.FilterType=Enum.RaycastFilterType.Exclude
		local rs=workspace:Raycast(hrp.Position,Vector3.new(0,-500,0),rp)
		if rs then
			hrp.CFrame=CFrame.new(hrp.Position.X, rs.Position.Y+hrp.Size.Y/2+0.1, hrp.Position.Z)
			hrp.AssemblyLinearVelocity=Vector3.zero
		end
	end)
end

-- ANTI LAG
local function applyAntiLag(ultra)
	Lighting.GlobalShadows=false
	Lighting.FogEnd=1e10
	Lighting.Brightness=1
	Lighting.EnvironmentDiffuseScale=0
	Lighting.EnvironmentSpecularScale=0
	for _,e in pairs(Lighting:GetChildren()) do
		if e:IsA("BlurEffect") or e:IsA("SunRaysEffect") or e:IsA("ColorCorrectionEffect") or e:IsA("BloomEffect") or e:IsA("DepthOfFieldEffect") then
			e.Enabled=false
		end
	end
	for _,obj in pairs(workspace:GetDescendants()) do
		if obj:IsA("BasePart") then
			obj.Material=Enum.Material.Plastic
			obj.Reflectance=0
			if ultra then obj.CastShadow=false end
		elseif obj:IsA("Decal") or obj:IsA("Texture") then
			if ultra then obj:Destroy() else obj.Transparency=1 end
		elseif ultra and (obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") or obj:IsA("Fire")) then
			obj.Enabled=false
		end
	end
	if ultra then
		pcall(function() RunService:Set3dRenderingEnabled(true); settings().Rendering.QualityLevel=Enum.QualityLevel.Level01 end)
	end
end

local function enableAntiLag()
	if antiLagEnabled then return end
	antiLagEnabled=true
	applyAntiLag(false)
	descendantConnection=workspace.DescendantAdded:Connect(function(obj)
		if obj:IsA("BasePart") then obj.Material=Enum.Material.Plastic; obj.Reflectance=0
		elseif obj:IsA("Decal") or obj:IsA("Texture") then obj.Transparency=1 end
	end)
end

local function disableAntiLag()
	antiLagEnabled=false
	if descendantConnection then descendantConnection:Disconnect(); descendantConnection=nil end
end

local function enableUltraMode()
	ultraModeEnabled=true
	applyAntiLag(true)
end

local function disableUltraMode()
	ultraModeEnabled=false
end

-- Remove Accessories
local function enableRemoveAccessories()
	removeAccessoriesEnabled=true
	for _,p in pairs(Players:GetPlayers()) do
		if p.Character then
			for _,obj in ipairs(p.Character:GetDescendants()) do
				if obj:IsA("Accessory") or obj:IsA("Hat") then obj:Destroy() end
			end
		end
	end
	if not accessoryConnection then
		accessoryConnection=Players.PlayerAdded:Connect(function(player)
			player.CharacterAdded:Connect(function(char)
				task.wait(0.5)
				if not removeAccessoriesEnabled then return end
				for _,obj in ipairs(char:GetDescendants()) do
					if obj:IsA("Accessory") or obj:IsA("Hat") then obj:Destroy() end
				end
			end)
		end)
	end
end

local function disableRemoveAccessories()
	removeAccessoriesEnabled=false
	if accessoryConnection then accessoryConnection:Disconnect(); accessoryConnection=nil end
end

-- Medusa Counter
local function findMedusa()
	local char=LP.Character; if not char then return nil end
	for _,t in ipairs(char:GetChildren()) do if t:IsA("Tool") and t.Name:lower():find("medusa") then return t end end
	local bp=LP:FindFirstChild("Backpack")
	if bp then for _,t in ipairs(bp:GetChildren()) do if t:IsA("Tool") and t.Name:lower():find("medusa") then return t end end end
end

local function useMedusa()
	if medusaDebounce or tick()-medusaLastUsed<25 then return end
	local char=LP.Character; if not char then return end
	medusaDebounce=true
	local med=findMedusa()
	if med then
		if med.Parent~=char then local h=char:FindFirstChildOfClass("Humanoid"); if h then h:EquipTool(med) end end
		pcall(function() med:Activate() end)
		medusaLastUsed=tick()
	end
	medusaDebounce=false
end

local function setupMedusa(char)
	for _,c in pairs(medusaConns) do pcall(function() c:Disconnect() end) end
	medusaConns={}
	if not char then return end
	local function onAnchor(part)
		return part:GetPropertyChangedSignal("Anchored"):Connect(function()
			if medusaCounterEnabled and part.Anchored and part.Transparency==1 then useMedusa() end
		end)
	end
	for _,part in ipairs(char:GetDescendants()) do
		if part:IsA("BasePart") then table.insert(medusaConns,onAnchor(part)) end
	end
	table.insert(medusaConns,char.DescendantAdded:Connect(function(part)
		if part:IsA("BasePart") then table.insert(medusaConns,onAnchor(part)) end
	end))
end

LP.CharacterAdded:Connect(function(char)
	lastHealth=100; task.wait(0.5)
	setupSpeedIndicator(char)
	if medusaCounterEnabled then setupMedusa(char) end
	unwalkAnimations={}
	if unwalkEnabled then task.wait(0.5); disableAnimations() end
end)
if LP.Character then setupSpeedIndicator(LP.Character) end

-- BAT AIMBOT LOGIC
local function getClosestPlayer()
	local char=LP.Character; if not char then return nil,math.huge end
	local hrp=char:FindFirstChild("HumanoidRootPart"); if not hrp then return nil,math.huge end
	local cp,cd=nil,math.huge
	for _,p in pairs(Players:GetPlayers()) do
		if p~=LP and p.Character then
			local tr=p.Character:FindFirstChild("HumanoidRootPart")
			if tr then local d=(hrp.Position-tr.Position).Magnitude; if d<cd then cd=d; cp=p end end
		end
	end
	return cp,cd
end

local function getBat()
	local char=LP.Character; if not char then return nil end
	local tool=char:FindFirstChild("Bat"); if tool then return tool end
	local bp=LP:FindFirstChild("Backpack")
	if bp then tool=bp:FindFirstChild("Bat"); if tool then tool.Parent=char; return tool end end
	return nil
end

local function tryHitBat()
	if batHittingCooldown then return end; batHittingCooldown=true
	pcall(function()
		local bat=getBat(); if bat then
			bat:Activate()
			local ev=bat:FindFirstChildWhichIsA("RemoteEvent")
			if ev then ev:FireServer() end
		end
	end)
	task.delay(0.08, function() batHittingCooldown=false end)
end

RunService.Heartbeat:Connect(function()
	if not autoBatEnabled then return end
	local char=LP.Character; if not char then return end
	local hrp=char:FindFirstChild("HumanoidRootPart"); if not hrp then return end
	local target,_=getClosestPlayer()
	if target and target.Character then
		local tr=target.Character:FindFirstChild("HumanoidRootPart")
		if tr then
			local fp=tr.Position+tr.CFrame.LookVector*1.5
			local dir=(fp-hrp.Position).Unit
			hrp.AssemblyLinearVelocity=Vector3.new(dir.X*56.5,dir.Y*56.5,dir.Z*56.5)
		end
	end
end)

-- ===== GUI =====
local C_BG=Color3.fromRGB(255,255,255)
local C_CARD=Color3.fromRGB(40,40,50)
local C_PURPLE=Color3.fromRGB(147,112,219)
local C_WHITE=Color3.fromRGB(255,255,255)
local C_RED=Color3.fromRGB(220,60,85)
local C_GREEN=Color3.fromRGB(60,180,80)

local gui=Instance.new("ScreenGui")
gui.Name="RelicHub"; gui.ResetOnSpawn=false; gui.DisplayOrder=10
gui.Parent=LP:WaitForChild("PlayerGui")

local main=Instance.new("Frame"); main.Size=UDim2.new(0,200,0,500)
main.Position=UDim2.new(0,20,0,130); main.BackgroundColor3=C_BG
main.BorderSizePixel=0; main.ClipsDescendants=true; main.Parent=gui
Instance.new("UICorner",main).CornerRadius=UDim.new(0,8)

local function makeDraggable(frame)
	local drag,ds,sp=false
	frame.InputBegan:Connect(function(inp)
		if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then
			drag=true; ds=inp.Position; sp=frame.Position
			inp.Changed:Connect(function() if inp.UserInputState==Enum.UserInputState.End then drag=false end end)
		end
	end)
	UIS.InputChanged:Connect(function(inp)
		if drag and (inp.UserInputType==Enum.UserInputType.MouseMovement or inp.UserInputType==Enum.UserInputType.Touch) then
			local d=inp.Position-ds
			frame.Position=UDim2.new(sp.X.Scale,sp.X.Offset+d.X,sp.Y.Scale,sp.Y.Offset+d.Y)
		end
	end)
end
makeDraggable(main)

local title=Instance.new("TextLabel",main)
title.Size=UDim2.new(1,-40,0,30); title.Position=UDim2.new(0,5,0,5)
title.BackgroundTransparency=1; title.Text="RELIC HUB"; title.TextColor3=C_PURPLE
title.Font=Enum.Font.GothamBold; title.TextSize=16

local close=Instance.new("TextButton",main)
close.Size=UDim2.new(0,30,0,30); close.Position=UDim2.new(1,-35,0,5)
close.BackgroundColor3=C_RED; close.BorderSizePixel=0
close.Text="X"; close.TextColor3=C_WHITE; close.Font=Enum.Font.GothamBold; close.TextSize=18
Instance.new("UICorner",close).CornerRadius=UDim.new(0,6)
close.MouseButton1Click:Connect(function() main.Visible=false end)

local scrollFrame=Instance.new("ScrollingFrame",main)
scrollFrame.Size=UDim2.new(1,0,1,-40); scrollFrame.Position=UDim2.new(0,0,0,40)
scrollFrame.BackgroundTransparency=1; scrollFrame.BorderSizePixel=0
scrollFrame.ScrollBarThickness=4; scrollFrame.ScrollBarImageColor3=C_PURPLE
scrollFrame.CanvasSize=UDim2.new(0,0,0,0); scrollFrame.AutomaticCanvasSize=Enum.AutomaticSize.Y

local function getKeyName(kc) return kc.Name end

local yPos=5

local function makeToggle(text,keybindName,callback)
	local btn=Instance.new("TextButton",scrollFrame)
	btn.Size=UDim2.new(1,-20,0,25); btn.Position=UDim2.new(0,10,0,yPos)
	btn.BackgroundColor3=C_CARD; btn.BorderSizePixel=0; btn.Text=""
	btn.TextColor3=C_WHITE; btn.Font=Enum.Font.Gotham; btn.TextSize=12
	Instance.new("UICorner",btn).CornerRadius=UDim.new(0,5)
	local xOff=5; local badge=nil
	if keybindName then
		badge=Instance.new("TextLabel",btn)
		badge.Size=UDim2.new(0,25,0,18); badge.Position=UDim2.new(0,5,0.5,-9)
		badge.BackgroundColor3=C_PURPLE; badge.BackgroundTransparency=0.3; badge.BorderSizePixel=0
		badge.Text=getKeyName(KB[keybindName]); badge.TextColor3=C_WHITE
		badge.Font=Enum.Font.GothamBold; badge.TextSize=9
		Instance.new("UICorner",badge).CornerRadius=UDim.new(0,4)
		xOff=35
	end
	local label=Instance.new("TextLabel",btn)
	label.Size=UDim2.new(1,-xOff-5,1,0); label.Position=UDim2.new(0,xOff,0,0)
	label.BackgroundTransparency=1; label.Text=text; label.TextColor3=C_WHITE
	label.Font=Enum.Font.Gotham; label.TextSize=12; label.TextXAlignment=Enum.TextXAlignment.Left
	local active=false
	local function setVisual(s) active=s; btn.BackgroundColor3=s and C_PURPLE or C_CARD end
	btn.MouseButton1Click:Connect(function()
		if waitingForKey then return end
		active=not active; setVisual(active); callback(active)
	end)
	if keybindName then
		btn.MouseButton2Click:Connect(function()
			waitingForKey=keybindName
			if badge then badge.Text="..."; badge.BackgroundColor3=Color3.fromRGB(255,180,100) end
		end)
	end
	yPos=yPos+30; return setVisual,btn
end

local function makeSimpleToggle(text,callback)
	local btn=Instance.new("TextButton",scrollFrame)
	btn.Size=UDim2.new(1,-20,0,25); btn.Position=UDim2.new(0,10,0,yPos)
	btn.BackgroundColor3=C_CARD; btn.BorderSizePixel=0; btn.Text=text
	btn.TextColor3=C_WHITE; btn.Font=Enum.Font.Gotham; btn.TextSize=12
	Instance.new("UICorner",btn).CornerRadius=UDim.new(0,5)
	local active=false
	btn.MouseButton1Click:Connect(function()
		active=not active; btn.BackgroundColor3=active and C_PURPLE or C_CARD; callback(active)
	end)
	yPos=yPos+30; return btn
end

local function makeDropdownBtn(text,keybindName)
	local container=Instance.new("Frame",scrollFrame)
	container.Size=UDim2.new(1,-20,0,25); container.Position=UDim2.new(0,10,0,yPos)
	container.BackgroundTransparency=1; container.ClipsDescendants=false
	local btn=Instance.new("TextButton",container)
	btn.Size=UDim2.new(1,0,0,25); btn.BackgroundColor3=C_CARD; btn.BorderSizePixel=0
	btn.Text=""; btn.ZIndex=3
	Instance.new("UICorner",btn).CornerRadius=UDim.new(0,5)
	local badge=nil
	if keybindName then
		badge=Instance.new("TextLabel",btn)
		badge.Size=UDim2.new(0,25,0,18); badge.Position=UDim2.new(0,5,0.5,-9)
		badge.BackgroundColor3=C_PURPLE; badge.BackgroundTransparency=0.3; badge.BorderSizePixel=0
		badge.Text=getKeyName(KB[keybindName]); badge.TextColor3=C_WHITE
		badge.Font=Enum.Font.GothamBold; badge.TextSize=9; badge.ZIndex=4
		Instance.new("UICorner",badge).CornerRadius=UDim.new(0,4)
	end
	local lbl=Instance.new("TextLabel",btn)
	lbl.Size=UDim2.new(1,keybindName and -35 or -10,1,0)
	lbl.Position=UDim2.new(0,keybindName and 35 or 5,0,0)
	lbl.BackgroundTransparency=1; lbl.Text=text; lbl.TextColor3=C_WHITE
	lbl.Font=Enum.Font.Gotham; lbl.TextSize=12; lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.ZIndex=4
	local dd=Instance.new("Frame",container)
	dd.Size=UDim2.new(1,0,0,0); dd.Position=UDim2.new(0,0,0,30)
	dd.BackgroundColor3=Color3.fromRGB(30,30,35); dd.BorderSizePixel=0
	dd.Visible=false; dd.ClipsDescendants=true; dd.ZIndex=100
	Instance.new("UICorner",dd).CornerRadius=UDim.new(0,5)
	yPos=yPos+30
	return container,btn,badge,dd
end

local function makeInput(parent,labelText,defaultVal,yOff,onChanged)
	local lbl=Instance.new("TextLabel",parent)
	lbl.Size=UDim2.new(0.6,0,0,30); lbl.Position=UDim2.new(0,5,0,yOff)
	lbl.BackgroundTransparency=1; lbl.Text=labelText; lbl.TextColor3=C_WHITE
	lbl.Font=Enum.Font.Gotham; lbl.TextSize=11; lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.ZIndex=101
	local tb=Instance.new("TextBox",parent)
	tb.Size=UDim2.new(0,50,0,22); tb.Position=UDim2.new(1,-55,0,yOff+9)
	tb.BackgroundColor3=C_CARD; tb.BorderSizePixel=0; tb.Text=tostring(defaultVal)
	tb.TextColor3=C_WHITE; tb.Font=Enum.Font.GothamBold; tb.TextSize=11; tb.ZIndex=101
	Instance.new("UICorner",tb).CornerRadius=UDim.new(0,4)
	tb.FocusLost:Connect(function() onChanged(tb) end)
	return tb
end

local function makeToggleDropdown(ddFrame,container,closedH,openH,holdFn)
	local open=false
	local function toggle()
		open=not open; ddFrame.Visible=true
		TS:Create(ddFrame,TweenInfo.new(0.2),{Size=open and UDim2.new(1,0,0,openH) or UDim2.new(1,0,0,0)}):Play()
		TS:Create(container,TweenInfo.new(0.2),{Size=open and UDim2.new(1,-20,0,closedH+openH+5) or UDim2.new(1,-20,0,closedH)}):Play()
		if not open then task.delay(0.2,function() if not open then ddFrame.Visible=false end end) end
	end
	return toggle,function() return open end
end

-- Auto Steal
local autoStealContainer,autoStealBtn,_,autoStealDD=makeDropdownBtn("Auto Steal",nil)
autoStealBtn.Text="Auto Steal"
local durationInput=makeInput(autoStealDD,"Steal Duration:",Steal.StealDuration,5,function(tb)
	local n=tonumber(tb.Text)
	if n then Steal.StealDuration=math.clamp(n,0.05,5); tb.Text=string.format("%.2f",Steal.StealDuration) end
end)
local toggleAutoStealDD,_=makeToggleDropdown(autoStealDD,autoStealContainer,25,40,nil)
local asHolding,asHoldTime=false,0
autoStealBtn.MouseButton1Click:Connect(function()
	if not asHolding then
		if Steal.AutoStealEnabled then
			stopAutoSteal()
			autoStealBtn.BackgroundColor3=C_CARD
		else
			startAutoSteal()
			autoStealBtn.BackgroundColor3=C_PURPLE
		end
	end
	asHolding=false; asHoldTime=0
end)
autoStealBtn.MouseButton2Click:Connect(toggleAutoStealDD)
autoStealBtn.MouseButton1Down:Connect(function() asHolding=false; asHoldTime=tick()
	task.delay(0.5,function() if asHoldTime>0 and(tick()-asHoldTime)>=0.5 then asHolding=true; toggleAutoStealDD() end end)
end)
autoStealBtn.MouseButton1Up:Connect(function() if(tick()-asHoldTime)<0.5 then asHoldTime=0 end end)

-- Carry Mode
local carryModeContainer,carryModeBtn,carryBadge,carryDropdown=makeDropdownBtn("Carry Mode","SpeedToggle")
local normalSpeedInput=makeInput(carryDropdown,"Normal Speed:",NS,5,function(tb)
	local n=tonumber(tb.Text); if n then NS=math.clamp(n,1,9999); tb.Text=tostring(NS); saveConfig() end
end)
local carrySpeedInput=makeInput(carryDropdown,"Carry Speed:",CS,40,function(tb)
	local n=tonumber(tb.Text); if n then CS=math.clamp(n,1,9999); tb.Text=tostring(CS); saveConfig() end
end)
local toggleCarryDD,_=makeToggleDropdown(carryDropdown,carryModeContainer,25,75,nil)
local cmHolding,cmHoldTime=false,0

speedBtn=function(state) speedMode=state; carryModeBtn.BackgroundColor3=state and C_PURPLE or C_CARD end

carryModeBtn.MouseButton1Click:Connect(function()
	if not cmHolding then speedMode=not speedMode; speedBtn(speedMode) end
	cmHolding=false; cmHoldTime=0
end)
carryModeBtn.MouseButton2Click:Connect(function()
	waitingForKey="SpeedToggle"; carryBadge.Text="..."; carryBadge.BackgroundColor3=Color3.fromRGB(255,180,100)
end)
carryModeBtn.MouseButton1Down:Connect(function() cmHolding=false; cmHoldTime=tick()
	task.delay(0.5,function() if cmHoldTime>0 and(tick()-cmHoldTime)>=0.5 then cmHolding=true; toggleCarryDD() end end)
end)
carryModeBtn.MouseButton1Up:Connect(function() if(tick()-cmHoldTime)<0.5 then cmHoldTime=0 end end)

-- Simple toggles
makeSimpleToggle("Anti Ragdoll",function(on) antiRagdollEnabled=on end)
makeSimpleToggle("Infinite Jump",function(on) infJumpEnabled=on; if on then startInfiniteJump() else stopInfiniteJump() end end)
makeSimpleToggle("Medusa Counter",function(on)
	medusaCounterEnabled=on
	if on then setupMedusa(LP.Character) else for _,c in pairs(medusaConns) do pcall(function() c:Disconnect() end) end; medusaConns={} end
end)

local unwalkSetVisual=makeToggle("Unwalk","Unwalk",function(on)
	unwalkEnabled=on
	if on then disableAnimations() else enableAnimations() end
end)

local brainrotLeftBtn=makeToggle("TP Left","TPLeft",function(on)
	if on and brainrotRightEnabled then brainrotRightEnabled=false; if brainrotRightBtn then brainrotRightBtn(false) end end
	brainrotLeftEnabled=on
end)

local brainrotRightBtn=makeToggle("TP Right","TPRight",function(on)
	if on and brainrotLeftEnabled then brainrotLeftEnabled=false; if brainrotLeftBtn then brainrotLeftBtn(false) end end
	brainrotRightEnabled=on
end)

makeToggle("Drop Brainrot","DropBrainrot",function(on) if on then runDrop() end end)

local tpFloorSetVisual=makeToggle("TP to Floor","TPFloor",function(on)
	runTPFloor()
	task.delay(0.25,function() if tpFloorSetVisual then tpFloorSetVisual(false) end end)
end)

local alVis=makeToggle("Auto Left","AutoLeft",function(on)
	autoLeftEnabled=on; if on then startAutoLeft() else stopAutoLeft() end
end)
autoLeftSetVisual=alVis

local arVis=makeToggle("Auto Right","AutoRight",function(on)
	autoRightEnabled=on; if on then startAutoRight() else stopAutoRight() end
end)
autoRightSetVisual=arVis

local abVis,abBtn=makeToggle("Auto Bat","AutoBat",function(on)
	autoBatEnabled=on
end)
autoBatSetVisual=abVis

makeSimpleToggle("Anti Lag",function(on) if on then enableAntiLag() else disableAntiLag() end end)
makeSimpleToggle("Ultra Mode",function(on) if on then enableUltraMode() else disableUltraMode() end end)
makeSimpleToggle("Remove Accessories",function(on) if on then enableRemoveAccessories() else disableRemoveAccessories() end end)

-- Keybind listener
UIS.InputBegan:Connect(function(input,gpe)
	if gpe then return end
	if waitingForKey then
		local kc=input.KeyCode; if kc==Enum.KeyCode.Unknown then return end
		local orig=waitingForKey
		if kc==Enum.KeyCode.Escape then
			waitingForKey=nil
			if orig=="SpeedToggle" then carryBadge.Text=getKeyName(KB.SpeedToggle); carryBadge.BackgroundColor3=C_PURPLE; carryBadge.BackgroundTransparency=0.3 end
			return
		end
		KB[orig]=kc
		if orig=="SpeedToggle" then carryBadge.Text=getKeyName(kc); carryBadge.BackgroundColor3=C_PURPLE; carryBadge.BackgroundTransparency=0.3
		else
			for _,child in ipairs(scrollFrame:GetChildren()) do
				if child:IsA("TextButton") then
					for _,b in ipairs(child:GetChildren()) do
						if b:IsA("TextLabel") and b.Text=="..." then
							b.Text=getKeyName(kc); b.BackgroundColor3=C_PURPLE; b.BackgroundTransparency=0.3; break
						end
					end
				end
			end
		end
		waitingForKey=nil; saveConfig(); return
	end
	if input.UserInputType~=Enum.UserInputType.Keyboard then return end
	local kc=input.KeyCode
	if kc==KB.SpeedToggle then
		speedMode=not speedMode; if speedBtn then speedBtn(speedMode) end
	elseif kc==KB.DropBrainrot then runDrop()
	elseif kc==KB.TPFloor then
		runTPFloor()
		if tpFloorSetVisual then tpFloorSetVisual(true); task.delay(0.25,function() tpFloorSetVisual(false) end) end
	elseif kc==KB.AutoLeft then
		autoLeftEnabled=not autoLeftEnabled
		if autoLeftSetVisual then autoLeftSetVisual(autoLeftEnabled) end
		if autoLeftEnabled then startAutoLeft() else stopAutoLeft() end
	elseif kc==KB.AutoRight then
		autoRightEnabled=not autoRightEnabled
		if autoRightSetVisual then autoRightSetVisual(autoRightEnabled) end
		if autoRightEnabled then startAutoRight() else stopAutoRight() end
	elseif kc==KB.AutoBat then
		autoBatEnabled=not autoBatEnabled
		if autoBatSetVisual then autoBatSetVisual(autoBatEnabled) end
	elseif kc==KB.Unwalk then
		unwalkEnabled=not unwalkEnabled
		if unwalkSetVisual then unwalkSetVisual(unwalkEnabled) end
	elseif kc==KB.TPLeft then
		brainrotLeftEnabled=not brainrotLeftEnabled
		if brainrotLeftBtn then brainrotLeftBtn(brainrotLeftEnabled) end
		if brainrotLeftEnabled and brainrotRightEnabled then brainrotRightEnabled=false; if brainrotRightBtn then brainrotRightBtn(false) end end
	elseif kc==KB.TPRight then
		brainrotRightEnabled=not brainrotRightEnabled
		if brainrotRightBtn then brainrotRightBtn(brainrotRightEnabled) end
		if brainrotRightEnabled and brainrotLeftEnabled then brainrotLeftEnabled=false; if brainrotLeftBtn then brainrotLeftBtn(false) end end
	end
end)

-- ===== PROGRESS BAR =====
local C_ACCENT=Color3.fromRGB(220,220,220)
local C_ACCENT2=Color3.fromRGB(160,160,160)
local C_PANEL=Color3.fromRGB(18,18,18)
local C_BORDER2=Color3.fromRGB(60,60,60)
local C_KEY_BG=Color3.fromRGB(28,28,28)
local C_ROW=Color3.fromRGB(24,24,24)
local C_ROW_HOV=Color3.fromRGB(32,32,32)

local pbFrame=Instance.new("Frame",gui)
pbFrame.Size=UDim2.new(0,270,0,52); pbFrame.Position=UDim2.new(0,20,0,694)
pbFrame.BackgroundColor3=C_PANEL; pbFrame.BorderSizePixel=0; pbFrame.Active=true
Instance.new("UICorner",pbFrame).CornerRadius=UDim.new(0,8)
Instance.new("UIStroke",pbFrame).Color=C_BORDER2
makeDraggable(pbFrame)

local progressPct=Instance.new("TextLabel",pbFrame)
progressPct.Size=UDim2.new(0,50,0,18); progressPct.Position=UDim2.new(0,10,0,6)
progressPct.BackgroundTransparency=1; progressPct.Text="0%"; progressPct.TextColor3=C_ACCENT2
progressPct.Font=Enum.Font.GothamBold; progressPct.TextSize=12; progressPct.TextXAlignment=Enum.TextXAlignment.Left

local progressRadLbl=Instance.new("TextLabel",pbFrame)
progressRadLbl.Size=UDim2.new(0,110,0,18); progressRadLbl.Position=UDim2.new(1,-115,0,6)
progressRadLbl.BackgroundTransparency=1; progressRadLbl.Text="Radius: "..Steal.StealRadius; progressRadLbl.TextColor3=C_ACCENT2
progressRadLbl.Font=Enum.Font.GothamBold; progressRadLbl.TextSize=12; progressRadLbl.TextXAlignment=Enum.TextXAlignment.Right

local progressBg=Instance.new("Frame",pbFrame)
progressBg.Size=UDim2.new(1,-20,0,16); progressBg.Position=UDim2.new(0,10,0,28)
progressBg.BackgroundColor3=C_ROW; progressBg.BorderSizePixel=0
Instance.new("UICorner",progressBg).CornerRadius=UDim.new(1,0)

local progressFill=Instance.new("Frame",progressBg)
progressFill.Size=UDim2.new(0,0,1,0); progressFill.BackgroundColor3=C_ACCENT
progressFill.BorderSizePixel=0
Instance.new("UICorner",progressFill).CornerRadius=UDim.new(1,0)

-- Wire resetProgressBar to the actual fill bar
resetProgressBar = function()
	progressFill.Size=UDim2.new(0,0,1,0); progressPct.Text="0%"
end

local radiusFrame=Instance.new("Frame",gui)
radiusFrame.Size=UDim2.new(0,270,0,44); radiusFrame.Position=UDim2.new(0,20,0,640)
radiusFrame.BackgroundColor3=C_PANEL; radiusFrame.BorderSizePixel=0; radiusFrame.Active=true
Instance.new("UICorner",radiusFrame).CornerRadius=UDim.new(0,8)
Instance.new("UIStroke",radiusFrame).Color=C_BORDER2
makeDraggable(radiusFrame)

local radLbl=Instance.new("TextLabel",radiusFrame)
radLbl.Size=UDim2.new(0,130,1,0); radLbl.Position=UDim2.new(0,12,0,0)
radLbl.Text="Grab Radius"; radLbl.Font=Enum.Font.GothamBold; radLbl.TextSize=12
radLbl.TextColor3=C_ACCENT; radLbl.BackgroundTransparency=1; radLbl.TextXAlignment=Enum.TextXAlignment.Left

local radValBtn=Instance.new("TextButton",radiusFrame)
radValBtn.Size=UDim2.new(0,74,0,28); radValBtn.Position=UDim2.new(1,-82,0.5,-14)
radValBtn.BackgroundColor3=C_KEY_BG; radValBtn.BorderSizePixel=0
radValBtn.Text=tostring(Steal.StealRadius); radValBtn.TextColor3=C_ACCENT
radValBtn.Font=Enum.Font.GothamBlack; radValBtn.TextSize=15
Instance.new("UICorner",radValBtn).CornerRadius=UDim.new(0,5)
Instance.new("UIStroke",radValBtn).Color=C_BORDER2

local typing2=false
radValBtn.MouseButton1Click:Connect(function()
	if typing2 then return end; typing2=true
	local tb=Instance.new("TextBox",radiusFrame)
	tb.Size=radValBtn.Size; tb.Position=radValBtn.Position
	tb.BackgroundColor3=C_ROW_HOV; tb.BorderSizePixel=0; tb.Text=tostring(Steal.StealRadius)
	tb.TextColor3=C_WHITE; tb.Font=Enum.Font.GothamBlack; tb.TextSize=15; tb.ClearTextOnFocus=false
	Instance.new("UICorner",tb).CornerRadius=UDim.new(0,5)
	Instance.new("UIStroke",tb).Color=C_ACCENT2
	tb:CaptureFocus()
	tb.FocusLost:Connect(function()
		local num=tonumber(tb.Text)
		if num and num>=5 and num<=300 then
			Steal.StealRadius=math.floor(num)
			radValBtn.Text=tostring(Steal.StealRadius)
			progressRadLbl.Text="Radius: "..Steal.StealRadius
		end
		tb:Destroy(); typing2=false
	end)
end)

RunService.Heartbeat:Connect(function()
	if StealState.isStealing and StealState.stealStartTime then
		local prog=math.clamp((tick()-StealState.stealStartTime)/Steal.StealDuration,0,1)
		progressFill.Size=UDim2.new(prog,0,1,0); progressPct.Text=math.floor(prog*100).."%"
	else
		progressFill.Size=UDim2.new(0,0,1,0); progressPct.Text="0%"
	end
end)

-- ===== CONFIG =====
local function saveConfig()
	local cfg={
		normalSpeed=NS,carrySpeed=CS,
		speedToggleKey=KB.SpeedToggle.Name,
		dropBrainrotKey=KB.DropBrainrot.Name,autoLeftKey=KB.AutoLeft.Name,autoRightKey=KB.AutoRight.Name,
		autoBatKey=KB.AutoBat.Name,tpLeftKey=KB.TPLeft.Name,tpRightKey=KB.TPRight.Name,
		unwalkKey=KB.Unwalk.Name,tpFloorKey=KB.TPFloor.Name,
		grabRadius=Steal.StealRadius,stealDuration=Steal.StealDuration,
		antiRagdoll=antiRagdollEnabled,autoStealEnabled=Steal.AutoStealEnabled,
		infiniteJump=infJumpEnabled,medusaCounter=medusaCounterEnabled,
		brainrotReturnLeft=brainrotLeftEnabled,brainrotReturnRight=brainrotRightEnabled,
		carryMode=speedMode,autoBat=autoBatEnabled,
		unwalkEnabled=unwalkEnabled,
		antiLag=antiLagEnabled,ultraMode=ultraModeEnabled,
	}
	if writefile then pcall(function() writefile("K7MiniHubConfig.json",HS:JSONEncode(cfg)) end) end
end

task.spawn(function() while task.wait(5) do saveConfig() end end)

local function loadConfig()
	if not(isfile and isfile("K7MiniHubConfig.json")) then return end
	local ok,cfg=pcall(function() return HS:JSONDecode(readfile("K7MiniHubConfig.json")) end)
	if not ok or not cfg then return end
	if cfg.normalSpeed then NS=cfg.normalSpeed end
	if cfg.carrySpeed then CS=cfg.carrySpeed end
	if cfg.speedToggleKey and Enum.KeyCode[cfg.speedToggleKey] then KB.SpeedToggle=Enum.KeyCode[cfg.speedToggleKey] end
	if cfg.dropBrainrotKey and Enum.KeyCode[cfg.dropBrainrotKey] then KB.DropBrainrot=Enum.KeyCode[cfg.dropBrainrotKey] end
	if cfg.autoLeftKey and Enum.KeyCode[cfg.autoLeftKey] then KB.AutoLeft=Enum.KeyCode[cfg.autoLeftKey] end
	if cfg.autoRightKey and Enum.KeyCode[cfg.autoRightKey] then KB.AutoRight=Enum.KeyCode[cfg.autoRightKey] end
	if cfg.autoBatKey and Enum.KeyCode[cfg.autoBatKey] then KB.AutoBat=Enum.KeyCode[cfg.autoBatKey] end
	if cfg.tpLeftKey and Enum.KeyCode[cfg.tpLeftKey] then KB.TPLeft=Enum.KeyCode[cfg.tpLeftKey] end
	if cfg.tpRightKey and Enum.KeyCode[cfg.tpRightKey] then KB.TPRight=Enum.KeyCode[cfg.tpRightKey] end
	if cfg.unwalkKey and Enum.KeyCode[cfg.unwalkKey] then KB.Unwalk=Enum.KeyCode[cfg.unwalkKey] end
	if cfg.tpFloorKey and Enum.KeyCode[cfg.tpFloorKey] then KB.TPFloor=Enum.KeyCode[cfg.tpFloorKey] end
	if cfg.grabRadius then Steal.StealRadius=cfg.grabRadius end
	if cfg.stealDuration then Steal.StealDuration=cfg.stealDuration end
	if cfg.antiRagdoll~=nil then antiRagdollEnabled=cfg.antiRagdoll end
	if cfg.autoStealEnabled~=nil then
		if cfg.autoStealEnabled then startAutoSteal() else stopAutoSteal() end
	end
	if cfg.infiniteJump~=nil then infJumpEnabled=cfg.infiniteJump end
	if cfg.medusaCounter~=nil then medusaCounterEnabled=cfg.medusaCounter end
	if cfg.brainrotReturnLeft~=nil then brainrotLeftEnabled=cfg.brainrotReturnLeft end
	if cfg.brainrotReturnRight~=nil then brainrotRightEnabled=cfg.brainrotReturnRight end
	if cfg.carryMode~=nil then speedMode=cfg.carryMode end
	if cfg.autoBat~=nil then autoBatEnabled=cfg.autoBat end
	if cfg.unwalkEnabled~=nil then unwalkEnabled=cfg.unwalkEnabled end
	if cfg.antiLag~=nil then antiLagEnabled=cfg.antiLag end
	if cfg.ultraMode~=nil then ultraModeEnabled=cfg.ultraMode end
	if medusaCounterEnabled then setupMedusa(LP.Character) end
	if infJumpEnabled then startInfiniteJump() end
	if antiLagEnabled then enableAntiLag() end
	if ultraModeEnabled then enableUltraMode() end
	task.defer(function()
		carryModeBtn.BackgroundColor3=speedMode and C_PURPLE or C_CARD
		carryBadge.Text=getKeyName(KB.SpeedToggle)
		normalSpeedInput.Text=tostring(NS); carrySpeedInput.Text=tostring(CS)
		autoStealBtn.BackgroundColor3=Steal.AutoStealEnabled and C_PURPLE or C_CARD
		durationInput.Text=string.format("%.2f",Steal.StealDuration)
		radValBtn.Text=tostring(Steal.StealRadius); progressRadLbl.Text="Radius: "..Steal.StealRadius
		local states={["Anti Ragdoll"]=antiRagdollEnabled,["Infinite Jump"]=infJumpEnabled,
			["Medusa Counter"]=medusaCounterEnabled,["Anti Lag"]=antiLagEnabled,
			["Ultra Mode"]=ultraModeEnabled,["Remove Accessories"]=removeAccessoriesEnabled}
		for _,child in ipairs(scrollFrame:GetChildren()) do
			if child:IsA("TextButton") then
				local s=states[child.Text]; if s~=nil then child.BackgroundColor3=s and C_PURPLE or C_CARD end
			end
		end
		local kbMap={["Drop Brainrot"]=KB.DropBrainrot,["Auto Left"]=KB.AutoLeft,["Auto Right"]=KB.AutoRight,
			["Auto Bat"]=KB.AutoBat,["TP Left"]=KB.TPLeft,["TP Right"]=KB.TPRight,
			["Unwalk"]=KB.Unwalk,["TP to Floor"]=KB.TPFloor}
		for _,child in ipairs(scrollFrame:GetChildren()) do
			if child:IsA("TextButton") then
				for _,sub in ipairs(child:GetChildren()) do
					if sub:IsA("TextLabel") then
						local kb=kbMap[sub.Text]
						if kb then
							for _,badge in ipairs(child:GetChildren()) do
								if badge:IsA("TextLabel") and badge~=sub and badge.Size.X.Offset<=30 then
									badge.Text=getKeyName(kb); badge.BackgroundColor3=C_PURPLE; badge.BackgroundTransparency=0.3
								end
							end
						end
					end
				end
			end
		end
		if autoLeftSetVisual then autoLeftSetVisual(autoLeftEnabled) end
		if autoRightSetVisual then autoRightSetVisual(autoRightEnabled) end
		if autoBatSetVisual then autoBatSetVisual(autoBatEnabled) end
		if unwalkSetVisual then unwalkSetVisual(unwalkEnabled) end
		if brainrotLeftBtn then brainrotLeftBtn(brainrotLeftEnabled) end
		if brainrotRightBtn then brainrotRightBtn(brainrotRightEnabled) end
		if autoLeftEnabled then startAutoLeft() end
		if autoRightEnabled then startAutoRight() end
	end)
end

loadConfig()
print("✓ RELIC HUB Loaded (Juels TP coords)")
