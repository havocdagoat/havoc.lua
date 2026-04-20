repeat task.wait() until game:IsLoaded()
local Players,RunService,UIS,TS,Lighting,HS = game:GetService("Players"),game:GetService("RunService"),game:GetService("UserInputService"),game:GetService("TweenService"),game:GetService("Lighting"),game:GetService("HttpService")
local LP = Players.LocalPlayer

local NS,CS,DAS,DAD = 60,30,150,0.2

local speedMode,antiRagdollEnabled,infJumpEnabled = false,false,false
local medusaCounterEnabled,brainrotLeftEnabled,brainrotRightEnabled = false,false,false
local tpMode = "Manuel"
local medusaMode = false
local unwalkEnabled = false
local unwalkAnimations = {}
local floatEnabled = false
local floatHeight = 9.5
local floatJumping = false
local lastHealth,medusaDebounce,medusaLastUsed,dropActive = 100,false,0,false
local stretchRezEnabled = false
local autoLeftEnabled,autoRightEnabled = false,falsea
local autoLeftSetVisual,autoRightSetVisual = nil,nil
local speedLabel = nil
local medusaConns = {}
local autoBatEnabled = false
local autoBatSetVisual = nil
local _anyKeyListening = false

local KB = {
	DropBrainrot={kb=Enum.KeyCode.X,gp=nil},
	AutoLeft    ={kb=Enum.KeyCode.Z,gp=nil},
	AutoRight   ={kb=Enum.KeyCode.C,gp=nil},
	AutoBat     ={kb=Enum.KeyCode.E,gp=nil},
	TPLeft      ={kb=Enum.KeyCode.V,gp=nil},
	TPRight     ={kb=Enum.KeyCode.B,gp=nil},
	TPFloor     ={kb=Enum.KeyCode.F,gp=nil},
	GuiHide     ={kb=Enum.KeyCode.LeftControl,gp=nil},
	Float       ={kb=Enum.KeyCode.J,gp=nil},
	SpeedToggle ={kb=Enum.KeyCode.Q,gp=nil},
}

local AP_L1,AP_L2 = Vector3.new(-476.48,-6.28,92.73),Vector3.new(-483.12,-4.95,94.80)
local AP_L_FACE = Vector3.new(-482.25,-4.96,92.09)
local AP_R1,AP_R2 = Vector3.new(-476.16,-6.52,25.62),Vector3.new(-483.06,-5.03,25.48)
local AP_R_FACE = Vector3.new(-482.06,-6.93,35.47)
local BR_L1,BR_L2,BR_L3 = Vector3.new(-469,-6,78),Vector3.new(-471,-6,96),Vector3.new(-484,-4,99)
local BR_R1,BR_R2,BR_R3 = Vector3.new(-468,-6,41),Vector3.new(-473,-6,24),Vector3.new(-484,-4,20)
local SEMI_L1,SEMI_L2,SEMI_L3 = Vector3.new(-474.9,-7.0,94.9),Vector3.new(-481.7,-5.1,97.7),Vector3.new(-465.7,-7.0,83.2)
local SEMI_R1,SEMI_R2,SEMI_R3 = Vector3.new(-474.9,-7.0,24.1),Vector3.new(-482.64,-5.20,21.06),Vector3.new(-466.78,-7.10,40.83)

local Steal = {
	AutoStealEnabled=false,StealRadius=20,StealDuration=0.25,
	Data={},plotCache={},plotCacheTime={},cachedPrompts={},promptCacheTime=0,
}
local isStealing=false
local stealStartTime=nil
local lastStealTick=0
local Conns = {autoSteal=nil,antiRag=nil,float=nil,anchor={},progress=nil}
local PLOT_CACHE_DURATION = 2
local PROMPT_CACHE_REFRESH = 0.15
local STEAL_COOLDOWN = 0.1
local MEDUSA_COOLDOWN = 25

local progressRadLbl,progressFill,progressPct
local setFloat,modeValLbl

local function resetProgressBar()
	progressPct.Text="0%";progressFill.Size=UDim2.new(0,0,1,0)
end

local function isMyPlotByName(plotName)
	local ct = tick()
	if Steal.plotCache[plotName] and (ct-(Steal.plotCacheTime[plotName] or 0))<PLOT_CACHE_DURATION then return Steal.plotCache[plotName] end
	local plots = workspace:FindFirstChild("Plots")
	if not plots then Steal.plotCache[plotName]=false;Steal.plotCacheTime[plotName]=ct;return false end
	local plot = plots:FindFirstChild(plotName)
	if not plot then Steal.plotCache[plotName]=false;Steal.plotCacheTime[plotName]=ct;return false end
	local sign = plot:FindFirstChild("PlotSign")
	if sign then
		local yb = sign:FindFirstChild("YourBase")
		if yb and yb:IsA("BillboardGui") then
			local r = yb.Enabled==true;Steal.plotCache[plotName]=r;Steal.plotCacheTime[plotName]=ct;return r
		end
	end
	Steal.plotCache[plotName]=false;Steal.plotCacheTime[plotName]=ct;return false
end

local function findNearestPrompt()
	local char = LP.Character;if not char then return nil end
	local root = char:FindFirstChild("HumanoidRootPart");if not root then return nil end
	local ct = tick()
	if ct-Steal.promptCacheTime<PROMPT_CACHE_REFRESH and #Steal.cachedPrompts>0 then
		local np,nd = nil,math.huge
		for _,data in ipairs(Steal.cachedPrompts) do
			if data.spawn then
				local dist = (data.spawn.Position-root.Position).Magnitude
				if dist<=Steal.StealRadius and dist<nd then np=data.prompt;nd=dist end
			end
		end
		if np then return np end
	end
	Steal.cachedPrompts={};Steal.promptCacheTime=ct
	local plots = workspace:FindFirstChild("Plots");if not plots then return nil end
	local np,nd = nil,math.huge
	for _,plot in ipairs(plots:GetChildren()) do
		if isMyPlotByName(plot.Name) then continue end
		local pods = plot:FindFirstChild("AnimalPodiums");if not pods then continue end
		for _,pod in ipairs(pods:GetChildren()) do
			pcall(function()
				local base = pod:FindFirstChild("Base");local sp = base and base:FindFirstChild("Spawn")
				if sp then
					local att = sp:FindFirstChild("PromptAttachment")
					if att then
						for _,child in ipairs(att:GetChildren()) do
							if child:IsA("ProximityPrompt") then
								local dist = (sp.Position-root.Position).Magnitude
								table.insert(Steal.cachedPrompts,{prompt=child,spawn=sp,name=pod.Name})
								if dist<=Steal.StealRadius and dist<nd then np=child;nd=dist end
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

-- ===== VYSE-STYLE INSTA STEAL =====
local function executeSteal(prompt)
	local ct = tick()
	if ct-lastStealTick<STEAL_COOLDOWN then return end
	if isStealing then return end
	if not Steal.Data[prompt] then
		Steal.Data[prompt]={hold={},trigger={},ready=true}
		pcall(function()
			if getconnections then
				for _,c in ipairs(getconnections(prompt.PromptButtonHoldBegan)) do if c.Function then table.insert(Steal.Data[prompt].hold,c.Function) end end
				for _,c in ipairs(getconnections(prompt.Triggered)) do if c.Function then table.insert(Steal.Data[prompt].trigger,c.Function) end end
			else Steal.Data[prompt].useFallback=true end
		end)
	end
	local data = Steal.Data[prompt];if not data.ready then return end
	data.ready=false;isStealing=true;stealStartTime=ct;lastStealTick=ct
	if Conns.progress then Conns.progress:Disconnect() end
	Conns.progress = RunService.Heartbeat:Connect(function()
		if not isStealing then Conns.progress:Disconnect();return end
		local prog = math.clamp((tick()-stealStartTime)/Steal.StealDuration,0,1)
		progressFill.Size=UDim2.new(prog,0,1,0);progressPct.Text=math.floor(prog*100).."%"
	end)
	task.spawn(function()
		local ok = false
		pcall(function()
			if not data.useFallback then
				for _,fn in ipairs(data.hold) do task.spawn(fn) end
				task.wait(Steal.StealDuration)
				for _,fn in ipairs(data.trigger) do task.spawn(fn) end
				ok=true
			end
		end)
		if not ok and fireproximityprompt then pcall(function() fireproximityprompt(prompt);ok=true end) end
		if not ok then pcall(function() prompt:InputHoldBegin();task.wait(Steal.StealDuration);prompt:InputHoldEnd() end) end
		task.wait(Steal.StealDuration*0.3)
		if Conns.progress then Conns.progress:Disconnect() end
		resetProgressBar();task.wait(0.05);data.ready=true;isStealing=false
	end)
end

local function startAutoSteal()
	if Conns.autoSteal then return end
	Conns.autoSteal = RunService.Heartbeat:Connect(function()
		if not Steal.AutoStealEnabled or isStealing then return end
		local p = findNearestPrompt();if p then executeSteal(p) end
	end)
end

local function stopAutoSteal()
	if Conns.autoSteal then Conns.autoSteal:Disconnect();Conns.autoSteal=nil end
	isStealing=false;lastStealTick=0
	Steal.plotCache={};Steal.plotCacheTime={};Steal.cachedPrompts={};resetProgressBar()
end
-- ===== END INSTA STEAL =====

RunService.Stepped:Connect(function()
	for _,p in ipairs(Players:GetPlayers()) do
		if p~=LP and p.Character then
			for _,part in ipairs(p.Character:GetDescendants()) do
				if part:IsA("BasePart") then part.CanCollide=false end
			end
		end
	end
end)

RunService.RenderStepped:Connect(function()
	local char=LP.Character; if not char then return end
	local hum=char:FindFirstChildOfClass("Humanoid")
	local hrp=char:FindFirstChild("HumanoidRootPart")
	if not hum or not hrp then return end
	local md=hum.MoveDirection
	local spd=speedMode and CS or NS
	if md.Magnitude>0 and not autoLeftEnabled and not autoRightEnabled then
		hrp.AssemblyLinearVelocity=Vector3.new(md.X*spd,hrp.AssemblyLinearVelocity.Y,md.Z*spd)
	end
	if speedLabel then speedLabel.Text=string.format("Speed: %.1f",Vector3.new(hrp.AssemblyLinearVelocity.X,0,hrp.AssemblyLinearVelocity.Z).Magnitude) end
end)

local alConn,arConn = nil,nil
local alPhase,arPhase = 1,1

local function stopAutoLeft()
	if alConn then alConn:Disconnect();alConn=nil end;alPhase=1
	local char = LP.Character;if char then local h=char:FindFirstChildOfClass("Humanoid");if h then h:Move(Vector3.zero,false) end end
end

local function stopAutoRight()
	if arConn then arConn:Disconnect();arConn=nil end;arPhase=1
	local char = LP.Character;if char then local h=char:FindFirstChildOfClass("Humanoid");if h then h:Move(Vector3.zero,false) end end
end

local function startAutoLeft()
	if alConn then alConn:Disconnect() end;alPhase=1
	alConn=RunService.Heartbeat:Connect(function()
		if not autoLeftEnabled then return end
		local char=LP.Character;if not char then return end
		local hrp=char:FindFirstChild("HumanoidRootPart")
		local hum=char:FindFirstChildOfClass("Humanoid")
		if not hrp or not hum then return end
		local spd=NS
		if alPhase==1 then
			local tgt=Vector3.new(AP_L1.X,hrp.Position.Y,AP_L1.Z)
			if (tgt-hrp.Position).Magnitude<1 then
				alPhase=2
				local d=AP_L2-hrp.Position;local mv=Vector3.new(d.X,0,d.Z).Unit
				hum:Move(mv,false);hrp.AssemblyLinearVelocity=Vector3.new(mv.X*spd,hrp.AssemblyLinearVelocity.Y,mv.Z*spd);return
			end
			local d=AP_L1-hrp.Position;local mv=Vector3.new(d.X,0,d.Z).Unit
			hum:Move(mv,false);hrp.AssemblyLinearVelocity=Vector3.new(mv.X*spd,hrp.AssemblyLinearVelocity.Y,mv.Z*spd)
		elseif alPhase==2 then
			local tgt=Vector3.new(AP_L2.X,hrp.Position.Y,AP_L2.Z)
			if (tgt-hrp.Position).Magnitude<1 then
				hum:Move(Vector3.zero,false);hrp.AssemblyLinearVelocity=Vector3.zero
				autoLeftEnabled=false;if alConn then alConn:Disconnect();alConn=nil end
				alPhase=1;if autoLeftSetVisual then autoLeftSetVisual(false) end
				if (AP_L_FACE-hrp.Position).Magnitude>0.01 then hrp.CFrame=CFrame.new(hrp.Position,Vector3.new(AP_L_FACE.X,hrp.Position.Y,AP_L_FACE.Z)) end
				return
			end
			local d=AP_L2-hrp.Position;local mv=Vector3.new(d.X,0,d.Z).Unit
			hum:Move(mv,false);hrp.AssemblyLinearVelocity=Vector3.new(mv.X*spd,hrp.AssemblyLinearVelocity.Y,mv.Z*spd)
		end
	end)
end

local function startAutoRight()
	if arConn then arConn:Disconnect() end;arPhase=1
	arConn=RunService.Heartbeat:Connect(function()
		if not autoRightEnabled then return end
		local char=LP.Character;if not char then return end
		local hrp=char:FindFirstChild("HumanoidRootPart")
		local hum=char:FindFirstChildOfClass("Humanoid")
		if not hrp or not hum then return end
		local spd=NS
		if arPhase==1 then
			local tgt=Vector3.new(AP_R1.X,hrp.Position.Y,AP_R1.Z)
			if (tgt-hrp.Position).Magnitude<1 then
				arPhase=2
				local d=AP_R2-hrp.Position;local mv=Vector3.new(d.X,0,d.Z).Unit
				hum:Move(mv,false);hrp.AssemblyLinearVelocity=Vector3.new(mv.X*spd,hrp.AssemblyLinearVelocity.Y,mv.Z*spd);return
			end
			local d=AP_R1-hrp.Position;local mv=Vector3.new(d.X,0,d.Z).Unit
			hum:Move(mv,false);hrp.AssemblyLinearVelocity=Vector3.new(mv.X*spd,hrp.AssemblyLinearVelocity.Y,mv.Z*spd)
		elseif arPhase==2 then
			local tgt=Vector3.new(AP_R2.X,hrp.Position.Y,AP_R2.Z)
			if (tgt-hrp.Position).Magnitude<1 then
				hum:Move(Vector3.zero,false);hrp.AssemblyLinearVelocity=Vector3.zero
				autoRightEnabled=false;if arConn then arConn:Disconnect();arConn=nil end
				arPhase=1;if autoRightSetVisual then autoRightSetVisual(false) end
				if (AP_R_FACE-hrp.Position).Magnitude>0.01 then hrp.CFrame=CFrame.new(hrp.Position,Vector3.new(AP_R_FACE.X,hrp.Position.Y,AP_R_FACE.Z)) end
				return
			end
			local d=AP_R2-hrp.Position;local mv=Vector3.new(d.X,0,d.Z).Unit
			hum:Move(mv,false);hrp.AssemblyLinearVelocity=Vector3.new(mv.X*spd,hrp.AssemblyLinearVelocity.Y,mv.Z*spd)
		end
	end)
end

local function setupSpeedIndicator(char)
	local head = char:WaitForChild("Head",5);if not head then return end
	local bb = Instance.new("BillboardGui",head)
	bb.Size=UDim2.new(0,140,0,25);bb.StudsOffset=Vector3.new(0,3,0);bb.AlwaysOnTop=true
	speedLabel = Instance.new("TextLabel",bb)
	speedLabel.Size=UDim2.new(1,0,1,0);speedLabel.BackgroundTransparency=1
	speedLabel.Text="Speed: 0";speedLabel.TextColor3=Color3.fromRGB(255,255,255)
	speedLabel.Font=Enum.Font.GothamBlack;speedLabel.TextScaled=true
	speedLabel.TextStrokeTransparency=0;speedLabel.TextStrokeColor3=Color3.fromRGB(0,0,0)
end

local function startAntiRagdoll()
	if Conns.antiRag then return end
	Conns.antiRag = RunService.Heartbeat:Connect(function()
		local char = LP.Character;if not char then return end
		local hum = char:FindFirstChildOfClass("Humanoid");local root=char:FindFirstChild("HumanoidRootPart")
		if hum then
			local st = hum:GetState()
			if st==Enum.HumanoidStateType.Physics or st==Enum.HumanoidStateType.Ragdoll or st==Enum.HumanoidStateType.FallingDown then
				hum:ChangeState(Enum.HumanoidStateType.Running)
				workspace.CurrentCamera.CameraSubject=hum
				pcall(function() local pm=LP.PlayerScripts:FindFirstChild("PlayerModule");if pm then require(pm:FindFirstChild("ControlModule")):Enable() end end)
				if root then root.Velocity=Vector3.zero;root.RotVelocity=Vector3.zero end
			end
		end
		for _,obj in ipairs(char:GetDescendants()) do if obj:IsA("Motor6D") and not obj.Enabled then obj.Enabled=true end end
	end)
end

local function stopAntiRagdoll()
	if Conns.antiRag then Conns.antiRag:Disconnect();Conns.antiRag=nil end
end

local IJ_JumpConn,IJ_FallConn = nil,nil

local function startInfiniteJump()
	if IJ_JumpConn then IJ_JumpConn:Disconnect() end
	if IJ_FallConn then IJ_FallConn:Disconnect() end
	IJ_JumpConn = UIS.JumpRequest:Connect(function()
		if not infJumpEnabled then return end
		local char = LP.Character;if not char then return end
		local root = char:FindFirstChild("HumanoidRootPart")
		if root then root.Velocity=Vector3.new(root.Velocity.X,55,root.Velocity.Z) end
	end)
	IJ_FallConn = RunService.Heartbeat:Connect(function()
		if not infJumpEnabled then return end
		local char = LP.Character;if not char then return end
		local root = char:FindFirstChild("HumanoidRootPart")
		if root and root.Velocity.Y<-120 then root.Velocity=Vector3.new(root.Velocity.X,-120,root.Velocity.Z) end
	end)
end

local function stopInfiniteJump()
	if IJ_JumpConn then IJ_JumpConn:Disconnect();IJ_JumpConn=nil end
	if IJ_FallConn then IJ_FallConn:Disconnect();IJ_FallConn=nil end
end

local function disableAnimations()
	local char = LP.Character;if not char then return end
	local hum = char:FindFirstChildOfClass("Humanoid");if not hum then return end
	for _,track in pairs(unwalkAnimations) do pcall(function() track:Stop() end) end
	unwalkAnimations={}
	local animator = hum:FindFirstChildOfClass("Animator")
	if animator then
		for _,track in pairs(animator:GetPlayingAnimationTracks()) do
			track:Stop();table.insert(unwalkAnimations,track)
		end
	end
end

local function enableAnimations() unwalkAnimations={} end

RunService.Heartbeat:Connect(function()
	if not unwalkEnabled then return end
	disableAnimations()
end)

local brainrotReturnCooldown = false
local RAGDOLL_STATES = {[Enum.HumanoidStateType.Ragdoll]=true,[Enum.HumanoidStateType.FallingDown]=true,[Enum.HumanoidStateType.Physics]=true}

local function isRagdolledCheck()
	local c = LP.Character;if not c then return false end
	local hum = c:FindFirstChildOfClass("Humanoid");if not hum then return false end
	if RAGDOLL_STATES[hum:GetState()] then return true end
	for _,obj in ipairs(c:GetDescendants()) do
		if obj:IsA("Motor6D") and obj.Enabled==false then return true end
	end
	return false
end

local function doReturnTeleport(side)
	if brainrotReturnCooldown then return end
	brainrotReturnCooldown=true
	task.spawn(function()
		local char = LP.Character;if not char then brainrotReturnCooldown=false;return end
		local hrp = char:FindFirstChild("HumanoidRootPart")
		local hum = char:FindFirstChildOfClass("Humanoid")
		if not(hrp and hum) then brainrotReturnCooldown=false;return end
		local s1,s2,s3
		if tpMode=="Semi" then
			s1=side=="left" and SEMI_L1 or SEMI_R1
			s2=side=="left" and SEMI_L2 or SEMI_R2
			s3=side=="left" and SEMI_L3 or SEMI_R3
		else
			s1=side=="left" and BR_L1 or BR_R1
			s2=side=="left" and BR_L2 or BR_R2
			s3=side=="left" and BR_L3 or BR_R3
		end
		if tpMode=="Semi" then
			pcall(function()
				for _,obj in ipairs(char:GetDescendants()) do if obj:IsA("Motor6D") then obj.Enabled=true end end
				hum:ChangeState(Enum.HumanoidStateType.GettingUp)
				task.wait(0.20)
				hrp.AssemblyLinearVelocity=Vector3.zero;hrp.AssemblyAngularVelocity=Vector3.zero
				hrp.CFrame=CFrame.new(s1+Vector3.new(0,3,0))
				task.wait(0.20)
				hrp.AssemblyLinearVelocity=Vector3.zero
				hrp.CFrame=CFrame.new(s2+Vector3.new(0,3,0))
				task.wait(0.20)
				hrp.AssemblyLinearVelocity=Vector3.zero
				hrp.CFrame=CFrame.new(s3+Vector3.new(0,3,0))
				hum:ChangeState(Enum.HumanoidStateType.Running)
				hum:Move(Vector3.zero,false)
				for _,obj in ipairs(char:GetDescendants()) do if obj:IsA("Motor6D") then obj.Enabled=true end end
			end)
			task.wait(0.6)
		else
			hrp.AssemblyLinearVelocity=Vector3.zero
			hrp.CFrame=CFrame.new(s1+Vector3.new(0,3,0))
			hum:ChangeState(Enum.HumanoidStateType.Running)
			task.wait(0.1)
			hrp.AssemblyLinearVelocity=Vector3.zero
			hrp.CFrame=CFrame.new(s2+Vector3.new(0,3,0))
			hum:ChangeState(Enum.HumanoidStateType.Running)
			task.wait(0.1)
			hrp.AssemblyLinearVelocity=Vector3.zero
			hrp.CFrame=CFrame.new(s3+Vector3.new(0,3,0))
			hum:ChangeState(Enum.HumanoidStateType.Running)
			task.wait(0.6)
		end
		brainrotReturnCooldown=false
	end)
end

RunService.Heartbeat:Connect(function()
	if not(brainrotLeftEnabled or brainrotRightEnabled) or brainrotReturnCooldown then return end
	local char = LP.Character;if not char then return end
	local hum = char:FindFirstChildOfClass("Humanoid");if not hum then return end
	local hp = hum.Health
	local hit = hp<lastHealth-1
	local rag = RAGDOLL_STATES[hum:GetState()] or isRagdolledCheck()
	lastHealth=hp
	if not(hit or rag) then return end
	if brainrotLeftEnabled then doReturnTeleport("left")
	elseif brainrotRightEnabled then doReturnTeleport("right") end
end)

UIS.JumpRequest:Connect(function()
	if floatEnabled then floatJumping=true end
end)

local function startFloat()
	if Conns.float then Conns.float:Disconnect() end
	Conns.float = RunService.Heartbeat:Connect(function()
		if not floatEnabled then return end
		if dropActive then return end
		local char = LP.Character;if not char then return end
		local root = char:FindFirstChild("HumanoidRootPart");if not root then return end
		local rp = RaycastParams.new();rp.FilterDescendantsInstances={char};rp.FilterType=Enum.RaycastFilterType.Exclude
		local rr = workspace:Raycast(root.Position,Vector3.new(0,-200,0),rp)
		if rr then
			local diff = (rr.Position.Y+floatHeight)-root.Position.Y
			if floatJumping then
				if root.AssemblyLinearVelocity.Y<=0 and diff>=-2 then
					floatJumping=false
				else
					return
				end
			end
			if math.abs(diff)>0.3 then
				root.AssemblyLinearVelocity=Vector3.new(root.AssemblyLinearVelocity.X,diff*15,root.AssemblyLinearVelocity.Z)
			else
				root.AssemblyLinearVelocity=Vector3.new(root.AssemblyLinearVelocity.X,0,root.AssemblyLinearVelocity.Z)
			end
		end
	end)
end

local function stopFloat()
	if Conns.float then Conns.float:Disconnect();Conns.float=nil end
	floatJumping=false
	local char = LP.Character;if char then
		local root = char:FindFirstChild("HumanoidRootPart")
		if root then root.AssemblyLinearVelocity=Vector3.new(root.AssemblyLinearVelocity.X,0,root.AssemblyLinearVelocity.Z) end
	end
end

local function runDrop()
	if dropActive then return end
	local char = LP.Character;if not char then return end
	local hrp = char:FindFirstChild("HumanoidRootPart");if not hrp then return end
	local floatWasEnabled = floatEnabled
	if floatWasEnabled then floatEnabled=false;if setFloat then setFloat(false) end end
	dropActive=true;local t0=tick();local conn
	conn = RunService.Heartbeat:Connect(function()
		local r = char and char:FindFirstChild("HumanoidRootPart")
		if not r then conn:Disconnect();dropActive=false;return end
		if tick()-t0>=DAD then
			conn:Disconnect()
			local rp = RaycastParams.new();rp.FilterDescendantsInstances={char};rp.FilterType=Enum.RaycastFilterType.Exclude
			local rr = workspace:Raycast(r.Position,Vector3.new(0,-2000,0),rp)
			if rr then
				local hum2 = char:FindFirstChildOfClass("Humanoid")
				local off = (hum2 and hum2.HipHeight or 2)+(r.Size.Y/2)
				r.CFrame=CFrame.new(r.Position.X,rr.Position.Y+off,r.Position.Z);r.AssemblyLinearVelocity=Vector3.zero
			end
			dropActive=false
			if floatWasEnabled then floatEnabled=true;if setFloat then setFloat(true) end;startFloat() end
			return
		end
		r.AssemblyLinearVelocity=Vector3.new(r.AssemblyLinearVelocity.X,DAS,r.AssemblyLinearVelocity.Z)
	end)
end

local function runTPFloor()
	pcall(function()
		local char = LP.Character;if not char then return end
		local hrp = char:FindFirstChild("HumanoidRootPart");if not hrp then return end
		local rp = RaycastParams.new();rp.FilterDescendantsInstances={char};rp.FilterType=Enum.RaycastFilterType.Exclude
		local rs = workspace:Raycast(hrp.Position,Vector3.new(0,-500,0),rp)
		if rs then
			hrp.CFrame=CFrame.new(hrp.Position.X,rs.Position.Y+hrp.Size.Y/2+0.1,hrp.Position.Z)
			hrp.AssemblyLinearVelocity=Vector3.zero
		end
	end)
end

local stretchRezConn = nil
local function enableStretchRez()
	stretchRezEnabled=true
	workspace.CurrentCamera.FieldOfView=120
	if stretchRezConn then stretchRezConn:Disconnect() end
	stretchRezConn=RunService.RenderStepped:Connect(function()
		if not stretchRezEnabled then stretchRezConn:Disconnect();stretchRezConn=nil;return end
		workspace.CurrentCamera.FieldOfView=120
	end)
end

local function disableStretchRez()
	stretchRezEnabled=false
	if stretchRezConn then stretchRezConn:Disconnect();stretchRezConn=nil end
	workspace.CurrentCamera.FieldOfView=70
end

local function findMedusa()
	local char = LP.Character;if not char then return nil end
	for _,t in ipairs(char:GetChildren()) do if t:IsA("Tool") and t.Name:lower():find("medusa") then return t end end
	local bp = LP:FindFirstChild("Backpack")
	if bp then for _,t in ipairs(bp:GetChildren()) do if t:IsA("Tool") and t.Name:lower():find("medusa") then return t end end end
end

local function useMedusa()
	if medusaDebounce or tick()-medusaLastUsed<MEDUSA_COOLDOWN then return end
	local char = LP.Character;if not char then return end
	medusaDebounce=true
	local med = findMedusa()
	if med then
		if med.Parent~=char then local h=char:FindFirstChildOfClass("Humanoid");if h then h:EquipTool(med) end end
		pcall(function() med:Activate() end);medusaLastUsed=tick()
	end
	medusaDebounce=false
end

local function onAnchorChanged(part)
	return part:GetPropertyChangedSignal("Anchored"):Connect(function()
		if part.Anchored and part.Transparency==1 and medusaCounterEnabled then useMedusa() end
	end)
end

local function setupMedusa(char)
	for _,c in pairs(medusaConns) do pcall(function() c:Disconnect() end) end;medusaConns={}
	if not char then return end
	for _,part in ipairs(char:GetDescendants()) do if part:IsA("BasePart") then table.insert(medusaConns,onAnchorChanged(part)) end end
	table.insert(medusaConns,char.DescendantAdded:Connect(function(part)
		if part:IsA("BasePart") then table.insert(medusaConns,onAnchorChanged(part)) end
	end))
end

local function getClosestPlayer()
	local char = LP.Character;if not char then return nil,math.huge end
	local hrp = char:FindFirstChild("HumanoidRootPart");if not hrp then return nil,math.huge end
	local cp,cd = nil,math.huge
	for _,p in pairs(Players:GetPlayers()) do
		if p~=LP and p.Character then
			local tr = p.Character:FindFirstChild("HumanoidRootPart")
			if tr then local d=(hrp.Position-tr.Position).Magnitude;if d<cd then cd=d;cp=p end end
		end
	end
	return cp,cd
end

RunService.Heartbeat:Connect(function()
	if not autoBatEnabled then return end
	local char=LP.Character;if not char then return end
	local hrp=char:FindFirstChild("HumanoidRootPart");if not hrp then return end
	if not char:FindFirstChildOfClass("Tool") then
		local hum=char:FindFirstChildOfClass("Humanoid")
		local bp=LP:FindFirstChild("Backpack")
		local bat=(bp and bp:FindFirstChild("Bat")) or char:FindFirstChild("Bat")
		if bat and hum then hum:EquipTool(bat) end
	end
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

LP.CharacterAdded:Connect(function(char)
	lastHealth=100;task.wait(0.5)
	setupSpeedIndicator(char)
	if medusaCounterEnabled then setupMedusa(char) end
	unwalkAnimations={}
	if unwalkEnabled then task.wait(0.5);disableAnimations() end
end)
if LP.Character then setupSpeedIndicator(LP.Character) end

local function saveConfig()
	local function ks(e) return {kb=e.kb and e.kb.Name or nil,gp=e.gp and e.gp.Name or nil} end
	local cfg = {
		normalSpeed=NS,carrySpeed=CS,
		dropBrainrotKey=ks(KB.DropBrainrot),autoLeftKey=ks(KB.AutoLeft),autoRightKey=ks(KB.AutoRight),
		autoBatKey=ks(KB.AutoBat),tpLeftKey=ks(KB.TPLeft),tpRightKey=ks(KB.TPRight),
		tpFloorKey=ks(KB.TPFloor),guiHideKey=ks(KB.GuiHide),floatKey=ks(KB.Float),
		speedToggleKey=ks(KB.SpeedToggle),
		grabRadius=Steal.StealRadius,stealDuration=Steal.StealDuration,
		antiRagdoll=antiRagdollEnabled,autoStealEnabled=Steal.AutoStealEnabled,
		infiniteJump=infJumpEnabled,medusaCounter=medusaCounterEnabled,
		brainrotReturnLeft=brainrotLeftEnabled,brainrotReturnRight=brainrotRightEnabled,
		carryMode=speedMode,autoBat=autoBatEnabled,
		unwalkEnabled=unwalkEnabled,
		floatHeight=floatHeight,floatEnabled=floatEnabled,
		stretchRez=stretchRezEnabled,
		tpMode=tpMode,
	}
	if writefile then pcall(function() writefile("RelicHubPC.json",HS:JSONEncode(cfg)) end) end
end
task.spawn(function() while task.wait(5) do saveConfig() end end)

local setInstaGrab
local setInfJumpVisual,setAntiRagVisual,setMedusaVisual
local setUnwalkVisual,setTPLeftVisual,setTPRightVisual
local durationInput,normalBox,carryBox,radInput
local floatHeightBox

-- buildGui written below
local function buildGui()
	local C_BG        = Color3.fromRGB(10,10,10)
    local C_SIDEBAR   = Color3.fromRGB(6,6,6)
    local C_TOPBAR    = Color3.fromRGB(8,8,8)
    local C_ROW       = Color3.fromRGB(18,18,18)
    local C_ROW_HOV   = Color3.fromRGB(24,24,24)
	local C_BORDER    = Color3.fromRGB(38,38,38)
	local C_DIM       = Color3.fromRGB(80,80,80)
	local C_WHITE     = Color3.fromRGB(255,255,255)
	local C_SUBTEXT   = Color3.fromRGB(120,120,120)
	local C_ON_BG = Color3.fromRGB(60,60,60)
local C_OFF_BG = Color3.fromRGB(20,20,20)
	local C_INPUT_BG  = Color3.fromRGB(28,28,28)
	local C_KEY_BG    = Color3.fromRGB(30,30,30)

	-- destroy old
	local old = game:GetService("CoreGui"):FindFirstChild("RelicHub"); if old then old:Destroy() end
	local pg = LP:FindFirstChild("PlayerGui"); if pg then local o2=pg:FindFirstChild("RelicHub"); if o2 then o2:Destroy() end end

	local gui = Instance.new("ScreenGui")
	gui.Name="RelicHub"; gui.ResetOnSpawn=false; gui.DisplayOrder=10; gui.IgnoreGuiInset=true
	pcall(function() if syn and syn.protect_gui then syn.protect_gui(gui) end end)
	if not pcall(function() gui.Parent=game:GetService("CoreGui") end) then gui.Parent=LP:WaitForChild("PlayerGui") end

	-- === MAIN FRAME ===
	local main = Instance.new("Frame", gui)
	main.Name="Main"; main.Size = UDim2.new(0,600,0,420); main.Position=UDim2.new(0.5,-260,0.5,-230)
	main.BackgroundColor3=C_BG; main.BorderSizePixel=0; main.Active=true; main.ClipsDescendants=true
	Instance.new("UICorner",main).CornerRadius=UDim.new(0,12)
	local mainStroke=Instance.new("UIStroke",main); mainStroke.Color=C_BORDER; mainStroke.Thickness=1

	local function makeDraggable(frame)
		local dragging,dragInput,dragStart,startPos=false,nil,nil,nil
		frame.InputBegan:Connect(function(inp)
			if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then
				dragging=true; dragStart=inp.Position; startPos=frame.Position
				inp.Changed:Connect(function() if inp.UserInputState==Enum.UserInputState.End then dragging=false end end)
			end
		end)
		frame.InputChanged:Connect(function(inp)
			if inp.UserInputType==Enum.UserInputType.MouseMovement or inp.UserInputType==Enum.UserInputType.Touch then dragInput=inp end
		end)
		UIS.InputChanged:Connect(function(inp)
			if inp==dragInput and dragging then
				local dx=inp.Position.X-dragStart.X; local dy=inp.Position.Y-dragStart.Y
				frame.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+dx,startPos.Y.Scale,startPos.Y.Offset+dy)
			end
		end)
	end
	makeDraggable(main)

	-- === TOP BAR ===
	local topbar = Instance.new("Frame", main)
	topbar.Size=UDim2.new(1,0,0,40); topbar.BackgroundColor3=C_TOPBAR; topbar.BorderSizePixel=0; topbar.ZIndex=5
	Instance.new("UICorner",topbar).CornerRadius=UDim.new(0,12)
	local topDiv=Instance.new("Frame",topbar)
	topDiv.Size=UDim2.new(1,0,0,1); topDiv.Position=UDim2.new(0,0,1,-1); topDiv.BackgroundColor3=C_BORDER; topDiv.BorderSizePixel=0; topDiv.ZIndex=5

	local titleLbl=Instance.new("TextLabel",topbar)
	titleLbl.Size=UDim2.new(0,160,1,0); titleLbl.Position=UDim2.new(0,14,0,0); titleLbl.BackgroundTransparency=1
	titleLbl.Text="RELIC HUB"; titleLbl.TextColor3=C_WHITE; titleLbl.Font=Enum.Font.GothamBlack; titleLbl.TextSize=14
	titleLbl.TextXAlignment=Enum.TextXAlignment.Left; titleLbl.ZIndex=6

	local discordLbl=Instance.new("TextLabel",topbar)
	discordLbl.Size=UDim2.new(0,160,1,0); discordLbl.Position=UDim2.new(0,108,0,0); discordLbl.BackgroundTransparency=1
	discordLbl.Text="discord.gg/relichub"; discordLbl.TextColor3=C_DIM; discordLbl.Font=Enum.Font.GothamBlack; discordLbl.TextSize=10
	discordLbl.TextXAlignment=Enum.TextXAlignment.Left; discordLbl.ZIndex=6

	local miniToggleBtn
	local guiVisible=true
	local function showGui() guiVisible=true; main.Visible=true; if miniToggleBtn then miniToggleBtn.Visible=false end end
	local function hideGui() guiVisible=false; main.Visible=false; if miniToggleBtn then miniToggleBtn.Visible=true end end
	local function toggleGuiVis() if guiVisible then hideGui() else showGui() end end

	local closeBtn=Instance.new("TextButton",topbar)
	closeBtn.Size=UDim2.new(0,24,0,24); closeBtn.Position=UDim2.new(1,-32,0.5,-12); closeBtn.BackgroundColor3=Color3.fromRGB(28,28,28)
	closeBtn.BorderSizePixel=0; closeBtn.Text="−"; closeBtn.TextColor3=C_SUBTEXT; closeBtn.Font=Enum.Font.GothamBlack; closeBtn.TextSize=16; closeBtn.ZIndex=10
	Instance.new("UICorner",closeBtn).CornerRadius=UDim.new(0,6)
	closeBtn.MouseButton1Click:Connect(hideGui)

	-- === BODY FRAME ===
	local body=Instance.new("Frame",main)
	body.Size=UDim2.new(1,0,1,-40); body.Position=UDim2.new(0,0,0,40); body.BackgroundTransparency=1; body.BorderSizePixel=0

	-- === SIDEBAR ===
	local sidebar=Instance.new("Frame",body)
	sidebar.Size = UDim2.new(0,170,1,0); sidebar.BackgroundColor3=C_SIDEBAR; sidebar.BorderSizePixel=0; sidebar.ClipsDescendants=true
	local sideDiv=Instance.new("Frame",sidebar)
	sideDiv.Size=UDim2.new(0,1,1,0); sideDiv.Position=UDim2.new(1,-1,0,0); sideDiv.BackgroundColor3=C_BORDER; sideDiv.BorderSizePixel=0; sideDiv.ZIndex=10

	-- Nav box at the TOP of sidebar (ZIndex high so it sits above R)
	local navBox=Instance.new("Frame",sidebar)
	navBox.Size=UDim2.new(1,-16,0,0); navBox.Position=UDim2.new(0,8,0,10)
	navBox.BackgroundColor3=Color3.fromRGB(16,16,16); navBox.BorderSizePixel=0; navBox.AutomaticSize=Enum.AutomaticSize.Y
	navBox.ZIndex=8; navBox.ClipsDescendants=false
	Instance.new("UICorner",navBox).CornerRadius=UDim.new(0,10)
	local navBoxStroke=Instance.new("UIStroke",navBox)
	navBoxStroke.Color=Color3.fromRGB(50,50,50); navBoxStroke.Thickness=1

	local navFrame=Instance.new("Frame",navBox)
	navFrame.Size=UDim2.new(1,0,0,0); navFrame.AutomaticSize=Enum.AutomaticSize.Y
	navFrame.BackgroundTransparency=1; navFrame.BorderSizePixel=0; navFrame.ZIndex=8
	local navLL=Instance.new("UIListLayout",navFrame)
	navLL.SortOrder=Enum.SortOrder.LayoutOrder; navLL.Padding=UDim.new(0,2)
	local navPad=Instance.new("UIPadding",navFrame)
	navPad.PaddingLeft=UDim.new(0,5); navPad.PaddingRight=UDim.new(0,5); navPad.PaddingTop=UDim.new(0,5); navPad.PaddingBottom=UDim.new(0,5)

	-- R fills lower portion of sidebar, positioned below nav buttons
	local bigR=Instance.new("TextLabel",sidebar)
	bigR.Size = UDim2.new(1,0,1,-160); bigR.Position = UDim2.new(0,0,0,160)
	bigR.BackgroundTransparency=1; bigR.Text="R"; bigR.TextColor3=Color3.fromRGB(255,255,255)
	bigR.TextTransparency=0.85; bigR.Font=Enum.Font.GothamBlack; bigR.TextSize=200
	bigR.TextScaled=true; bigR.TextXAlignment=Enum.TextXAlignment.Center; bigR.TextYAlignment=Enum.TextYAlignment.Center
	bigR.ZIndex=2

	-- Fade gradient over top of R so it blends with nav box area
	local rFade=Instance.new("Frame",sidebar)
	rFade.Size=UDim2.new(1,0,0,60); rFade.Position=UDim2.new(0,0,0,210)
	rFade.BackgroundColor3=C_SIDEBAR; rFade.BorderSizePixel=0; rFade.ZIndex=3
	local rFadeGrad=Instance.new("UIGradient",rFade)
	rFadeGrad.Rotation=90; rFadeGrad.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(1,1)})

	-- Bottom name overlay
	local logoBottomName=Instance.new("TextLabel",sidebar)
	logoBottomName.Size=UDim2.new(1,-10,0,18); logoBottomName.Position=UDim2.new(0,10,1,-38)
	logoBottomName.BackgroundTransparency=1; logoBottomName.Text="RELIC HUB"
	logoBottomName.TextColor3=C_WHITE; logoBottomName.Font=Enum.Font.GothamBlack; logoBottomName.TextSize=12
	logoBottomName.TextXAlignment=Enum.TextXAlignment.Left; logoBottomName.ZIndex=5

	local logoBottomSub=Instance.new("TextLabel",sidebar)
	logoBottomSub.Size=UDim2.new(1,-10,0,14); logoBottomSub.Position=UDim2.new(0,10,1,-20)
	logoBottomSub.BackgroundTransparency=1; logoBottomSub.Text="discord.gg/relichub"
	logoBottomSub.TextColor3=C_DIM; logoBottomSub.Font=Enum.Font.GothamBlack; logoBottomSub.TextSize=9
	logoBottomSub.TextXAlignment=Enum.TextXAlignment.Left; logoBottomSub.ZIndex=5

	-- === CONTENT AREA ===
	local contentArea=Instance.new("Frame",body)
	contentArea.Size = UDim2.new(1,-170,1,0)
contentArea.Position = UDim2.new(0,170,0,0)
	contentArea.BackgroundTransparency=1; contentArea.BorderSizePixel=0; contentArea.ClipsDescendants=true

	-- === TAB SYSTEM ===
	local TAB_NAMES={"Speed","Bat Aimbot","Mechanics","Movement","Settings"}
	local tabPages={}; local navBtns={}; local activeTabName=nil

	for _,name in ipairs(TAB_NAMES) do
		local sf=Instance.new("ScrollingFrame",contentArea)
		sf.Size=UDim2.new(1,0,1,0); sf.BackgroundTransparency=1; sf.BorderSizePixel=0
		sf.ScrollBarThickness=2; sf.ScrollBarImageColor3=C_BORDER
		sf.AutomaticCanvasSize=Enum.AutomaticSize.Y; sf.CanvasSize=UDim2.new(0,0,0,0); sf.Visible=false
		local ll=Instance.new("UIListLayout",sf); ll.SortOrder=Enum.SortOrder.LayoutOrder; ll.Padding=UDim.new(0,4)
		local pp=Instance.new("UIPadding",sf)
		pp.PaddingLeft = UDim.new(0,16)
pp.PaddingRight = UDim.new(0,16); pp.PaddingTop=UDim.new(0,10); pp.PaddingBottom=UDim.new(0,10)
		tabPages[name]=sf
	end

	local function switchTab(name)
		if activeTabName then tabPages[activeTabName].Visible=false end
		activeTabName=name; tabPages[name].Visible=true
		for n,d in pairs(navBtns) do
			local active=(n==name)
			TS:Create(d.btn,TweenInfo.new(0.15),{TextColor3=active and C_WHITE or C_DIM}):Play()
			TS:Create(d.bg,TweenInfo.new(0.15),{BackgroundTransparency=active and 0 or 1,BackgroundColor3=Color3.fromRGB(30,30,30)}):Play()
			local existingStroke=d.bg:FindFirstChildOfClass("UIStroke")
			if active and not existingStroke then
				local st=Instance.new("UIStroke",d.bg); st.Color=Color3.fromRGB(55,55,55); st.Thickness=0.8
			elseif not active and existingStroke then
				existingStroke:Destroy()
			end
		end
	end

	local loCount={}
	for _,n in ipairs(TAB_NAMES) do loCount[n]=0 end
	local function LO(pg) loCount[pg]=loCount[pg]+1; return loCount[pg] end

	-- create nav buttons
	for i,name in ipairs(TAB_NAMES) do
		local btn=Instance.new("TextButton",navFrame)
		btn.Size = UDim2.new(1,0,0,30); btn.BorderSizePixel=0; btn.LayoutOrder=i
		btn.Text=name; btn.TextColor3=name=="Speed" and C_WHITE or C_DIM
		btn.Font=Enum.Font.GothamBlack; btn.TextSize=11; btn.AutoButtonColor=false
		btn.TextXAlignment=Enum.TextXAlignment.Center; btn.BackgroundTransparency=1; btn.ZIndex=10
		local bg=Instance.new("Frame",btn)
		bg.Size=UDim2.new(1,0,1,0); bg.BorderSizePixel=0; bg.ZIndex=9
		bg.BackgroundColor3=Color3.fromRGB(30,30,30)
		bg.BackgroundTransparency=name=="Speed" and 0 or 1
		Instance.new("UICorner",bg).CornerRadius=UDim.new(0,7)
		if name=="Speed" then
			local st=Instance.new("UIStroke",bg); st.Color=Color3.fromRGB(60,60,60); st.Thickness=0.8
		end
		navBtns[name]={btn=btn,bg=bg}
		btn.MouseEnter:Connect(function()
			if activeTabName~=name then TS:Create(bg,TweenInfo.new(0.1),{BackgroundTransparency=0.6,BackgroundColor3=Color3.fromRGB(26,26,26)}):Play() end
		end)
		btn.MouseLeave:Connect(function()
			if activeTabName~=name then TS:Create(bg,TweenInfo.new(0.1),{BackgroundTransparency=1}):Play() end
		end)
		btn.MouseButton1Click:Connect(function() switchTab(name) end)
	end

	-- === HELPER BUILDERS ===
	local function mkSect(pg,text)
		local row=Instance.new("Frame",tabPages[pg]); row.Size=UDim2.new(1,0,0,22)
		row.BackgroundTransparency=1; row.BorderSizePixel=0; row.LayoutOrder=LO(pg)
		local acc=Instance.new("Frame",row); acc.Size=UDim2.new(0,3,0,11); acc.Position=UDim2.new(0,0,0.5,-5)
		acc.BackgroundColor3=C_WHITE; acc.BorderSizePixel=0; Instance.new("UICorner",acc).CornerRadius=UDim.new(0,2)
		local lbl=Instance.new("TextLabel",row); lbl.Size=UDim2.new(1,-8,1,0); lbl.Position=UDim2.new(0,8,0,0)
		lbl.BackgroundTransparency=1; lbl.Text=text:upper(); lbl.TextColor3 = Color3.fromRGB(150,150,150)
		lbl.Font=Enum.Font.GothamBlack; lbl.TextSize=10; lbl.TextXAlignment=Enum.TextXAlignment.Left
	end

	local function mkRow(pg)
		local f=Instance.new("Frame",tabPages[pg]); f.Size=UDim2.new(1,0,0,38)
		f.BackgroundColor3=C_ROW; f.BorderSizePixel=0; f.LayoutOrder=LO(pg)
		Instance.new("UICorner",f).CornerRadius=UDim.new(0,8)
		local st=Instance.new("UIStroke",f); st.Color=C_BORDER; st.Thickness=0.8
		f.MouseEnter:Connect(function() TS:Create(f,TweenInfo.new(0.1),{BackgroundColor3=C_ROW_HOV}):Play() end)
		f.MouseLeave:Connect(function() TS:Create(f,TweenInfo.new(0.1),{BackgroundColor3=C_ROW}):Play() end)
		return f
	end

	local function mkLabel(row,txt)
		local l=Instance.new("TextLabel",row); l.Size=UDim2.new(0.55,0,1,0); l.Position=UDim2.new(0,12,0,0)
		l.BackgroundTransparency=1; l.Text=txt; l.TextColor3=Color3.fromRGB(200,200,200)
		l.Font=Enum.Font.GothamBlack; l.TextSize=13; l.TextXAlignment=Enum.TextXAlignment.Left; return l
	end

	local function mkKeyBadge(row,keyName,xOff)
		local badge=Instance.new("TextLabel",row)
		badge.Size=UDim2.new(0,60,0,22); badge.Position=UDim2.new(1,-(xOff or 70),0.5,-11)
		badge.BackgroundColor3=C_KEY_BG; badge.BorderSizePixel=0
		badge.Text=keyName; badge.TextColor3=C_SUBTEXT; badge.Font=Enum.Font.GothamBlack; badge.TextSize=10; badge.ZIndex=4
		Instance.new("UICorner",badge).CornerRadius=UDim.new(0,5)
		Instance.new("UIStroke",badge).Color=C_BORDER
		return badge
	end

	local function mkToggle(pg,label,defKey,defOn,onToggle,onKeyChanged)
		local row=mkRow(pg)
		mkLabel(row,label)
		local keyBadge=nil
		if defKey then
			keyBadge=mkKeyBadge(row,(defKey or Enum.KeyCode.Unknown).Name,130)
			keyBadge.ZIndex=6
			local kl=false; local kconn; local prevText=keyBadge.Text
			keyBadge.Active=true
			keyBadge.InputBegan:Connect(function(inp)
				if inp.UserInputType~=Enum.UserInputType.MouseButton1 then return end
				if kl then kl=false; _anyKeyListening=false; if kconn then kconn:Disconnect();kconn=nil end; keyBadge.Text=prevText; return end
				prevText=keyBadge.Text; kl=true; _anyKeyListening=true; keyBadge.Text="..."
				kconn=UIS.InputBegan:Connect(function(i2)
					if not kl then return end
					if i2.UserInputType==Enum.UserInputType.Keyboard or i2.UserInputType==Enum.UserInputType.Gamepad1 then
						if i2.KeyCode==Enum.KeyCode.Escape then kl=false;_anyKeyListening=false;if kconn then kconn:Disconnect();kconn=nil end;keyBadge.Text=prevText;return end
						keyBadge.Text=i2.KeyCode.Name; prevText=i2.KeyCode.Name
						kl=false; _anyKeyListening=false; if kconn then kconn:Disconnect();kconn=nil end
						if onKeyChanged then onKeyChanged(i2.KeyCode,i2.UserInputType==Enum.UserInputType.Gamepad1) end
					end
				end)
			end)
		end
		local pillBg=Instance.new("Frame",row); pillBg.Size=UDim2.new(0,40,0,20); pillBg.Position=UDim2.new(1,-48,0.5,-10)
		pillBg.BackgroundColor3=defOn and C_ON_BG or C_OFF_BG; pillBg.BorderSizePixel=0; pillBg.ZIndex=5
		Instance.new("UICorner",pillBg).CornerRadius=UDim.new(1,0)
		local dot=Instance.new("Frame",pillBg); dot.Size=UDim2.new(0,14,0,14)
		dot.Position=defOn and UDim2.new(1,-17,0.5,-7) or UDim2.new(0,3,0.5,-7)
		dot.BackgroundColor3 = defOn and Color3.fromRGB(255,255,255); dot.BorderSizePixel=0; dot.ZIndex=6
		Instance.new("UICorner",dot).CornerRadius=UDim.new(1,0)
		local isOn=defOn or false
		local function setV(on)
			isOn=on
			TS:Create(pillBg,TweenInfo.new(0.2,Enum.EasingStyle.Quad),{BackgroundColor3=on and C_ON_BG or C_OFF_BG}):Play()
			TS:Create(dot,TweenInfo.new(0.2,Enum.EasingStyle.Back),{Position=on and UDim2.new(1,-17,0.5,-7) or UDim2.new(0,3,0.5,-7),BackgroundColor3=on and C_WHITE or Color3.fromRGB(90,90,90)}):Play()
		end
		local clk=Instance.new("TextButton",row); clk.Size=UDim2.new(1,0,1,0); clk.BackgroundTransparency=1; clk.Text=""; clk.ZIndex=3
		clk.MouseButton1Click:Connect(function()
			if _anyKeyListening then return end
			isOn=not isOn; setV(isOn); if onToggle then onToggle(isOn) end
		end)
		if keyBadge then keyBadge.ZIndex=7 end
		return setV
	end

	local function mkInput(pg,label,default,onChange)
		local row=mkRow(pg)
		mkLabel(row,label)
		local box=Instance.new("TextBox",row); box.Size=UDim2.new(0,70,0,26); box.Position=UDim2.new(1,-78,0.5,-13)
		box.BackgroundColor3=C_INPUT_BG; box.BorderSizePixel=0; box.Text=tostring(default)
		box.TextColor3=C_WHITE; box.Font=Enum.Font.GothamBlack; box.TextSize=12; box.ClearTextOnFocus=false; box.ZIndex=5
		Instance.new("UICorner",box).CornerRadius=UDim.new(0,6)
		Instance.new("UIStroke",box).Color=C_BORDER
		box.FocusLost:Connect(function()
			if onChange then local n=tonumber(box.Text); if n then onChange(n) else box.Text=tostring(default) end end
		end)
		return box
	end

	local function mkStatus(pg,label,val)
		local row=mkRow(pg)
		mkLabel(row,label)
		local v=Instance.new("TextLabel",row); v.Size=UDim2.new(0.42,0,1,0); v.Position=UDim2.new(0.55,0,0,0)
		v.BackgroundTransparency=1; v.Text=val; v.TextColor3=C_SUBTEXT
		v.Font=Enum.Font.GothamBlack; v.TextSize=12; v.TextXAlignment=Enum.TextXAlignment.Right; return v
	end

	local function mkCycleBtn(pg,label,options,default,onChange)
		local row=mkRow(pg)
		mkLabel(row,label)
		local idx=1
		for i,v in ipairs(options) do if v==default then idx=i break end end
		local btn=Instance.new("TextButton",row); btn.Size=UDim2.new(0,80,0,26); btn.Position=UDim2.new(1,-88,0.5,-13)
		btn.BackgroundColor3=C_INPUT_BG; btn.BorderSizePixel=0; btn.Text=options[idx]
		btn.TextColor3=C_WHITE; btn.Font=Enum.Font.GothamBlack; btn.TextSize=11; btn.ZIndex=5
		Instance.new("UICorner",btn).CornerRadius=UDim.new(0,6)
		Instance.new("UIStroke",btn).Color=C_BORDER
		btn.MouseButton1Click:Connect(function()
			idx=(idx%#options)+1; btn.Text=options[idx]
			if onChange then onChange(options[idx]) end
		end)
		return btn
	end

	-- =============================================
	-- SPEED TAB
	-- =============================================
	mkSect("Speed","Speed")
	normalBox=mkInput("Speed","Normal Speed",NS,function(v) if v>0 and v<=500 then NS=v end; saveConfig() end)
	carryBox=mkInput("Speed","Carry Speed",CS,function(v) if v>0 and v<=500 then CS=v end; saveConfig() end)

	do
		local row=mkRow("Speed"); row.LayoutOrder=LO("Speed"); mkLabel(row,"Speed Toggle Key")
		local badge=mkKeyBadge(row,(KB.SpeedToggle.kb or Enum.KeyCode.Q).Name,70)
		badge.ZIndex=6; local kl=false; local lconn; local prevT=badge.Text
		badge.Active=true
		badge.InputBegan:Connect(function(inp)
			if inp.UserInputType~=Enum.UserInputType.MouseButton1 then return end
			if kl then kl=false;_anyKeyListening=false;if lconn then lconn:Disconnect();lconn=nil end;badge.Text=prevT;return end
			prevT=badge.Text;kl=true;_anyKeyListening=true;badge.Text="..."
			lconn=UIS.InputBegan:Connect(function(i2)
				if not kl then return end
				if i2.UserInputType==Enum.UserInputType.Keyboard or i2.UserInputType==Enum.UserInputType.Gamepad1 then
					if i2.KeyCode==Enum.KeyCode.Escape then kl=false;_anyKeyListening=false;if lconn then lconn:Disconnect();lconn=nil end;badge.Text=prevT;return end
					badge.Text=i2.KeyCode.Name;prevT=i2.KeyCode.Name;kl=false;_anyKeyListening=false
					if lconn then lconn:Disconnect();lconn=nil end
					if tostring(i2.KeyCode):find("Button") then KB.SpeedToggle.gp=i2.KeyCode;KB.SpeedToggle.kb=nil else KB.SpeedToggle.kb=i2.KeyCode;KB.SpeedToggle.gp=nil end
					saveConfig()
				end
			end)
		end)
		UIS.InputBegan:Connect(function(input,gpe)
			if gpe then return end
			local kc=input.KeyCode
			if kc==KB.SpeedToggle.kb or (KB.SpeedToggle.gp and kc==KB.SpeedToggle.gp) then
				speedMode=not speedMode; if modeValLbl then modeValLbl.Text=speedMode and "Carry" or "Normal" end
			end
		end)
	end
	modeValLbl=mkStatus("Speed","Current Mode","Normal")

	-- =============================================
	-- BAT AIMBOT TAB
	-- =============================================
	mkSect("Bat Aimbot","Combat")
	local setAutoBatVis=mkToggle("Bat Aimbot","Auto Bat",KB.AutoBat.kb,false,
		function(on)
			if on then
				if autoLeftEnabled then autoLeftEnabled=false; if autoLeftSetVisual then autoLeftSetVisual(false) end; stopAutoLeft() end
				if autoRightEnabled then autoRightEnabled=false; if autoRightSetVisual then autoRightSetVisual(false) end; stopAutoRight() end
			end
			autoBatEnabled=on
		end,
		function(k,isGp) if isGp then KB.AutoBat.gp=k;KB.AutoBat.kb=nil else KB.AutoBat.kb=k;KB.AutoBat.gp=nil end; saveConfig() end)
	autoBatSetVisual=setAutoBatVis

	-- =============================================
	-- MECHANICS TAB
	-- =============================================
	mkSect("Mechanics","Game Mechanics")

	-- Auto Steal (custom, hold to expand duration)
	do
		local stealRow=mkRow("Mechanics"); stealRow.LayoutOrder=LO("Mechanics")
		mkLabel(stealRow,"Auto Steal")
		local stealPill=Instance.new("Frame",stealRow); stealPill.Size=UDim2.new(0,40,0,20); stealPill.Position=UDim2.new(1,-48,0.5,-10)
		stealPill.BackgroundColor3=C_OFF_BG; stealPill.BorderSizePixel=0; stealPill.ZIndex=5
		Instance.new("UICorner",stealPill).CornerRadius=UDim.new(1,0)
		local stealDot=Instance.new("Frame",stealPill); stealDot.Size=UDim2.new(0,14,0,14)
		stealDot.Position=UDim2.new(0,3,0.5,-7); stealDot.BackgroundColor3=Color3.fromRGB(90,90,90); stealDot.BorderSizePixel=0; stealDot.ZIndex=6
		Instance.new("UICorner",stealDot).CornerRadius=UDim.new(1,0)
		local stealIsOn=false
		local function setStealVis(on)
			stealIsOn=on
			TS:Create(stealPill,TweenInfo.new(0.2,Enum.EasingStyle.Quad),{BackgroundColor3=on and C_ON_BG or C_OFF_BG}):Play()
			TS:Create(stealDot,TweenInfo.new(0.2,Enum.EasingStyle.Back),{Position=on and UDim2.new(1,-17,0.5,-7) or UDim2.new(0,3,0.5,-7),BackgroundColor3=on and C_WHITE or Color3.fromRGB(90,90,90)}):Play()
		end
		setInstaGrab=setStealVis
		local isHolding=false
		local stealClk=Instance.new("TextButton",stealRow); stealClk.Size=UDim2.new(1,0,1,0); stealClk.BackgroundTransparency=1; stealClk.Text=""; stealClk.ZIndex=4
		stealClk.InputBegan:Connect(function(inp)
			if inp.UserInputType~=Enum.UserInputType.MouseButton1 and inp.UserInputType~=Enum.UserInputType.Touch then return end
			isHolding=true
		end)
		stealClk.InputEnded:Connect(function(inp)
			if inp.UserInputType~=Enum.UserInputType.MouseButton1 and inp.UserInputType~=Enum.UserInputType.Touch then return end
			if not isHolding then return end; isHolding=false
			stealIsOn=not stealIsOn; setStealVis(stealIsOn); Steal.AutoStealEnabled=stealIsOn
			if stealIsOn then if not pcall(startAutoSteal) then Steal.AutoStealEnabled=false; setStealVis(false) end else stopAutoSteal() end
			saveConfig()
		end)
		stealPill.ZIndex=5; stealDot.ZIndex=6; stealClk.ZIndex=4
	end

	durationInput=mkInput("Mechanics","Steal Duration",Steal.StealDuration,function(v)
		if v and v>0 and v<=60 then Steal.StealDuration=v end; saveConfig()
	end)

	setInfJumpVisual=mkToggle("Mechanics","Infinite Jump",nil,false,function(on) infJumpEnabled=on; if on then startInfiniteJump() else stopInfiniteJump() end end)
	setAntiRagVisual=mkToggle("Mechanics","Anti Ragdoll",nil,false,function(on) antiRagdollEnabled=on; if on then startAntiRagdoll() else stopAntiRagdoll() end end)
	setMedusaVisual=mkToggle("Mechanics","Medusa Counter",nil,false,function(on)
		medusaCounterEnabled=on
		if on then setupMedusa(LP.Character) else for _,c in pairs(medusaConns) do pcall(function() c:Disconnect() end) end; medusaConns={} end
	end)
	setUnwalkVisual=mkToggle("Mechanics","Unwalk",nil,false,function(on)
		unwalkEnabled=on; if on then disableAnimations() else enableAnimations() end
	end)

	mkSect("Mechanics","Visual")
	setStretchRezVisual=mkToggle("Mechanics","Stretch Rez",nil,false,function(on) if on then enableStretchRez() else disableStretchRez() end end)

	-- =============================================
	-- MOVEMENT TAB
	-- =============================================
	mkSect("Movement","Teleport")
	do
		local tpRow=mkRow("Movement"); tpRow.LayoutOrder=LO("Movement")
		mkLabel(tpRow,"TP Mode")
		local modes={"Manuel","Semi","Medusa"}; local idx=1
		for i,m in ipairs(modes) do if m==tpMode then idx=i break end end
		local tpBtn=Instance.new("TextButton",tpRow); tpBtn.Size=UDim2.new(0,80,0,26); tpBtn.Position=UDim2.new(1,-88,0.5,-13)
		tpBtn.BackgroundColor3=C_INPUT_BG; tpBtn.BorderSizePixel=0; tpBtn.Text=modes[idx]
		tpBtn.TextColor3=C_WHITE; tpBtn.Font=Enum.Font.GothamBlack; tpBtn.TextSize=11; tpBtn.ZIndex=5
		Instance.new("UICorner",tpBtn).CornerRadius=UDim.new(0,6)
		Instance.new("UIStroke",tpBtn).Color=C_BORDER
		tpBtn.MouseButton1Click:Connect(function()
			idx=(idx%#modes)+1; tpBtn.Text=modes[idx]; tpMode=modes[idx]; medusaMode=(tpMode=="Medusa"); saveConfig()
			TS:Create(tpBtn,TweenInfo.new(0.08),{BackgroundColor3=C_BORDER}):Play()
			task.delay(0.16,function() TS:Create(tpBtn,TweenInfo.new(0.12),{BackgroundColor3=C_INPUT_BG}):Play() end)
		end)
	end

	do
		local row=mkRow("Movement"); row.LayoutOrder=LO("Movement"); mkLabel(row,"TP Down")
		local badge=mkKeyBadge(row,(KB.TPFloor.kb or Enum.KeyCode.F).Name,70)
		badge.Active=true; local kl=false; local lconn; local prevT=badge.Text
		badge.InputBegan:Connect(function(inp)
			if inp.UserInputType~=Enum.UserInputType.MouseButton1 then return end
			if kl then kl=false;_anyKeyListening=false;if lconn then lconn:Disconnect();lconn=nil end;badge.Text=prevT;return end
			prevT=badge.Text;kl=true;_anyKeyListening=true;badge.Text="..."
			lconn=UIS.InputBegan:Connect(function(i2)
				if not kl then return end
				if i2.UserInputType==Enum.UserInputType.Keyboard or i2.UserInputType==Enum.UserInputType.Gamepad1 then
					if i2.KeyCode==Enum.KeyCode.Escape then kl=false;_anyKeyListening=false;if lconn then lconn:Disconnect();lconn=nil end;badge.Text=prevT;return end
					badge.Text=i2.KeyCode.Name;prevT=i2.KeyCode.Name;kl=false;_anyKeyListening=false;if lconn then lconn:Disconnect();lconn=nil end
					if tostring(i2.KeyCode):find("Button") then KB.TPFloor.gp=i2.KeyCode;KB.TPFloor.kb=nil else KB.TPFloor.kb=i2.KeyCode;KB.TPFloor.gp=nil end;saveConfig()
				end
			end)
		end)
	end

	mkSect("Movement","Return")
	local setTPLeftVisual2=mkToggle("Movement","Brainrot Return L",KB.TPLeft.kb,false,
		function(on) if on and brainrotRightEnabled then brainrotRightEnabled=false; if setTPRightVisual then setTPRightVisual(false) end end; brainrotLeftEnabled=on end,
		function(k,isGp) if isGp then KB.TPLeft.gp=k;KB.TPLeft.kb=nil else KB.TPLeft.kb=k;KB.TPLeft.gp=nil end; saveConfig() end)
	setTPLeftVisual=setTPLeftVisual2

	local setTPRightVisual2=mkToggle("Movement","Brainrot Return R",KB.TPRight.kb,false,
		function(on) if on and brainrotLeftEnabled then brainrotLeftEnabled=false; if setTPLeftVisual then setTPLeftVisual(false) end end; brainrotRightEnabled=on end,
		function(k,isGp) if isGp then KB.TPRight.gp=k;KB.TPRight.kb=nil else KB.TPRight.kb=k;KB.TPRight.gp=nil end; saveConfig() end)
	setTPRightVisual=setTPRightVisual2

	do
		local row=mkRow("Movement"); row.LayoutOrder=LO("Movement"); mkLabel(row,"Drop Brainrot")
		local badge=mkKeyBadge(row,(KB.DropBrainrot.kb or Enum.KeyCode.X).Name,70)
		badge.Active=true; local kl=false; local lconn; local prevT=badge.Text
		badge.InputBegan:Connect(function(inp)
			if inp.UserInputType~=Enum.UserInputType.MouseButton1 then return end
			if kl then kl=false;_anyKeyListening=false;if lconn then lconn:Disconnect();lconn=nil end;badge.Text=prevT;return end
			prevT=badge.Text;kl=true;_anyKeyListening=true;badge.Text="..."
			lconn=UIS.InputBegan:Connect(function(i2)
				if not kl then return end
				if i2.UserInputType==Enum.UserInputType.Keyboard or i2.UserInputType==Enum.UserInputType.Gamepad1 then
					if i2.KeyCode==Enum.KeyCode.Escape then kl=false;_anyKeyListening=false;if lconn then lconn:Disconnect();lconn=nil end;badge.Text=prevT;return end
					badge.Text=i2.KeyCode.Name;prevT=i2.KeyCode.Name;kl=false;_anyKeyListening=false;if lconn then lconn:Disconnect();lconn=nil end
					if tostring(i2.KeyCode):find("Button") then KB.DropBrainrot.gp=i2.KeyCode;KB.DropBrainrot.kb=nil else KB.DropBrainrot.kb=i2.KeyCode;KB.DropBrainrot.gp=nil end;saveConfig()
				end
			end)
		end)
	end

	mkSect("Movement","Auto Move")
	local setALVis=mkToggle("Movement","Auto Left",KB.AutoLeft.kb,false,
		function(on)
			autoLeftEnabled=on
			if on then
				if autoRightEnabled then autoRightEnabled=false; if autoRightSetVisual then autoRightSetVisual(false) end; stopAutoRight() end
				if autoBatEnabled then autoBatEnabled=false; if autoBatSetVisual then autoBatSetVisual(false) end end
				startAutoLeft()
			else stopAutoLeft() end
		end,
		function(k,isGp) if isGp then KB.AutoLeft.gp=k;KB.AutoLeft.kb=nil else KB.AutoLeft.kb=k;KB.AutoLeft.gp=nil end; saveConfig() end)
	autoLeftSetVisual=setALVis

	local setARVis=mkToggle("Movement","Auto Right",KB.AutoRight.kb,false,
		function(on)
			autoRightEnabled=on
			if on then
				if autoLeftEnabled then autoLeftEnabled=false; if autoLeftSetVisual then autoLeftSetVisual(false) end; stopAutoLeft() end
				if autoBatEnabled then autoBatEnabled=false; if autoBatSetVisual then autoBatSetVisual(false) end end
				startAutoRight()
			else stopAutoRight() end
		end,
		function(k,isGp) if isGp then KB.AutoRight.gp=k;KB.AutoRight.kb=nil else KB.AutoRight.kb=k;KB.AutoRight.gp=nil end; saveConfig() end)
	autoRightSetVisual=setARVis

	mkSect("Movement","Float")
	floatHeightBox=mkInput("Movement","Float Height",floatHeight,function(v)
		local n=tonumber(v); if n and n>=1 and n<=100 then floatHeight=n end; saveConfig()
	end)

	do
		local row=mkRow("Movement"); row.LayoutOrder=LO("Movement"); mkLabel(row,"Float")
		local badge=mkKeyBadge(row,(KB.Float.kb or Enum.KeyCode.J).Name,130)
		badge.ZIndex=7; badge.Active=true; local kl=false; local kconn; local prevT=badge.Text
		badge.InputBegan:Connect(function(inp)
			if inp.UserInputType~=Enum.UserInputType.MouseButton1 then return end
			if kl then kl=false;_anyKeyListening=false;if kconn then kconn:Disconnect();kconn=nil end;badge.Text=prevT;return end
			prevT=badge.Text;kl=true;_anyKeyListening=true;badge.Text="..."
			kconn=UIS.InputBegan:Connect(function(i2)
				if not kl then return end
				if i2.UserInputType==Enum.UserInputType.Keyboard or i2.UserInputType==Enum.UserInputType.Gamepad1 then
					if i2.KeyCode==Enum.KeyCode.Escape then kl=false;_anyKeyListening=false;if kconn then kconn:Disconnect();kconn=nil end;badge.Text=prevT;return end
					badge.Text=i2.KeyCode.Name;prevT=i2.KeyCode.Name;kl=false;_anyKeyListening=false;if kconn then kconn:Disconnect();kconn=nil end
					if i2.UserInputType==Enum.UserInputType.Gamepad1 then KB.Float.gp=i2.KeyCode else KB.Float.kb=i2.KeyCode end;saveConfig()
				end
			end)
		end)
		local pillBg=Instance.new("Frame",row); pillBg.Size=UDim2.new(0,40,0,20); pillBg.Position=UDim2.new(1,-48,0.5,-10)
		pillBg.BackgroundColor3=C_OFF_BG; pillBg.BorderSizePixel=0; pillBg.ZIndex=5
		Instance.new("UICorner",pillBg).CornerRadius=UDim.new(1,0)
		local dot=Instance.new("Frame",pillBg); dot.Size=UDim2.new(0,14,0,14)
		dot.Position=UDim2.new(0,3,0.5,-7); dot.BackgroundColor3=Color3.fromRGB(90,90,90); dot.BorderSizePixel=0; dot.ZIndex=6
		Instance.new("UICorner",dot).CornerRadius=UDim.new(1,0)
		local isOn=false
		setFloat=function(on)
			isOn=on
			TS:Create(pillBg,TweenInfo.new(0.2,Enum.EasingStyle.Quad),{BackgroundColor3=on and C_ON_BG or C_OFF_BG}):Play()
			TS:Create(dot,TweenInfo.new(0.2,Enum.EasingStyle.Back),{Position=on and UDim2.new(1,-17,0.5,-7) or UDim2.new(0,3,0.5,-7),BackgroundColor3=on and C_WHITE or Color3.fromRGB(90,90,90)}):Play()
		end
		local clk=Instance.new("TextButton",row); clk.Size=UDim2.new(1,0,1,0); clk.BackgroundTransparency=1; clk.Text=""; clk.ZIndex=3
		clk.MouseButton1Click:Connect(function()
			isOn=not isOn; setFloat(isOn); floatEnabled=isOn
			if isOn then floatJumping=false; startFloat() else stopFloat() end; saveConfig()
		end)
		pillBg.ZIndex=5; dot.ZIndex=6; clk.ZIndex=3; badge.ZIndex=7
	end

	-- =============================================
	-- SETTINGS TAB
	-- =============================================
	mkSect("Settings","Grab Settings")
	radInput=mkInput("Settings","Grab Radius",Steal.StealRadius,function(v)
		if v>=5 and v<=300 then
			Steal.StealRadius=math.floor(v); Steal.cachedPrompts={}; Steal.promptCacheTime=0
			if progressRadLbl then progressRadLbl.Text="Radius: "..Steal.StealRadius end; saveConfig()
		end
	end)

	mkSect("Settings","Interface")
	do
		local row=mkRow("Settings"); row.LayoutOrder=LO("Settings"); mkLabel(row,"Hide / Show GUI")
		local badge=mkKeyBadge(row,(KB.GuiHide.kb or Enum.KeyCode.LeftControl).Name,70)
		badge.Active=true; local kl=false; local lconn; local prevT=badge.Text
		badge.InputBegan:Connect(function(inp)
			if inp.UserInputType~=Enum.UserInputType.MouseButton1 then return end
			if kl then kl=false;_anyKeyListening=false;if lconn then lconn:Disconnect();lconn=nil end;badge.Text=prevT;return end
			prevT=badge.Text;kl=true;_anyKeyListening=true;badge.Text="..."
			lconn=UIS.InputBegan:Connect(function(i2)
				if not kl then return end
				if i2.UserInputType==Enum.UserInputType.Keyboard or i2.UserInputType==Enum.UserInputType.Gamepad1 then
					if i2.KeyCode==Enum.KeyCode.Escape then kl=false;_anyKeyListening=false;if lconn then lconn:Disconnect();lconn=nil end;badge.Text=prevT;return end
					badge.Text=i2.KeyCode.Name;prevT=i2.KeyCode.Name;kl=false;_anyKeyListening=false;if lconn then lconn:Disconnect();lconn=nil end
					if tostring(i2.KeyCode):find("Button") then KB.GuiHide.gp=i2.KeyCode;KB.GuiHide.kb=nil else KB.GuiHide.kb=i2.KeyCode;KB.GuiHide.gp=nil end;saveConfig()
				end
			end)
		end)
	end

	-- === PROGRESS BAR (steal indicator) ===
	local pbFrame=Instance.new("Frame",gui)
	pbFrame.Size=UDim2.new(0,280,0,48); pbFrame.Position=UDim2.new(0.5,-140,1,-110)
	pbFrame.BackgroundColor3=Color3.fromRGB(14,14,14); pbFrame.BorderSizePixel=0; pbFrame.Active=true
	Instance.new("UICorner",pbFrame).CornerRadius=UDim.new(0,8)
	Instance.new("UIStroke",pbFrame).Color=C_BORDER
	makeDraggable(pbFrame)
	progressPct=Instance.new("TextLabel",pbFrame)
	progressPct.Size=UDim2.new(0,50,0,18); progressPct.Position=UDim2.new(0,10,0,6)
	progressPct.BackgroundTransparency=1; progressPct.Text="0%"; progressPct.TextColor3=C_WHITE
	progressPct.Font=Enum.Font.GothamBlack; progressPct.TextSize=12; progressPct.TextXAlignment=Enum.TextXAlignment.Left
	progressRadLbl=Instance.new("TextLabel",pbFrame)
	progressRadLbl.Size=UDim2.new(0,110,0,18); progressRadLbl.Position=UDim2.new(1,-118,0,6)
	progressRadLbl.BackgroundTransparency=1; progressRadLbl.Text="Radius: "..Steal.StealRadius
	progressRadLbl.TextColor3=C_SUBTEXT; progressRadLbl.Font=Enum.Font.GothamBlack; progressRadLbl.TextSize=9; progressRadLbl.TextXAlignment=Enum.TextXAlignment.Right
	local progressBg=Instance.new("Frame",pbFrame)
	progressBg.Size=UDim2.new(1,-20,0,14); progressBg.Position=UDim2.new(0,10,0,30)
	progressBg.BackgroundColor3=Color3.fromRGB(22,22,22); progressBg.BorderSizePixel=0
	Instance.new("UICorner",progressBg).CornerRadius=UDim.new(1,0)
	progressFill=Instance.new("Frame",progressBg)
	progressFill.Size=UDim2.new(0,0,1,0); progressFill.BackgroundColor3=C_WHITE; progressFill.BorderSizePixel=0
	Instance.new("UICorner",progressFill).CornerRadius=UDim.new(1,0)

	-- === MINI TOGGLE (when hidden) ===
	miniToggleBtn=Instance.new("TextButton",gui)
	miniToggleBtn.Name="MiniToggle"
	miniToggleBtn.Size=UDim2.new(0,110,0,28); miniToggleBtn.Position=UDim2.new(0,38,0,38)
	miniToggleBtn.BackgroundColor3=Color3.fromRGB(10,10,10); miniToggleBtn.BorderSizePixel=0
	miniToggleBtn.Text="RELIC HUB"; miniToggleBtn.TextColor3=C_WHITE
	miniToggleBtn.Font=Enum.Font.GothamBlack; miniToggleBtn.TextSize=11; miniToggleBtn.ZIndex=20; miniToggleBtn.Visible=false
	Instance.new("UICorner",miniToggleBtn).CornerRadius=UDim.new(0,8)
	Instance.new("UIStroke",miniToggleBtn).Color=C_BORDER
	makeDraggable(miniToggleBtn)
	miniToggleBtn.MouseButton1Click:Connect(showGui)

	-- === GLOBAL KEYBINDS ===
	UIS.InputBegan:Connect(function(input,gpe)
		if gpe then return end
		if _anyKeyListening then return end
		if input.UserInputType~=Enum.UserInputType.Keyboard and input.UserInputType~=Enum.UserInputType.Gamepad1 then return end
		local kc=input.KeyCode
		local function kbMatch(e,k) return k==e.kb or (e.gp and k==e.gp) end
		if kbMatch(KB.DropBrainrot,kc) then runDrop()
		elseif kbMatch(KB.TPFloor,kc) then runTPFloor()
		elseif kbMatch(KB.Float,kc) then
			floatEnabled=not floatEnabled; if setFloat then setFloat(floatEnabled) end
			if floatEnabled then floatJumping=false; startFloat() else stopFloat() end
		elseif kbMatch(KB.AutoLeft,kc) then
			autoLeftEnabled=not autoLeftEnabled
			if autoLeftEnabled then
				if autoRightEnabled then autoRightEnabled=false; if autoRightSetVisual then autoRightSetVisual(false) end; stopAutoRight() end
				if autoBatEnabled then autoBatEnabled=false; if autoBatSetVisual then autoBatSetVisual(false) end end
				startAutoLeft()
			else stopAutoLeft() end
			if autoLeftSetVisual then autoLeftSetVisual(autoLeftEnabled) end
		elseif kbMatch(KB.AutoRight,kc) then
			autoRightEnabled=not autoRightEnabled
			if autoRightEnabled then
				if autoLeftEnabled then autoLeftEnabled=false; if autoLeftSetVisual then autoLeftSetVisual(false) end; stopAutoLeft() end
				if autoBatEnabled then autoBatEnabled=false; if autoBatSetVisual then autoBatSetVisual(false) end end
				startAutoRight()
			else stopAutoRight() end
			if autoRightSetVisual then autoRightSetVisual(autoRightEnabled) end
		elseif kbMatch(KB.AutoBat,kc) then
			autoBatEnabled=not autoBatEnabled
			if autoBatEnabled then
				if autoLeftEnabled then autoLeftEnabled=false; if autoLeftSetVisual then autoLeftSetVisual(false) end; stopAutoLeft() end
				if autoRightEnabled then autoRightEnabled=false; if autoRightSetVisual then autoRightSetVisual(false) end; stopAutoRight() end
			end
			if autoBatSetVisual then autoBatSetVisual(autoBatEnabled) end
		elseif kbMatch(KB.TPLeft,kc) then
			brainrotLeftEnabled=not brainrotLeftEnabled; if setTPLeftVisual then setTPLeftVisual(brainrotLeftEnabled) end
			if brainrotLeftEnabled and brainrotRightEnabled then brainrotRightEnabled=false; if setTPRightVisual then setTPRightVisual(false) end end
		elseif kbMatch(KB.TPRight,kc) then
			brainrotRightEnabled=not brainrotRightEnabled; if setTPRightVisual then setTPRightVisual(brainrotRightEnabled) end
			if brainrotRightEnabled and brainrotLeftEnabled then brainrotLeftEnabled=false; if setTPLeftVisual then setTPLeftVisual(false) end end
		elseif kbMatch(KB.GuiHide,kc) then toggleGuiVis()
		end
	end)

	-- activate first tab
	switchTab("Speed")
end
local function loadConfig()
	if not(isfile and isfile("RelicHubPC.json")) then return end
	local ok,cfg=pcall(function() return HS:JSONDecode(readfile("RelicHubPC.json")) end)
	if not ok or not cfg then return end
	local function lk(entryName,data)
		local entry=KB[entryName];if not data then return end
		if type(data)=="table" then
			if data.kb and Enum.KeyCode[data.kb] then entry.kb=Enum.KeyCode[data.kb] end
			if data.gp and Enum.KeyCode[data.gp] then entry.gp=Enum.KeyCode[data.gp] end
		end
	end
	if cfg.normalSpeed then NS=cfg.normalSpeed;if normalBox then normalBox.Text=tostring(NS) end end
	if cfg.carrySpeed then CS=cfg.carrySpeed;if carryBox then carryBox.Text=tostring(CS) end end
	if cfg.grabRadius then Steal.StealRadius=cfg.grabRadius;if radInput then radInput.Text=tostring(cfg.grabRadius) end;if progressRadLbl then progressRadLbl.Text="Radius: "..cfg.grabRadius end end
	if cfg.stealDuration then Steal.StealDuration=cfg.stealDuration;if durationInput then durationInput.Text=tostring(cfg.stealDuration) end end
	if cfg.floatHeight and type(cfg.floatHeight)=="number" then floatHeight=cfg.floatHeight;if floatHeightBox then floatHeightBox.Text=tostring(cfg.floatHeight) end end
	lk("DropBrainrot",cfg.dropBrainrotKey);lk("AutoLeft",cfg.autoLeftKey);lk("AutoRight",cfg.autoRightKey)
	lk("AutoBat",cfg.autoBatKey);lk("TPLeft",cfg.tpLeftKey);lk("TPRight",cfg.tpRightKey)
	lk("TPFloor",cfg.tpFloorKey);lk("GuiHide",cfg.guiHideKey);lk("Float",cfg.floatKey)
	lk("SpeedToggle",cfg.speedToggleKey)
	if cfg.antiRagdoll~=nil then antiRagdollEnabled=cfg.antiRagdoll;if cfg.antiRagdoll then setAntiRagVisual(true);startAntiRagdoll() end end
	if cfg.autoStealEnabled then Steal.AutoStealEnabled=true;setInstaGrab(true);pcall(startAutoSteal) end
	if cfg.infiniteJump then infJumpEnabled=true;setInfJumpVisual(true);startInfiniteJump() end
	if cfg.medusaCounter then medusaCounterEnabled=true;setMedusaVisual(true);setupMedusa(LP.Character) end
	if cfg.brainrotReturnLeft then brainrotLeftEnabled=true;if setTPLeftVisual then setTPLeftVisual(true) end end
	if cfg.brainrotReturnRight then brainrotRightEnabled=true;if setTPRightVisual then setTPRightVisual(true) end end
	if cfg.carryMode then speedMode=true;if modeValLbl then modeValLbl.Text="Carry" end end
	if cfg.autoBat then autoBatEnabled=true;if autoBatSetVisual then autoBatSetVisual(true) end end
	if cfg.unwalkEnabled then
		unwalkEnabled=true;setUnwalkVisual(true)
		task.spawn(function() task.wait(0.5);disableAnimations() end)
	end
	if cfg.floatEnabled then floatEnabled=true;if setFloat then setFloat(true) end;floatJumping=false;startFloat() end
	if cfg.stretchRez then stretchRezEnabled=true;setStretchRezVisual(true);enableStretchRez() end
	if cfg.tpMode and (cfg.tpMode=="Manuel" or cfg.tpMode=="Semi" or cfg.tpMode=="Medusa") then
		tpMode=cfg.tpMode;medusaMode=(tpMode=="Medusa")
	end
end

local function preloadKeybinds()
	if not(isfile and isfile("RelicHubPC.json")) then return end
	local ok,cfg=pcall(function() return HS:JSONDecode(readfile("RelicHubPC.json")) end)
	if not ok or not cfg then return end
	local function lk(entryName,data)
		local entry=KB[entryName];if not data then return end
		if type(data)=="table" then
			if data.kb and Enum.KeyCode[data.kb] then entry.kb=Enum.KeyCode[data.kb] end
			if data.gp and Enum.KeyCode[data.gp] then entry.gp=Enum.KeyCode[data.gp] end
		end
	end
	lk("DropBrainrot",cfg.dropBrainrotKey);lk("AutoLeft",cfg.autoLeftKey);lk("AutoRight",cfg.autoRightKey)
	lk("AutoBat",cfg.autoBatKey);lk("TPLeft",cfg.tpLeftKey);lk("TPRight",cfg.tpRightKey)
	lk("TPFloor",cfg.tpFloorKey);lk("GuiHide",cfg.guiHideKey);lk("Float",cfg.floatKey)
	lk("SpeedToggle",cfg.speedToggleKey)
	if cfg.normalSpeed then NS=cfg.normalSpeed end
	if cfg.carrySpeed then CS=cfg.carrySpeed end
	if cfg.tpMode and (cfg.tpMode=="Manuel" or cfg.tpMode=="Semi" or cfg.tpMode=="Medusa") then
		tpMode=cfg.tpMode;medusaMode=(tpMode=="Medusa")
	end
end

preloadKeybinds()
buildGui()
loadConfig()
print("Relic Hub Loaded")
